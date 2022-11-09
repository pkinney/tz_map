defmodule TzMap.Application do
  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link([TzMap.Server], strategy: :one_for_one)
  end
end
