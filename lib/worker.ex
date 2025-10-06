defmodule Portfolio.Worker do
  use GenServer
  import Popcorn.Wasm
  alias Popcorn.Wasm

  @process_name :main

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @process_name)
  end

  @impl true
  def init(_init_arg) do
    Popcorn.Wasm.register(@process_name)

    Portfolio.UI.show()

    state = %{}
    {:ok, state}
  end

  @impl GenServer
  def handle_info(raw_msg, state) when is_wasm_message(raw_msg) do
    state = Wasm.handle_message!(raw_msg, &handle_wasm(&1, state))
    {:noreply, state}
  end

  defp handle_wasm({:wasm_call, %{"command" => "terminal_input", "text" => text}}, state) do
    case Portfolio.Terminal.send_input(text) do
      :ok -> {:resolve, :ok, state}
      # XXX or :reject?
      error -> {:resolve, error, state}
    end
  end

  # Handle any other messages that might come through
  defp handle_wasm({:wasm_call, msg}, state) do
    {:resolve, {:unknown_command, msg}, state}
  end
end
