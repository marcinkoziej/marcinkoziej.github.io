defmodule Portfolio.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Portfolio.PaneSupervisor,
      Portfolio.Worker
    ]

    opts = [strategy: :one_for_one, name: Portfolio.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
