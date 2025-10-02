defmodule Portfolio.ContentView do
  require EEx
  EEx.function_from_file(:def, :welcome, "lib/portfolio/templates/welcome.html.eex", [:assigns])
  EEx.function_from_file(:def, :about, "lib/portfolio/templates/about.html.eex", [:assigns])

  def header(text) do
    """
    <header><b>#{text}</b><span class="close">&times;</span></header>
    """
  end
end
