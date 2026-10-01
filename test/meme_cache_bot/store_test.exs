defmodule MemeCacheBot.StoreTest do
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias MemeCacheBot.Model.{MemeTag, User}
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

  test "returns a changeset error instead of raising for a duplicate telegram id" do
    assert {:ok, _user} = UserStore.insert_user(%{telegram_id: 4242, first_name: "Ada"})
    assert {:ok, _user} = UserStore.insert_user(%{telegram_id: 4243, first_name: "Grace"})

    assert {:error, changeset} = UserStore.insert_user(%{telegram_id: 4242, first_name: "Ada"})
    assert "has already been taken" in errors_on(changeset).telegram_id
  end

  test "accepts the Telegram user struct passed by the registration middleware" do
    telegram_user = %ExGram.Model.User{id: 7, first_name: "Cuwano", username: "Cuwano"}
    params = Map.put(telegram_user, :telegram_id, telegram_user.id)

    assert {:ok, user} = UserStore.insert_user(params)
    assert user.telegram_id == 7
    assert user.first_name == "Cuwano"
    assert user.username == "Cuwano"
  end

  test "replaces tags on each user's personal meme and lists them alphabetically" do
    user1 = insert_user!(101)
    user2 = insert_user!(202)
    meme1 = insert_meme!(user1, "shared")
    meme2 = insert_meme!(user2, "shared")

    assert {:ok, ["gato", "feliz"]} = MemeStore.replace_tags(meme1, ["gato", "feliz"])
    assert {:ok, ["otro"]} = MemeStore.replace_tags(meme2, ["otro"])
    assert {:ok, ["nuevo"]} = MemeStore.replace_tags(meme1, ["nuevo"])

    assert MemeStore.list_tags(meme1) == ["nuevo"]
    assert MemeStore.list_tags(meme2) == ["otro"]
  end

  test "deduplicates tags before storing them" do
    meme = 303 |> insert_user!() |> insert_meme!("duplicate-tags")

    assert {:ok, ["gato"]} = MemeStore.replace_tags(meme, ["gato", "gato"])
    assert MemeStore.list_tags(meme) == ["gato"]
  end

  test "finds only the user's memes matching any requested tag" do
    user = insert_user!(404)
    cat = insert_meme!(user, "cat")
    happy = insert_meme!(user, "happy")
    unrelated = insert_meme!(user, "unrelated")
    other = 405 |> insert_user!() |> insert_meme!("other-cat")

    MemeStore.replace_tags(cat, ["gato"])
    MemeStore.replace_tags(happy, ["feliz"])
    MemeStore.replace_tags(unrelated, ["triste"])
    MemeStore.replace_tags(other, ["gato"])

    ids =
      MemeStore.find_memes(telegram_id: user.telegram_id, tags: ["gato", "feliz"])
      |> Enum.map(& &1.meme_unique_id)
      |> Enum.sort()

    assert ids == ["cat", "happy"]
  end

  test "returns a meme only once when several requested tags match" do
    user = insert_user!(406)
    meme = insert_meme!(user, "both")
    MemeStore.replace_tags(meme, ["gato", "feliz"])

    assert [%{meme_unique_id: "both"}] =
             MemeStore.find_memes(telegram_id: user.telegram_id, tags: ["gato", "feliz"])
  end

  test "rolls back tag replacement when an insertion fails" do
    meme = 407 |> insert_user!() |> insert_meme!("rollback")
    assert {:ok, ["anterior"]} = MemeStore.replace_tags(meme, ["anterior"])

    assert {:error, %Ecto.Changeset{}} = MemeStore.replace_tags(meme, ["nuevo", nil])
    assert MemeStore.list_tags(meme) == ["anterior"]
  end

  test "returns an error when replacing tags on a concurrently deleted meme" do
    meme = 409 |> insert_user!() |> insert_meme!("deleted-before-tags")
    assert {:ok, _deleted} = MemeStore.delete_meme(meme)

    assert {:error, %Ecto.ConstraintError{}} = MemeStore.replace_tags(meme, ["gato"])
  end

  test "deleting a meme cascades to its tags" do
    meme = 408 |> insert_user!() |> insert_meme!("cascade")
    assert {:ok, ["gato"]} = MemeStore.replace_tags(meme, ["gato"])

    assert {:ok, _} = MemeStore.delete_meme(meme)
    assert Repo.aggregate(MemeTag, :count) == 0
  end

  defp insert_user!(telegram_id) do
    {:ok, user} = UserStore.insert_user(%{telegram_id: telegram_id, first_name: "User"})
    user
  end

  defp insert_meme!(user, unique_id) do
    {:ok, meme} =
      MemeStore.insert_meme(%{
        meme_id: "file-#{user.telegram_id}",
        meme_unique_id: unique_id,
        meme_type: "photo",
        user: user
      })

    meme
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
