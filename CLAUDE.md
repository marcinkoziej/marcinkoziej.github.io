# About

This project is my portfolio.
It is meant as a gimmick to show my Elixir skill, by coding portoflio using a Popcorn library, which compiles Elixir to WASM and runs on AtomVM virtual machine.
AtomVM is a stripped-down version of BEAM which works in WASM.

AtomVM website: https://atomvm.org/
Popcorn documentation: https://hexdocs.pm/popcorn/readme.html

# Commands

- `mix build` - creates WASM file in
- `mix dev` - run a hot-reloading server for develompent (at port 4000)
- `mix server` - run a simple local server (at port 4000)

# Architecture

## Panes

A pane is:

- A process
- Has associted div node (by tracked object? or by an id? perhaps by an id? or a tracked object which we can then delete?) - via tracked object!
-
