defmodule Portfolio.UI do
  alias Popcorn.Wasm
  alias Portfolio.ContentView
  alias Portfolio.PaneSupervisor

  def show() do
    show_layout()
    add_pane(id: :welcome, content: ContentView.welcome(%{}))
    add_pane(id: :second, content: ContentView.about(%{}))
    IO.puts("show/")
  end

  def show_layout do
    html = Portfolio.LayoutView.layout(title: "Portfolio")

    Wasm.run_js(
      """
      ({args}) => {
        const body = document.getElementsByTagName("body")[0];
        body.innerHTML = args.html;
      }
      """,
      %{html: html}
    )
  end

  def add_pane(pane_opts) do
    PaneSupervisor.start_pane(pane_opts)
  end

  def remove_pane(pane_id) do
    PaneSupervisor.stop_pane(pane_id)
  end
end
