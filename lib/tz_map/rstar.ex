defmodule TzMap.RStar do
  @moduledoc """
  This is an opinionated wrapper around the RStar library that removes all of the
  CDRT and async parts of it to just hold the underlying storage structure and
  methods.
  """
  defstruct ~w{members tree}a

  @envelope_eps 0.00001

  @type geometry() ::
          {number(), number()}
          | Geo.Point.t()
          | Geo.MultiPoint.t()
          | Geo.LineString.t()
          | Geo.MultiLineString.t()
          | Geo.Polygon.t()
          | Geo.MultiPolygon.t()
  @type id() :: reference() | atom()
  @type member() :: %{id: id(), geometry: geometry(), data: map()}
  @type tree() :: {:rtree, integer(), any(), tuple()}
  @type t() :: %__MODULE__{
          members: %{id() => member()},
          tree: tree()
        }

  @doc """
  Creates a new, empty RStar tree
  """
  @spec new() :: t()
  def new() do
    %__MODULE__{members: %{}, tree: :rstar.new(2)}
  end

  @doc """
  Inserts or updates a given object into the RStar.  The object is indexed by the bounding box
  of the given geometry and the additional object information is stored for return later.
  """
  @spec put(t(), id(), geometry(), map()) :: t()
  def put(state, id, geometry, data \\ %{}) do
    state |> delete(id) |> insert(id, geometry, data)
  end

  defp insert(state, id, geometry, data) do
    env = Envelope.from_geo(geometry)
    box = to_box(env)
    to_store = :rstar_geometry.new(2, box, id)
    member = %{id: id, geometry: geometry, data: data, stored: to_store}

    %{
      state
      | tree: :rstar.insert(state.tree, to_store),
        members: Map.put(state.members, id, member)
    }
  end

  @doc """
  Removes the object with the given id from the RStar
  """
  @spec delete(t(), id()) :: t()
  def delete(state, id) do
    case Map.get(state.members, id) do
      %{stored: stored} ->
        %{state | tree: :rstar.delete(state.tree, stored), members: Map.delete(state.members, id)}

      nil ->
        state
    end
  end

  @doc """
  Query the map to find any objects that intersect the geometry given.

  1. Build an envelope from the given geometry
  2. Find intersecting bounding boxes in the R-Tree
  3. Return objects whose geometry intersects the given geometry

  If you only want envelope checks, use `query_envelope/2`.
  """
  @spec query(t(), geometry()) :: list(member())
  def query(state, {x, y}) do
    query(state, %Geo.Point{coordinates: {x, y}})
  end

  def query(state, geo) do
    query_envelope(state, Envelope.from_geo(geo))
    |> Enum.filter(fn member ->
      Topo.intersects?(geo, member.geometry)
    end)
  end

  @spec query_envelope(t(), Envelope.t()) :: list(member())
  def query_envelope(state, %Envelope{} = env) do
    query_envelope_ids(state, env)
    |> Enum.map(fn id -> Map.get(state.members, id) end)
  end

  @spec query_envelope_ids(t(), Envelope.t()) :: list(id())
  def query_envelope_ids(state, %Envelope{} = env) do
    box = :rstar_geometry.new(2, to_box(env), :query)
    :rstar.search_within(state.tree, box) |> Enum.map(fn {_, _, _, id} -> id end)
  end

  @spec query_envelope_and_filter_by_geometry(t(), Envelope.t(), geometry()) :: list(member())
  def query_envelope_and_filter_by_geometry(state, %Envelope{} = env, geo) do
    query_envelope(state, env)
    |> Enum.filter(fn member ->
      Topo.intersects?(geo, member.geometry)
    end)
  end

  @spec any_intersect?(t(), geometry()) :: boolean()
  def any_intersect?(state, {x, y}) do
    any_intersect?(state, %Geo.Point{coordinates: {x, y}})
  end

  def any_intersect?(state, geo) do
    query_envelope(state, Envelope.from_geo(geo))
    |> Enum.any?(fn member ->
      Topo.intersects?(geo, member.geometry)
    end)
  end

  @spec any_contain?(t(), geometry()) :: boolean()
  def any_contain?(state, {x, y}) do
    any_contain?(state, %Geo.Point{coordinates: {x, y}})
  end

  def any_contain?(state, geo) do
    query_envelope(state, Envelope.from_geo(geo))
    |> Enum.any?(fn member ->
      Topo.contains?(member.geometry, geo)
    end)
  end

  @spec members(t()) :: list(member())
  def members(state) do
    state.members |> Map.values()
  end

  @spec count(t()) :: non_neg_integer()
  def count(state) do
    state.members |> map_size()
  end

  # The underlying RStar implementation does not support envelopes with 0-length sides,
  # so we expand everything by a small amount (1mm) when storing or querying.
  defp to_box(%Envelope{} = env) do
    expanded = env |> Envelope.expand_by(@envelope_eps)
    [{expanded.min_x, expanded.max_x}, {expanded.min_y, expanded.max_y}]
  end
end
