defmodule Portfolio.UI do
  alias Portfolio.UI.WindowManager
  alias Portfolio.DOM
  alias Popcorn.Wasm

  def show() do
    show_layout()
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
