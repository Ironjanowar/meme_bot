defmodule MemeCacheBot.Store.UserStore do
  import Ecto.Query
  alias MemeCacheBot.Repo
  alias MemeCacheBot.Model.User

  def find_user(opts \\ []) do
    User
    |> maybe_where_telegram_id(opts[:telegram_id])
    |> maybe_preload(opts[:preload])
    |> Repo.one()
  end

  def find_users(opts \\ []) do
    User
    |> maybe_limit(opts[:limit])
    |> maybe_preload(opts[:preload])
    |> maybe_order_by(opts[:order_by])
    |> Repo.all()
  end

  def insert_user(user_params) do
    user_params
    |> Map.new()
    |> User.insert_changeset()
    |> Repo.insert()
  end

  def count_users() do
    Repo.aggregate(User, :count, :id)
  end

  def get_meme_master() do
    find_users(preload: :memes)
    |> Enum.max_by(&length(&1.memes))
  end

  # Private
  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, ^limit)

  defp maybe_order_by(query, nil), do: query
  defp maybe_order_by(query, order), do: order_by(query, ^order)

  defp maybe_where_telegram_id(query, nil), do: query

  defp maybe_where_telegram_id(query, telegram_id) when is_integer(telegram_id),
    do: where(query, telegram_id: ^telegram_id)

  defp maybe_preload(query, nil), do: query
  defp maybe_preload(query, preload) when is_atom(preload), do: preload(query, ^preload)
end
