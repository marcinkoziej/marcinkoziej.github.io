defmodule PortfolioTest do
  use ExUnit.Case
  doctest Portfolio

  test "greets the world" do
    assert Portfolio.hello() == :world
  end
end
