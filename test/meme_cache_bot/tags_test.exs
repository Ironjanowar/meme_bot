defmodule MemeCacheBot.TagsTest do
  use ExUnit.Case, async: true

  alias MemeCacheBot.Tags

  test "normalizes and deduplicates comma-separated tags in input order" do
    assert {:ok, ["gato", "feliz"]} = Tags.parse("Gato, FELIZ, gato")
  end

  test "ignores empty comma-separated segments" do
    assert {:ok, ["gato", "feliz"]} = Tags.parse("gato, ,feliz,,")
  end

  test "rejects an empty tag list" do
    assert {:error, :empty} = Tags.parse(" , , ")
  end

  test "rejects tags containing whitespace" do
    assert {:error, :whitespace} = Tags.parse("gato feliz")
  end

  test "rejects more than twenty tags" do
    input = 1..21 |> Enum.map_join(",", &"tag#{&1}")
    assert {:error, :too_many} = Tags.parse(input)
  end

  test "rejects tags longer than thirty-two characters" do
    assert {:error, :too_long} = Tags.parse(String.duplicate("a", 33))
  end

  test "rejects purely numeric tags" do
    assert {:error, :numeric} = Tags.parse("123")
  end

  test "normalizes inline tokens separated by spaces or commas" do
    assert ["gato", "feliz"] = Tags.parse_query(" GATO,feliz gato ")
  end
end
