import Config
config :popcorn, out_dir: "static/wasm"

# I think this does not work in WASM version
config :logger, level: :error

config :portfolio, Portfolio.UI,
  toc: [
    welcome: [template: {:welcome, %{}}],
    about: [template: {:about, %{}}],
    breganor: [template: {:breganor, %{}}],
    proca: [template: {:proca, %{}}],
    portfolio: [template: {:portfolio, %{}}],
    technical: [template: {:technical, %{}}],
    experience: [template: {:experience, %{}}],
    contact: [template: {:contact, %{}}]
  ]
