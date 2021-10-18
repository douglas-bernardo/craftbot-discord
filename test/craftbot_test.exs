defmodule CraftbotTest do
  use ExUnit.Case
  doctest Craftbot

  test "greets the world" do
    assert Craftbot.hello() == :world
  end
end
