defmodule Portfolio.LayoutView do
  require EEx
  EEx.function_from_file(:def, :layout, "lib/portfolio/templates/layout.html.eex", [:assigns])
end
