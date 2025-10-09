defmodule Portfolio.Terminal do
  use GenServer
  alias Popcorn.Wasm

  # make sure it's compiled
  require Portfolio.Terminal.Helpers

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @tty_name :portfolio_tty

  @impl GenServer
  def init(_opts) do
    Process.flag(:trap_exit, true)

    ExTTY.start_link(
      handler: self(),
      shell_opts: [dot_iex_path: "", colors: [syntax_colors: false]],
      name: @tty_name,
      type: :elixir
    )

    initialize_term_gui()

    {:ok, %{}}
  end

  @impl GenServer
  def handle_info({:tty_data, code_output}, state) do
    # XXX This is a hack to import helpers into terminal on start and restart.
    # After a deep dive into ExTTY and IEx, I was not able to figure out how to monitor for IEx.Evaluator errors
    # What make it harder is that in WASM, some process introspection calls (Process.info) crash
    if String.starts_with?(code_output, "Interactive Elixir") do
      send_input("import Portfolio.Terminal.Helpers  # setup REPL commands\n")
    end

    # Send output to the JavaScript terminal
    """
    ({ args }) => {
      if (window.terminal) {
        window.terminal.write(args.code_output);
      }
    }
    """
    |> Wasm.run_js(%{code_output: code_output})

    {:noreply, state}
  end

  def handle_info(other, state) do
    IO.inspect(other, label: "Terminal got info from")
    {:noreply, state}
  end

  @impl true
  def terminate(reason, _state) do
    IO.inspect(reason, label: "Terminal terminated")
    :ok
  end

  # Public API for sending input to the terminal
  def send_input(text) do
    try do
      ExTTY.send_text(@tty_name, text)
    rescue
      error -> error
    end
  end

  def initialize_term_gui do
    try do
      Wasm.run_js!("""
      () => {
        setTimeout(() => {
        const terminalElement = document.querySelector(".terminal");

        if (terminalElement) {
          window.Portfolio.initializeTerminal(terminalElement);
        } else {
          console.warn("Terminal element not found");
        }
        }, 100);
      }
      """)
    rescue
      _ -> IO.puts("Failed to initialize terminal")
    end
  end
end
