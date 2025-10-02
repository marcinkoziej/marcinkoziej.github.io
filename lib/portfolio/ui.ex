defmodule Portfolio.UI do
  alias Popcorn.Wasm
  alias Portfolio.ContentView
  alias Portfolio.UI.WindowManager

  def show() do
    show_layout()
    add_window(id: :welcome, content: ContentView.welcome(%{}))
    add_window(id: :second, content: ContentView.about(%{}))
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

  def add_window(opts) do
    WindowManager.add_window(opts)
  end

  def remove_window(window_id) do
    WindowManager.remove_window(window_id)
  end
end
