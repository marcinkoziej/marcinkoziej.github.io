defmodule Portfolio.UI.WindowManager do
  use GenServer
  alias Portfolio.DOM
  alias Popcorn.Wasm
  import Popcorn.Wasm, only: [is_wasm_message: 1]
  alias Portfolio.UI.{WindowSupervisor, Window, Nav}
  alias Portfolio.ContentView

  @min_z 1
  @cellh 10
  @cellw 10
  @process_name :window_manager
  @mobile_breakpoint 768
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: @process_name)
  end

  def init(_opts) do
    # Detect initial mobile state
    is_mobile = detect_mobile()

    # Set up resize listener to track mobile state changes
    resize_listener = setup_resize_listener()

    state = %{
      position: %{},
      dragging: nil,
      mobile: is_mobile,
      listeners: [resize_listener]
    }

    {:ok, state}
  end

  def handle_info(raw_msg, state) when is_wasm_message(raw_msg) do
    state =
      Wasm.handle_message!(raw_msg, fn
        {:wasm_event, :mousedown, _,
         %{
           "action" => "drag",
           "window" => window_id
         }} ->
          window_id =
            String.to_existing_atom(window_id)

          state
          |> raise_window_on_desktop(window_id, state[:mobile])
          |> drag_window_on_desktop(window_id, state[:mobile])

        {:wasm_event, :mousemove, ev, %{"window" => window_id}} ->
          window_id = String.to_existing_atom(window_id)

          state = drag_window_position(state, window_id, ev["movementX"], ev["movementY"])
          Window.move(window_id, state[:position][window_id])
          state

        {:wasm_event, :mouseup, _, _} ->
          state |> Map.put(:dragging, nil)

        {:wasm_event, :resize, _, _} ->
          # Handle viewport size changes
          is_mobile = detect_mobile()
          state |> handle_resize(is_mobile)
      end)

    {:noreply, state}
  end

  def handle_cast({:add_window, opts}, state) do
    case WindowSupervisor.start_window(opts) do
      {:ok, pid} ->
        if state[:mobile] do
          # Skip positioning on mobile - let windows use natural flow
          set_active_window(opts[:id])
          {:noreply, state}
        else
          {state, new_position} = new_window_position(state, opts[:id])
          Window.move(pid, new_position)
          set_active_window(opts[:id])
          {:noreply, state}
        end

      _ ->
        {:noreply, state}
    end
  end

  def handle_cast({:open_or_raise, window_id}, state) do
    windows = WindowSupervisor.list_windows()

    state =
      if Map.has_key?(windows, window_id) do
        raise_window(state, window_id)
      else
        add_window(window_id)
        state
      end

    {:noreply, state}
  end

  def new_window_position(state, id) do
    zs =
      Map.values(state[:position])
      |> Enum.map(&elem(&1, 2))

    max_z = Enum.max([@min_z - 1 | zs]) + 1

    winct = WindowSupervisor.count_windows()

    # how many cells to right/down should we place the new window
    off_by = 4
    new_position = {off_by * (winct - 1) * @cellw, off_by * (winct - 1) * @cellh, max_z}
    state = put_in(state, [:position, id], new_position)

    {state, new_position}
  end

  def drag_window_position(
        %{dragging: dragging, position: position} = state,
        window_id,
        by_x,
        by_y
      )
      when not is_nil(dragging) do
    quantize = fn v, q -> {v - rem(v, q), rem(v, q)} end

    {x, y, z} = position[window_id]
    {x_ex, y_ex} = dragging[:extra]

    {dx, rem_x} = quantize.(by_x + x_ex, @cellw)
    {dy, rem_y} = quantize.(by_y + y_ex, @cellh)

    new_position = {max(0, x + dx), max(0, y + dy), z}

    position = Map.put(position, window_id, new_position)

    %{
      state
      | position: position,
        dragging: %{dragging | extra: {rem_x, rem_y}}
    }
  end

  def drag_window_position(state, _, _, _) do
    state
  end

  @dialyzer {:no_return, setup_drag_handler: 3}
  def setup_drag_handler(node, handle_selector, window_id) do
    header = DOM.query_selector!(node, handle_selector)

    {:ok, stop} =
      Wasm.register_event_listener(:mousedown,
        target_node: header,
        event_receiver: @process_name,
        custom_data: %{action: "drag", window: window_id}
      )

    stop
  end

  def add_window(opts) when is_list(opts) do
    GenServer.cast(@process_name, {:add_window, opts})
  end

  def add_window(window_id) when is_atom(window_id) do
    window_spec =
      Portfolio.UI.toc()[window_id]

    if window_spec do
      opts = [id: window_id]
      {view, assocs} = window_spec[:template]

      opts =
        if function_exported?(ContentView, view, 1) do
          Keyword.put(opts, :content, apply(ContentView, view, [assocs]))
        else
          raise ArgumentError, message: "View #{view} does not exist"
        end

      add_window(opts)
    end
  end

  def remove_window(window_id) do
    Nav.set_hash()
    WindowSupervisor.stop_window(window_id)
  end

  def raise_window_on_desktop(state, window_id, _mobile = true) do
    set_active_window(window_id)
    state
  end

  def raise_window_on_desktop(state, window_id, _mobile = false) do
    state |> raise_window(window_id)
  end

  def raise_window(state, window_id) do
    state =
      reorder_positions_to_raise(state, window_id)

    for {id, wpid} <- WindowSupervisor.list_windows() do
      Window.move(wpid, state[:position][id])
    end

    set_active_window(window_id)

    state
  end

  def drag_window_on_desktop(state, _window_id, true), do: state

  def drag_window_on_desktop(state, window_id, false) do
    state |> drag_window(window_id)
  end

  @dialyzer {:no_return, drag_window: 2}
  def drag_window(state, window_id) do
    disable_selecting(true)
    document = DOM.document()

    dragging =
      Wasm.register_event_listener(:mousemove,
        event_keys: [:movementX, :movementY],
        event_receiver: :window_manager,
        target_node: document,
        custom_data: %{window: window_id}
      )

    mouse_up =
      Wasm.register_event_listener(:mouseup,
        event_receiver: :window_manager,
        target_node: document
      )

    state
    |> Map.put(:dragging, %{extra: {0, 0}, listeners: [dragging, mouse_up]})
  end

  defp reorder_positions_to_raise(state, window_id) do
    {x0, y0, _z0} = state[:position][window_id]

    reordered =
      state[:position]
      |> Enum.reject(fn {id, _pos} -> id == window_id end)
      |> Enum.sort()
      |> Enum.with_index()
      |> Enum.map(fn {{id, {x, y, _z}}, index} ->
        {id, {x, y, index + @min_z}}
      end)
      |> Enum.into(%{})

    reordered =
      reordered
      |> Map.put(window_id, {x0, y0, map_size(reordered) + @min_z})

    %{state | position: reordered}
  end

  def disable_selecting(disabled?) do
    js = """
    ({args}) => {
      if (args.disabled) {
        document.body.classList.add("no-select");
      } else {
        document.body.classList.remove("no-select");
      }
    }
    """

    Wasm.run_js!(js, %{disabled: disabled?})
  end

  def open_or_raise(window_id) do
    GenServer.cast(@process_name, {:open_or_raise, window_id})
  end

  defp set_active_window(window_id) do
    Nav.set_hash(window_id)

    js = """
    ({args}) => {
      const windows = document.querySelectorAll(".window");
      windows.forEach((window) => {
        window.classList.remove("active");
      })
      const activeWindow = document.getElementById(args.id);
      activeWindow.classList.add("active");
    }
    """

    Wasm.run_js!(js, %{id: window_id})
  end

  @dialyzer {:no_return, detect_mobile: 0}
  defp detect_mobile() do
    js = """
    () => {
      return [window.innerWidth <= #{@mobile_breakpoint}];
    }
    """

    try do
      Wasm.run_js!(js, %{}, return: :value)
    rescue
      _ -> false
    end
  end

  @dialyzer {:no_return, setup_resize_listener: 0}
  defp setup_resize_listener() do
    window = DOM.window()

    try do
      {:ok, listener} =
        Wasm.register_event_listener(:resize, target_node: window, event_receiver: @process_name)

      listener
    rescue
      _ -> :mock_listener
    end
  end

  def handle_resize(state, is_mobile) do
    # GenServer.cast(@process_name, {:viewport_changed, is_mobile})

    # If switching from mobile to desktop, we might want to reposition windows
    # If switching from desktop to mobile, windows will naturally stack
    if not state[:mobile] and is_mobile do
      # Switching to mobile - remove all positioning
      for {_id, wpid} <- WindowSupervisor.list_windows() do
        # Reset window positions by removing inline styles
        reset_window_positioning(wpid)
      end
    end

    %{state | mobile: is_mobile}
  end

  @dialyzer {:no_return, reset_window_positioning: 1}
  defp reset_window_positioning(window_pid) do
    js = """
    ({args}) => {
      const el = args.el;
      if (el && el.style) {
        el.style.position = '';
        el.style.left = '';
        el.style.top = '';
        el.style.zIndex = '';
      }
    }
    """

    state = :sys.get_state(window_pid)

    if state[:el] do
      Wasm.run_js!(js, %{el: state[:el]})
    end
  end
end
