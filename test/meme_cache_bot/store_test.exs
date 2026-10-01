defmodule MemeCacheBot.StoreTest do
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias MemeCacheBot.Model.User
  alias MemeCacheBot.Repo
  alias MemeCacheBot.Store.{MemeStore, UserStore}

  setup do
    :ok = Sandbox.checkout(Repo)
    :ok
  end

  test "persists users and memes in SQLite while enforcing uniqueness" do
    assert {:ok, user} =
             UserStore.insert_user(%{telegram_id: 9_223_372_036_854_775_000, first_name: "Ada"})

    assert %User{id: id} = UserStore.find_user(telegram_id: user.telegram_id)
    assert is_binary(id)

    meme = %{
      meme_id: "telegram-file",
      meme_unique_id: "unique-file",
      meme_type: "photo",
      user: user
    }

    assert {:ok, saved} = MemeStore.insert_meme(meme)
    assert saved.telegram_id == user.telegram_id
    assert {:error, duplicate_changeset} = MemeStore.insert_meme(meme)
    assert "has already been taken" in errors_on(duplicate_changeset).meme_unique_id
  end

  test "returns no meme master when the database has no users" do
    assert UserStore.get_meme_master() == nil
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
