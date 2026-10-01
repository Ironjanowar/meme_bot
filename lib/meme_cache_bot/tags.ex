defmodule MemeCacheBot.Tags do
  @moduledoc false

  def parse_query(text) when is_binary(text) do
    text
    |> String.downcase()
    |> String.split(~r/[\s,]+/u, trim: true)
    |> Enum.filter(&(String.length(&1) <= 32))
    |> Enum.reject(&Regex.match?(~r/^\d+$/u, &1))
    |> Enum.uniq()
    |> Enum.take(20)
  end

  def parse(text) when is_binary(text) do
    tags =
      text
      |> String.split(",")
      |> Enum.map(&(&1 |> String.trim() |> String.downcase()))
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    cond do
      tags == [] -> {:error, :empty}
      length(tags) > 20 -> {:error, :too_many}
      Enum.any?(tags, &(String.length(&1) > 32)) -> {:error, :too_long}
      Enum.any?(tags, &Regex.match?(~r/^\d+$/u, &1)) -> {:error, :numeric}
      Enum.any?(tags, &Regex.match?(~r/\s/u, &1)) -> {:error, :whitespace}
      true -> {:ok, tags}
    end
  end
end
