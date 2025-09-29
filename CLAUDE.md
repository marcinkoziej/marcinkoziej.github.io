# About 

This project is my portfolio.
It is meant as a gimmick to show my Elixir skill, by coding portoflio using a Popcorn library, which compiles Elixir to WASM and runs on AtomVM virtual machine.
AtomVM is a stripped-down version of BEAM which works in WASM.

AtomVM website: https://atomvm.org/
Popcorn documentation: https://hexdocs.pm/popcorn/readme.html

# Commands 

- `mix popcorn.cook` - creates WASM file in 



# Setup

The easiest way to host the page is to generate a simple HTTP server script with `mix popcorn.simple_server` and run it with `elixir server.exs`. 
Then, at `http://localhost:4000`, you should see Hello from WASM printed in the console.

