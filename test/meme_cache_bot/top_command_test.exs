defmodule MemeCacheBot.TopCommandTest do
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias ExGram.Bot.SetupCommands
  alias ExGram.Cnt
  alias ExGram.Responses.Answer
  alias MemeCacheBot.{Bot, MessageFormatter, Repo}
  alias MemeCacheBot.Store.{MemeStore, UserStore}

  setup do
    :ok = Sandbox.checkout(Repo)

    previous_admins = Application.get_env(:meme_cache_bot, :admins)
    Application.put_env(:meme_cache_bot, :admins, Jason.encode!([40]))

    on_exit(fn ->
      if previous_admins do
        Application.put_env(:meme_cache_bot, :admins, previous_admins)
      else
        Application.delete_env(:meme_cache_bot, :admins)
      end
    end)

    :ok
  end

  test "a user without a username is shown without an invented Telegram handle" do
    assert {"Top users\n\n1. Ada — 2 memes", []} =
             MessageFormatter.format_top_users([
               %{first_name: "Ada", username: nil, meme_count: 2}
             ])
  end

  test "uses the singular noun for one meme" do
    assert {"Top users\n\n1. Ada @ada — 1 meme", []} =
             MessageFormatter.format_top_users([
               %{first_name: "Ada", username: "ada", meme_count: 1}
             ])
  end

  test "users without memes are excluded from the ranking" do
    insert_user!(10, "No Memes", "empty")
    ranked_user = insert_user!(20, "Ada", "ada")
    insert_memes!(ranked_user, 1)

    assert [%{telegram_id: 20, meme_count: 1}] = UserStore.top_users()
  end

  test "an admin sees the top ten users ranked by meme count" do
    users = [
      {10, "Ada", "ada", 12},
      {20, "Grace", "grace", 11},
      {30, "Lin", "lin", 10},
      {40, "Maya", "maya", 10},
      {50, "Sam", "sam", 9},
      {60, "Jo", "jo", 8},
      {70, "Kai", "kai", 7},
      {80, "Nia", "nia", 6},
      {90, "Max", "max", 5},
      {100, "Ivy", "ivy", 4},
      {110, "Bea", "bea", 3},
      {120, "Leo", "leo", 2}
    ]

    users
    |> Enum.reverse()
    |> Enum.each(fn {telegram_id, first_name, username, meme_count} ->
      user = insert_user!(telegram_id, first_name, username)
      insert_memes!(user, meme_count)
    end)

    assert %Cnt{answers: [{:response, %Answer{text: text}}]} =
             Bot.handle({:command, "top", %{from: %{id: 40}}}, %Cnt{})

    assert text =~ "Top users"

    rows =
      text
      |> String.split("\n", trim: true)
      |> Enum.filter(&Regex.match?(~r/^\d+\./, &1))

    assert length(rows) == 10

    expected_rows = Enum.take(users, 10)

    Enum.zip(rows, expected_rows)
    |> Enum.with_index(1)
    |> Enum.each(fn {{row, {_telegram_id, first_name, username, meme_count}}, rank} ->
      assert Regex.match?(
               ~r/^#{rank}\.\s+#{Regex.escape(first_name)}.*@#{Regex.escape(username)}.*#{meme_count} memes$/,
               row
             )
    end)
  end

  test "a non-admin invocation is silently ignored" do
    assert Bot.handle({:command, "top", %{from: %{id: 41}}}, %Cnt{}) in [:ignore, nil]
  end

  test "top is not registered in Telegram's public command menu" do
    public_commands =
      Bot.commands()
      |> SetupCommands.build()
      |> Enum.flat_map(fn {commands, _opts} -> Enum.map(commands, & &1.command) end)

    refute "top" in public_commands
  end

  defp insert_user!(telegram_id, first_name, username) do
    {:ok, user} =
      UserStore.insert_user(%{
        telegram_id: telegram_id,
        first_name: first_name,
        username: username
      })

    user
  end

  defp insert_memes!(user, meme_count) do
    Enum.each(1..meme_count, fn index ->
      {:ok, _meme} =
        MemeStore.insert_meme(%{
          meme_id: "file-#{user.telegram_id}-#{index}",
          meme_unique_id: "unique-#{user.telegram_id}-#{index}",
          meme_type: "photo",
          user: user
        })
    end)
  end
end
