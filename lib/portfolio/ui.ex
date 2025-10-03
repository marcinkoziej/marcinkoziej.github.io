defmodule Portfolio.UI do
  alias Portfolio.UI.WindowManager
  alias Portfolio.DOM

  def show() do
    show_layout()
    # add_window(id: :welcome, content: ContentView.welcome(%{}))
    # add_window(id: :second, content: ContentView.about(%{}))
  end

  def toc() do
    Application.get_env(:portfolio, Portfolio.UI)[:toc]
  end

  def show_layout do
    Portfolio.LayoutView.layout(title: "Portfolio")
    |> DOM.render_to(tag_name: "body")
  end

  def add_window(id_or_opts) do
    WindowManager.add_window(id_or_opts)
  end

  def remove_window(window_id) do
    WindowManager.remove_window(window_id)
  end
end
