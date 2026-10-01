defmodule MemeCacheBot.Store.UserStore do
  @moduledoc false

  import Ecto.Query
  import MemeCacheBot.Store
  alias MemeCacheBot.Model.{Meme, User}
  alias MemeCacheBot.Repo

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
    |> to_params()
    |> User.insert_changeset()
    |> Repo.insert()
  end

  # The registration middleware forwards a Telegram user struct, which Map.new/1
  # cannot enumerate.
  defp to_params(%_{} = struct), do: Map.from_struct(struct)
  defp to_params(user_params), do: Map.new(user_params)

  def count_users do
    Repo.aggregate(User, :count, :id)
  end

  def get_meme_master do
    find_users(preload: :memes)
    |> Enum.max_by(&length(&1.memes), fn -> nil end)
  end

  def top_users do
    from(user in User,
      join: meme in Meme,
      on: meme.telegram_id == user.telegram_id,
      group_by: [user.telegram_id, user.first_name, user.username],
      order_by: [desc: count(meme.id), asc: user.telegram_id],
      limit: 10,
      select: %{
        telegram_id: user.telegram_id,
        first_name: user.first_name,
        username: user.username,
        meme_count: count(meme.id)
      }
    )
    |> Repo.all()
  end
end
