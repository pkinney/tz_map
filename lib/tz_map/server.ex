defmodule TzMap.Server do
  use GenServer

  require Logger

  @spec query(number, number) :: String.t() | nil
  def query(lon, lat) do
    GenServer.call(__MODULE__, {:query, lon, lat})
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: __MODULE__])
  end

  @impl true
  def init(:ok) do
    filename = Path.join([:code.priv_dir(:tz_map), "tz_world.etf"])

    with {:ok, content} <- File.read(filename),
         binary <- :zlib.gunzip(content) do
      map = :erlang.binary_to_term(binary)
      {:ok, map}
    else
      e ->
        Logger.error("[#{__MODULE__}] Error loading TzMap source file: #{inspect(e)}")
        {:stop, :tz_map_error}
    end
  end

  @impl true
  def handle_call({:query, lon, lat}, _, state) do
    case TzMap.RStar.query(state, {lon, lat}) do
      [%{data: %{tz: tz}}] ->
        {:reply, tz, state}

      [%{data: %{tz: tz}} | _] ->
        Logger.warn(
          "[#{__MODULE__}] TzMap Query for #{{lon, lat}} returned more than one answer."
        )

        {:reply, tz, state}

      [] ->
        {:reply, nil, state}
    end
  end
end
