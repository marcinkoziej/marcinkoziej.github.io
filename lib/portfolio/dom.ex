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
end
