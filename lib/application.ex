defmodule Portfolio.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Portfolio.UI.WindowSupervisor,
      Portfolio.UI.WindowManager,
      Portfolio.UI.Nav,
      Portfolio.Worker
    ]

    opts = [strategy: :one_for_one, name: Portfolio.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
