defmodule Portfolio.UI.WindowManager do
  use GenServer
  alias Popcorn.Wasm
  alias Portfolio.DOM
  import Popcorn.Wasm, only: [is_wasm_message: 1]
  alias Portfolio.UI.{WindowSupervisor, Window}

  @min_z 1
  @cellh 10
  @cellw 10
  @process_name :window_manager
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: @process_name)
  end

  def init(_opts) do
    state = %{
      position: %{}
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
          window_id = String.to_existing_atom(window_id)
          state |> raise_window(window_id)
      end)

    {:noreply, state}
  end

  def handle_cast({:add_window, opts}, state) do
    case WindowSupervisor.start_window(opts) do
      {:ok, pid} ->
        {state, new_position} = new_window_position(state, opts[:id])
        Window.move(pid, new_position)

        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  def new_window_position(state, id) do
    zs =
      Map.values(state[:position])
      |> Enum.map(&elem(&1, 2))

    max_z = Enum.max([@min_z - 1 | zs]) + 1

    winct = map_size(state[:position])

    new_position = {winct * @cellw, winct * @cellh, max_z}
    state = put_in(state, [:position, id], new_position)

    {state, new_position}
  end

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

  def add_window(opts) do
    GenServer.cast(@process_name, {:add_window, opts})
  end

  def remove_window(window_id) do
    WindowSupervisor.stop_window(window_id)
  end

  def raise_window(state, window_id) do
    state = reorder_positions_to_raise(state, window_id)

    for {id, wpid} <- WindowSupervisor.list_windows() do
      Window.move(wpid, state[:position][id])
    end

    state
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
end
