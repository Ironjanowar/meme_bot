defmodule MemeCacheBot.Store.MemeStore do
  import Ecto.Query
  import MemeCacheBot.Store
  alias MemeCacheBot.Repo
  alias MemeCacheBot.Model.Meme

  def find_meme(opts \\ []) do
    Meme
    |> maybe_where_telegram_id(opts[:telegram_id])
    |> maybe_preload(opts[:preload])
    |> maybe_limit(opts[:limit])
    |> Repo.one()
  end

  def insert_meme(meme_params) do
    meme_params
    |> Map.new()
    |> Meme.insert_changeset()
    |> Repo.insert()
  end

  def count_memes(opts \\ []) do
    Meme
    |> maybe_where_telegram_id(opts[:telegram_id])
    |> Repo.aggregate(:count, :id)
  end

  # Private
  defp maybe_where_telegram_id(query, nil), do: query

  defp maybe_where_telegram_id(query, telegram_id) when is_integer(telegram_id),
    do: where(query, telegram_id: ^telegram_id)

  defp maybe_preload(query, nil), do: query
  defp maybe_preload(query, preload) when is_atom(preload), do: preload(query, ^preload)
end
