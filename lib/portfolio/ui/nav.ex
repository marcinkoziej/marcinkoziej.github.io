defmodule Portfolio.UI.Nav do
  use GenServer
  alias Popcorn.Wasm
  import Popcorn.Wasm, only: [is_wasm_message: 1]
  alias Portfolio.DOM
  alias Portfolio.UI.WindowManager

  @process_name :nav
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: @process_name)
  end

  def init(_opts) do
    state =
      %{}
      |> listen_hashchange()

    {:ok, state, {:continue, :check_hash}}
  end

  def handle_continue(:check_hash, state) do
    current_hash()
    |> handle_hash()

    {:noreply, state}
  end

  def listen_hashchange(state) do
    window = DOM.window()

    case Wasm.register_event_listener(:hashchange,
           target_node: window,
           event_receiver: @process_name,
           event_keys: [:newURL]
         ) do
      {:ok, listener} -> Map.put(state, :hashchange_listener, listener)
      {:error, why} -> IO.puts("Could not register hashchange listener (#{inspect(why)})")
    end
  end

  def handle_info(raw_msg, state) when is_wasm_message(raw_msg) do
    state =
      Wasm.handle_message!(raw_msg, fn
        {:wasm_event, :hashchange, %{"newURL" => new_url}, _} ->
          new_url
          |> parse_hash()
          |> handle_hash()

          state
      end)

    {:noreply, state}
  end

  def handle_hash(hash) do
    # hash is window id to raise or open
    window_id =
      try do
        String.to_existing_atom(hash)
      rescue
        ArgumentError -> :page_not_found
      end

    if window_id != :page_not_found do
      WindowManager.open_or_raise(window_id)
    end
  end

  defp parse_hash(url) do
    # URI.parse is not implemented in AtomVM
    case String.split(url, "#") do
      [_, hash] -> hash
      _ -> ""
    end
  end

  defp current_hash() do
    hash =
      Wasm.run_js!("""
      () => {
        return [window.location.hash];
      }
      """)

    [hash] = Wasm.get_tracked_values!([hash])
    String.trim_leading(hash, "#")
  end
end
