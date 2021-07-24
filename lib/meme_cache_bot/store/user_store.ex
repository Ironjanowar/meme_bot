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

  def insert_user(user_params) do
    user_params
    |> Map.new()
    |> User.insert_changeset()
    |> Repo.insert()
  end

  # Private
  defp maybe_where_telegram_id(query, nil), do: query

  defp maybe_where_telegram_id(query, telegram_id) when is_integer(telegram_id),
    do: where(query, telegram_id: ^telegram_id)

  defp maybe_preload(query, nil), do: query
  defp maybe_preload(query, preload) when is_atom(preload), do: preload(query, ^preload)
end
