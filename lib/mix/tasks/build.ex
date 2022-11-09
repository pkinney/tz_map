defmodule Mix.Tasks.Build do
  @moduledoc """
  Mix task that imports the shapefile at `src/tz_world.zip`, builds a `SpatialMap` containing
  all of the polygons, and writes that map out to a compressed (erlang term format)[https://www.erlang.org/doc/apps/erts/erl_ext_dist.html]
  file, which is distributed with the package.
  """
  use Mix.Task

  require Logger

  def run(args) do
    Mix.Task.run("compile")
    __MODULE__.compiled_run(args)
  end

  def compiled_run(_) do
    path = "./src/tz_world.zip"
    Application.ensure_all_started(:tz_map)

    [{_, _, shapes}] =
      path
      |> Exshape.from_zip(unzip_shell: true)

    spatial_map =
      shapes
      |> convert_to_geo()
      |> check_tz_name()
      |> into_rstar()

    IO.puts("Serializing...")
    binary = :erlang.term_to_binary(spatial_map)
    binary_gzip = :zlib.gzip(binary)

    IO.puts(
      "  #{byte_size(binary) |> Size.humanize!()} - #{byte_size(binary_gzip) |> Size.humanize!()} compressed"
    )

    file = Path.join([:code.priv_dir(:tz_map), "tz_world.etf"])
    :ok = File.write(file, binary_gzip)
    IO.puts("File written to #{file}")
  end

  defp convert_to_geo(stream) do
    Stream.map(stream, fn
      {%{points: [rings]}, [name]} ->
        polygon = %Geo.Polygon{
          coordinates:
            Enum.map(rings, fn ring -> Enum.map(ring, fn %{x: lon, y: lat} -> {lon, lat} end) end),
          properties: %{tz: name |> String.trim()}
        }

        polygon

      _ ->
        nil
    end)
    |> Stream.reject(&is_nil/1)
  end

  defp check_tz_name(stream) do
    Stream.filter(stream, fn %Geo.Polygon{properties: %{tz: tz}} ->
      cond do
        Tzdata.zone_exists?(tz) ->
          true

        "uninhabited" ->
          false

        true ->
          IO.puts("Time zone found that is not known to tzdata: #{tz}")
          false
      end
    end)
  end

  defp into_rstar(stream) do
    init_map = TzMap.RStar.new()

    shapes = stream |> Enum.to_list()
    count = length(shapes)
    IO.puts("Placing #{count} shapes into RStar tree...")

    shapes
    |> Enum.reduce(init_map, fn %Geo.Polygon{} = poly, map ->
      IO.puts("  #{TzMap.RStar.count(map) + 1}/#{count}")
      TzMap.RStar.put(map, make_ref(), poly, poly.properties)
    end)
  end
end
