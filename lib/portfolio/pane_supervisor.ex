defmodule Portfolio.PaneSupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_pane(pane_opts) do
    child_spec = %{
      id: pane_opts[:id],
      start: {Portfolio.PaneView, :start_link, [pane_opts]}
    }

    Supervisor.start_child(__MODULE__, child_spec)
  end

  def stop_pane(id) do
    IO.puts("stopping?")

    Supervisor.terminate_child(__MODULE__, id)
    |> IO.inspect(label: "terminating")

    Supervisor.delete_child(__MODULE__, id)
    |> IO.inspect(label: "deleting")

    IO.puts("eh?")
  end
end
