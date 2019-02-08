defmodule DynamoMigrateTest do
  use ExUnit.Case
  doctest DynamoMigrate

  test "greets the world" do
    assert DynamoMigrate.hello() == :world
  end
end
