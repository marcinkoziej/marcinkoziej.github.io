defmodule Portfolio.PaneView do
  @moduledoc """
  State is a keyword list with:
  - el - DOM element (TrackedValue)

  Arguments:
  - id - the node id value
  """

  use GenServer
  alias Popcorn.Wasm
  import Popcorn.Wasm, only: [is_wasm_message: 1]
  require EEx
  alias Portfolio.DOM

  def start_link(opts) do
    default_id = :pane
    opts = Keyword.merge([id: default_id], opts)
    GenServer.start_link(__MODULE__, opts, name: opts[:id])
  end

  # seems dialyzer is confused by WASM api
  @dialyzer {:no_return, init: 1}
  @impl true
  def init(opts) do
    make_el_js = """
    ({args, wasm}) => {
      console.log("WASM obj", wasm);

      const el = document.createElement("section");
      el.id = args.id;
      el.className = "pane terminal-card";
      if (args.content) {
        el.innerHTML = args.content;
      }

      const parentNode = args.container || document.getElementsByTagName("main")[0];
      console.log('parent node is', parentNode);
      parentNode.appendChild(el);

      // make draggable
      window.Portfolio.draggable(el, "header", ".pane");

      // Return the section element as tracked value with a cleanup function
      // that removes it from DOM when the value is GCed on Elixir side.
      const key = wasm.nextTrackedObjectKey();
      wasm.cleanupFunctions.set(key, () => parentNode.removeChild(el))
      return [new TrackedValue({key: key, value: el})];
    }
    """

    {:ok, el_ref} =
      Wasm.run_js(make_el_js, %{
        id: opts[:id],
        container: opts[:container],
        content: opts[:content]
      })

    cancel_close_handler = setup_close_handler(el_ref, opts[:id])

    IO.puts("init done for #{opts[:id]}")

    {:ok, [id: opts[:id], el: el_ref, cancel_handlers: [cancel_close_handler]]}
  end

  def setup_close_handler(node, receiver) do
    close_button = DOM.query_selector!(node, ".close")

    {:ok, cancel} =
      Wasm.register_event_listener(:click,
        target_node: close_button,
        event_receiver: receiver,
        custom_data: %{action: "close"}
      )

    cancel
  end

  @impl true
  def handle_info([], _state) do
    IO.puts("bye")
    {:stop, :normal}
  end

  @impl true
  def handle_info(raw_msg, state) when is_wasm_message(raw_msg) do
    Wasm.handle_message!(raw_msg, fn
      {:wasm_event, :click, _, %{"action" => "close"}} ->
        Portfolio.UI.remove_pane(state[:id])
        {:noreply, state}

      ev ->
        IO.inspect(ev, label: "other WASM event")
        {:noreply, state}
    end)
  end

  @impl true
  def handle_info(other_msg, state) do
    IO.inspect(other_msg, label: "other message")
    {:noreply, state}
  end

  @impl true
  def terminate(reason, _state) do
    IO.puts("terminating reason: #{inspect(reason)}")
    :ok
  end
end
