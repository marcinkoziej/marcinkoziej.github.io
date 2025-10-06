defmodule Portfolio.Terminal.Helpers do
  def help do
    """
    Beside all Elixir can give, some commands available:

    help - this message
    windows - list open windows
    kill :window_id - kill a window

    """
    |> IO.puts()
  end

  def windows do
    IO.puts("# window_id (pid)")

    Portfolio.UI.WindowSupervisor.list_windows()
    |> Enum.with_index()
    |> Enum.map(fn {{id, pid}, index} -> "#{index + 1}. :#{id} (pid: #{inspect(pid)})" end)
    |> Enum.join("\n")
    |> no_windows()
    |> IO.puts()
  end

  defp no_windows("") do
    "No windows open (click on navigation above)"
  end

  defp no_windows(text) do
    text
  end

  def kill(window_id) when is_atom(window_id) do
    Portfolio.UI.WindowManager.remove_window(window_id)
  end
end
