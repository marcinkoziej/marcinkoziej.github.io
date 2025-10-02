defmodule Portfolio.UI.Window do
  @moduledoc """
  State is a keyword list with:
  - el - DOM element (TrackedValue)

  Arguments:
  - id - the node id value
  - z_index - the z-index value for the window
  """

  use GenServer
  alias Popcorn.Wasm
  import Popcorn.Wasm, only: [is_wasm_message: 1]
  require EEx
  alias Portfolio.UI.WindowManager
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
      el.className = "window terminal-card";
      if (args.content) {
        el.innerHTML = args.content;
      }

      const parentNode = args.container || document.getElementsByTagName("main")[0];
      console.log('parent node is', parentNode);
      parentNode.appendChild(el);

      // make draggable
      // window.Portfolio.draggable(el, "header", ".window");

      // Return the section element as tracked value with a cleanup function
      // that removes it from DOM when the value is GCed on Elixir side.
      const key = wasm.nextTrackedObjectKey();
      wasm.cleanupFunctions.set(key, () => parentNode.removeChild(el))
      return [new TrackedValue({key: key, value: el})];
    }
    """

    id = opts[:id]

    {:ok, el} =
      Wasm.run_js(make_el_js, %{
        id: id,
        container: opts[:container],
        content: opts[:content]
      })

    remove_close_handler = setup_close_handler(el, id)
    remove_drag_handler = WindowManager.setup_drag_handler(el, "header", id)

    IO.puts("init done for #{opts[:id]}")

    {:ok, [id: id, el: el, remove: [close: remove_close_handler, drag: remove_drag_handler]]}
  end

  def setup_close_handler(node, window_id) do
    close_button = DOM.query_selector!(node, ".close")

    {:ok, stop} =
      Wasm.register_event_listener(:click,
        target_node: close_button,
        event_receiver: window_id,
        custom_data: %{action: "close"}
      )

    stop
  end

  @impl true
  def handle_info(raw_msg, state) when is_wasm_message(raw_msg) do
    Wasm.handle_message!(raw_msg, fn
      {:wasm_event, :click, _, %{"action" => "close"}} ->
        Portfolio.UI.remove_window(state[:id])
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
  def handle_cast({:move, {x, y, z}}, state) do
    move_js = """
    ({args}) => {
      args.el.style.zIndex = args.z;
      args.el.style.left = args.x + "px";
      args.el.style.top = args.y + "px";
    }
    """

    Wasm.run_js(move_js, %{el: state[:el], x: x, y: y, z: z})
    {:noreply, state}
  end

  def move(pid, position) do
    GenServer.cast(pid, {:move, position})
  end

  @impl true
  def terminate(reason, _state) do
    IO.puts("terminating reason: #{inspect(reason)}")
    :ok
  end
end
