defmodule Portfolio.UI.WindowSupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_window(pane_opts) do
    child_spec = %{
      id: pane_opts[:id],
      start: {Portfolio.UI.Window, :start_link, [pane_opts]}
    }

    Supervisor.start_child(__MODULE__, child_spec)
  end

  def stop_window(id) do
    Supervisor.terminate_child(__MODULE__, id)

    Supervisor.delete_child(__MODULE__, id)
  end

  def list_windows do
    for {id, pid, _, _} <- Supervisor.which_children(__MODULE__), pid != :undefined, into: %{} do
      {id, pid}
    end
  end

  def count_windows do
    Supervisor.count_children(__MODULE__)[:specs]
  end
end
