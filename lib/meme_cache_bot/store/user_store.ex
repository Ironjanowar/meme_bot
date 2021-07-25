defmodule MemeCacheBot.Store.UserStore do
  import MemeCacheBot.Store
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
end
