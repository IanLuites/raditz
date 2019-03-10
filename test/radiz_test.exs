defmodule RadizTest do
  use ExUnit.Case
  doctest Raditz

  test "greets the world" do
    assert Raditz.hello() == :world
  end
end
