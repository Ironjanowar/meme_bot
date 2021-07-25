defmodule MemeCacheBot.Store.MemeStore do
  import Ecto.Query
  import MemeCacheBot.Store
  alias MemeCacheBot.Repo
  alias MemeCacheBot.Model.Meme

  def find_meme(opts \\ []) do
    Meme
    |> maybe_where_telegram_id(opts[:telegram_id])
    |> maybe_where_meme_unique_id(opts[:meme_unique_id])
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

  def delete_meme(%Meme{} = meme), do: meme |> Map.from_struct() |> delete_meme()

  def delete_meme(%{telegram_id: telegram_id, meme_unique_id: meme_unique_id}) do
    case find_meme(telegram_id: telegram_id, meme_unique_id: meme_unique_id) do
      nil -> {:error, "Meme was not found"}
      meme -> Repo.delete(meme)
    end
  end

  def delete_meme(_), do: {:error, "Can not find meme with that params"}

  # Private
  defp maybe_where_telegram_id(query, nil), do: query

  defp maybe_where_telegram_id(query, telegram_id) when is_integer(telegram_id),
    do: where(query, telegram_id: ^telegram_id)

  defp maybe_where_meme_unique_id(query, nil), do: query

  defp maybe_where_meme_unique_id(query, meme_unique_id) when is_binary(meme_unique_id),
    do: where(query, meme_unique_id: ^meme_unique_id)

  defp maybe_preload(query, nil), do: query
  defp maybe_preload(query, preload) when is_atom(preload), do: preload(query, ^preload)
end
