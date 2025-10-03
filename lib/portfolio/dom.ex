defmodule Portfolio.DOM do
  alias Popcorn.Wasm

  @doc """
  Perform node.querySelector(selector)
  Raise exception if not found
  """
  @spec query_selector!(Popcorn.TrackedObject.t(), String.t()) :: Popcorn.TrackedObject.t()
  def query_selector!(node, selector) do
    select_js = """
    ({args}) => {
      return [args.node.querySelector(args.selector)]
    }
    """

    case Wasm.run_js(select_js, %{
           node: node,
           selector: selector
         }) do
      {:ok, node} -> node
      error -> raise "Failed to query for #{selector}: #{inspect(error)}"
    end
  end

  def document() do
    try do
      Wasm.run_js!("() => { return [document]; }")
    rescue
      ErlangError -> :"DOM.document"
    end
  end

  def window() do
    try do
      Wasm.run_js!("() => { return [window]; }")
    rescue
      ErlangError -> :"DOM.window"
    end
  end

  def render_to(html, [{:tag_name, tag_name} | _]) do
    Wasm.run_js(
      """
      ({args}) => {
        const body = document.getElementsByTagName(args.tag_name)[0];
        body.innerHTML = args.html;
      }
      """,
      %{html: html, tag_name: tag_name}
    )
  end
end
