defmodule Portfolio.ContentView do
  require EEx
  EEx.function_from_file(:def, :welcome, "lib/portfolio/templates/welcome.html.eex", [:assigns])
  EEx.function_from_file(:def, :about, "lib/portfolio/templates/about.html.eex", [:assigns])
  EEx.function_from_file(:def, :breganor, "lib/portfolio/templates/breganor.html.eex", [:assigns])
  EEx.function_from_file(:def, :proca, "lib/portfolio/templates/proca.html.eex", [:assigns])

  EEx.function_from_file(:def, :portfolio, "lib/portfolio/templates/portfolio.html.eex", [
    :assigns
  ])

  EEx.function_from_file(:def, :technical, "lib/portfolio/templates/technical.html.eex", [
    :assigns
  ])

  EEx.function_from_file(:def, :experience, "lib/portfolio/templates/experience.html.eex", [
    :assigns
  ])

  EEx.function_from_file(:def, :contact, "lib/portfolio/templates/contact.html.eex", [:assigns])

  def header(text) do
    """
    <header><span class="title"><b>#{text}</b></span><span class="close">&times;</span></header>
    """
  end
end
