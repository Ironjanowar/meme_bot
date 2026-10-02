defmodule MemeCacheBot.FlowTest do
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias MemeCacheBot.Repo
  alias MemeCacheBot.{Steps, TagEditSessions}
  alias MemeCacheBot.Store.{MemeStore, UserStore}

  setup do
    :ok = Sandbox.checkout(Repo)
    :sys.replace_state(Steps, fn _ -> %{first_gen: %{}, second_gen: %{}} end)
    :sys.replace_state(TagEditSessions, fn state -> %{state | sessions: %{}} end)
    :ok
  end

  test "saving a new meme offers tag editing and opens an owned edit session" do
    {:ok, _user} = UserStore.insert_user(%{telegram_id: 101, first_name: "Ada"})
    from = %{id: 101}
    message = meme_message(from, "new-meme")

    assert {"Do you want to save this meme?", save_opts} = MemeCacheBot.process_message(message)
    [[%{callback_data: save_uuid}]] = save_opts[:reply_markup].inline_keyboard

    assert {"Meme saved!", saved_opts} =
             MemeCacheBot.apply_meme_action(save_uuid, from, message)

    assert [[%{text: "Edit tags", callback_data: edit_uuid}]] =
             saved_opts[:reply_markup].inline_keyboard

    assert {prompt, prompt_opts} = MemeCacheBot.apply_meme_action(edit_uuid, from, message)
    assert prompt =~ "Current tags: none"
    assert [[%{text: "Cancel"}]] = prompt_opts[:reply_markup].inline_keyboard
    assert {:ok, %{telegram_id: 101}} = TagEditSessions.get(101)
  end

  test "resending a saved meme shows its tags and separate owned actions" do
    {:ok, user} = UserStore.insert_user(%{telegram_id: 102, first_name: "Grace"})
    from = %{id: 102}
    message = meme_message(from, "saved-meme")

    {:ok, meme} =
      MemeStore.insert_meme(%{
        meme_id: "file-saved-meme",
        meme_unique_id: "saved-meme",
        meme_type: "photo",
        user: user
      })

    MemeStore.replace_tags(meme, ["feliz", "gato"])

    assert {text, opts} = MemeCacheBot.process_message(message)
    assert text =~ "Current tags: feliz, gato"
    assert [[%{text: "Delete"}, %{text: "Edit tags"}]] = opts[:reply_markup].inline_keyboard
  end

  test "valid pending text replaces tags and consumes the session" do
    {:ok, user} = UserStore.insert_user(%{telegram_id: 103, first_name: "Lin"})
    meme = insert_meme!(user, "taggable")
    MemeStore.replace_tags(meme, ["anterior"])
    TagEditSessions.start(103, %{meme_id: meme.id})

    assert {text, _opts} =
             MemeCacheBot.process_pending_tag_message(%{
               from: %{id: 103},
               message_id: 43,
               text: "Gato, FELIZ, gato"
             })

    assert text == "Tags saved: gato, feliz"
    assert MemeStore.list_tags(meme) == ["feliz", "gato"]
    assert :none = TagEditSessions.get(103)
  end

  test "invalid pending text leaves tags and the session unchanged" do
    {:ok, user} = UserStore.insert_user(%{telegram_id: 104, first_name: "Sam"})
    meme = insert_meme!(user, "invalid-tags")
    MemeStore.replace_tags(meme, ["anterior"])
    TagEditSessions.start(104, %{meme_id: meme.id})

    assert {text, _opts} =
             MemeCacheBot.process_pending_tag_message(%{
               from: %{id: 104},
               message_id: 44,
               text: ", ,"
             })

    assert text =~ "Invalid tags"
    assert MemeStore.list_tags(meme) == ["anterior"]
    assert {:ok, _session} = TagEditSessions.get(104)
  end

  test "non-text Telegram messages explain the requirement and preserve the session" do
    TagEditSessions.start(105, %{meme_id: "meme-id"})

    message = %ExGram.Model.Message{
      from: %ExGram.Model.User{id: 105, first_name: "User"},
      message_id: 45,
      sticker: %ExGram.Model.Sticker{file_id: "sticker", file_unique_id: "unique"}
    }

    assert {text, _opts} = MemeCacheBot.process_pending_tag_message(message)
    assert text =~ "text message"
    assert {:ok, _session} = TagEditSessions.get(105)
  end

  test "routes ExGram text updates into a pending tag edit" do
    {:ok, user} = UserStore.insert_user(%{telegram_id: 114, first_name: "Maya"})
    meme = insert_meme!(user, "text-update")
    TagEditSessions.start(114, %{meme_id: meme.id})

    message = %ExGram.Model.Message{
      from: %ExGram.Model.User{id: 114, first_name: "Maya"},
      message_id: 47,
      text: "maia, hmm"
    }

    assert %ExGram.Cnt{} =
             MemeCacheBot.Bot.handle({:text, "maia, hmm", message}, %ExGram.Cnt{})

    assert MemeStore.list_tags(meme) == ["hmm", "maia"]
    assert :none = TagEditSessions.get(114)
  end

  test "a pending edit for a deleted meme is closed as unavailable" do
    assert {:ok, _token} = TagEditSessions.start(112, %{meme_id: Ecto.UUID.generate()})

    assert {text, _opts} =
             MemeCacheBot.process_pending_tag_message(%{
               from: %{id: 112},
               message_id: 46,
               text: "gato"
             })

    assert text =~ "no longer available"
    assert :none = TagEditSessions.get(112)
  end

  test "canceling an edit preserves existing tags and closes the session" do
    {:ok, user} = UserStore.insert_user(%{telegram_id: 106, first_name: "Jo"})
    from = %{id: 106}
    message = meme_message(from, "cancel-edit")
    meme = insert_meme!(user, "cancel-edit")
    MemeStore.replace_tags(meme, ["original"])

    {_text, existing_opts} = MemeCacheBot.process_message(message)
    [[_delete_button, %{callback_data: edit_uuid}]] = existing_opts[:reply_markup].inline_keyboard
    {_prompt, prompt_opts} = MemeCacheBot.apply_meme_action(edit_uuid, from, message)
    [[%{callback_data: cancel_uuid}]] = prompt_opts[:reply_markup].inline_keyboard

    assert {"Tag editing canceled. No changes were made.", _opts} =
             MemeCacheBot.apply_meme_action(cancel_uuid, from, message)

    assert MemeStore.list_tags(meme) == ["original"]
    assert :none = TagEditSessions.get(106)
  end

  test "a stale cancel button cannot cancel a newer edit" do
    {:ok, user} = UserStore.insert_user(%{telegram_id: 111, first_name: "Jo"})
    from = %{id: 111}
    old_meme = insert_meme!(user, "old-edit")
    new_meme = insert_meme!(user, "new-edit")

    {_text, old_opts} = MemeCacheBot.process_message(meme_message(from, "old-edit"))
    [[_delete, %{callback_data: old_edit_uuid}]] = old_opts[:reply_markup].inline_keyboard

    {_prompt, old_prompt_opts} =
      MemeCacheBot.apply_meme_action(old_edit_uuid, from, meme_message(from, "old-edit"))

    [[%{callback_data: old_cancel_uuid}]] = old_prompt_opts[:reply_markup].inline_keyboard

    {_text, new_opts} = MemeCacheBot.process_message(meme_message(from, "new-edit"))
    [[_delete, %{callback_data: new_edit_uuid}]] = new_opts[:reply_markup].inline_keyboard
    MemeCacheBot.apply_meme_action(new_edit_uuid, from, meme_message(from, "new-edit"))

    assert {text, _opts} =
             MemeCacheBot.apply_meme_action(old_cancel_uuid, from, meme_message(from, "old-edit"))

    assert text =~ "no longer active"
    assert {:ok, %{meme_id: new_meme_id}} = TagEditSessions.get(111)
    assert new_meme_id == new_meme.id
    refute new_meme_id == old_meme.id
  end

  test "inline tag search returns only the user's OR matches" do
    {:ok, user} = UserStore.insert_user(%{telegram_id: 107, first_name: "Kai"})
    cat = insert_meme!(user, "inline-cat")
    happy = insert_meme!(user, "inline-happy")
    _unrelated = insert_meme!(user, "inline-other")
    other = 108 |> insert_user!() |> insert_meme!("foreign-cat")
    MemeStore.replace_tags(cat, ["gato"])
    MemeStore.replace_tags(happy, ["feliz"])
    MemeStore.replace_tags(other, ["gato"])

    {articles, opts} = MemeCacheBot.get_meme_articles("GATO feliz", %{id: 107})

    assert articles |> Enum.map(& &1.id) |> Enum.sort() == ["inline-cat", "inline-happy"]
    assert opts[:is_personal]
  end

  test "inline tag search matches case-insensitive substrings at any position" do
    user = insert_user!(115)
    courage = insert_meme!(user, "inline-courage")
    MemeStore.replace_tags(courage, ["coraje"])

    {prefix_articles, _opts} = MemeCacheBot.get_meme_articles("CORA", %{id: 115})
    {interior_articles, _opts} = MemeCacheBot.get_meme_articles("RAJ", %{id: 115})

    assert {
             Enum.map(prefix_articles, & &1.id),
             Enum.map(interior_articles, & &1.id)
           } == {["inline-courage"], ["inline-courage"]}
  end

  test "one-character partial terms keep OR matching within the requesting user" do
    user = insert_user!(116)
    courage = insert_meme!(user, "one-char-courage")
    happy = insert_meme!(user, "one-char-happy")
    foreign = 117 |> insert_user!() |> insert_meme!("one-char-foreign")
    MemeStore.replace_tags(courage, ["coraje"])
    MemeStore.replace_tags(happy, ["feliz"])
    MemeStore.replace_tags(foreign, ["cielo"])

    {articles, _opts} = MemeCacheBot.get_meme_articles("c z", %{id: 116})

    assert articles |> Enum.map(& &1.id) |> Enum.sort() == ["one-char-courage", "one-char-happy"]
  end

  test "SQL wildcard characters in partial tag searches are literal" do
    user = insert_user!(118)
    percent = insert_meme!(user, "literal-percent")
    underscore = insert_meme!(user, "literal-underscore")
    unrelated = insert_meme!(user, "literal-unrelated")
    MemeStore.replace_tags(percent, ["100%real"])
    MemeStore.replace_tags(underscore, ["under_score"])
    MemeStore.replace_tags(unrelated, ["ordinary"])

    {percent_articles, _opts} = MemeCacheBot.get_meme_articles("%", %{id: 118})
    {underscore_articles, _opts} = MemeCacheBot.get_meme_articles("_", %{id: 118})

    assert {
             Enum.map(percent_articles, & &1.id),
             Enum.map(underscore_articles, & &1.id)
           } == {["literal-percent"], ["literal-underscore"]}
  end

  test "partial tag search returns at most 50 results" do
    user = insert_user!(119)

    for index <- 1..51 do
      meme = insert_meme!(user, "partial-limit-#{index}")
      MemeStore.replace_tags(meme, ["coraje-#{index}"])
    end

    {articles, _opts} = MemeCacheBot.get_meme_articles("cora", %{id: 119})

    assert length(articles) == 50
  end

  test "empty and positive numeric inline queries preserve recent pagination" do
    user = insert_user!(109)
    base = ~N[2026-01-01 00:00:00]

    memes =
      for index <- 1..51 do
        meme = insert_meme!(user, "page-#{index}")
        {:ok, meme} = MemeStore.update_meme(meme, %{last_used: NaiveDateTime.add(base, index)})
        meme
      end

    {empty_articles, _opts} = MemeCacheBot.get_meme_articles("", %{id: 109})
    {first_articles, _opts} = MemeCacheBot.get_meme_articles("1", %{id: 109})
    {second_articles, _opts} = MemeCacheBot.get_meme_articles("2", %{id: 109})

    assert Enum.map(empty_articles, & &1.id) == Enum.map(first_articles, & &1.id)
    assert length(empty_articles) == 50
    assert Enum.map(second_articles, & &1.id) == [hd(memes).meme_unique_id]
  end

  test "oversized numeric inline queries return no results without building an invalid offset" do
    user = insert_user!(113)
    _meme = insert_meme!(user, "numeric-query")

    assert {[], _opts} = MemeCacheBot.get_meme_articles(String.duplicate("9", 100), %{id: 113})
  end

  test "an inline query with no valid tag tokens returns no unrelated memes" do
    user = insert_user!(110)
    _meme = insert_meme!(user, "not-related")

    assert {[], _opts} = MemeCacheBot.get_meme_articles("0, 123", %{id: 110})
  end

  defp insert_user!(telegram_id) do
    {:ok, user} = UserStore.insert_user(%{telegram_id: telegram_id, first_name: "User"})
    user
  end

  defp insert_meme!(user, unique_id) do
    {:ok, meme} =
      MemeStore.insert_meme(%{
        meme_id: "file-#{unique_id}",
        meme_unique_id: unique_id,
        meme_type: "photo",
        user: user
      })

    meme
  end

  defp meme_message(from, unique_id) do
    %{
      message_id: 42,
      from: from,
      photo: [%{file_id: "file-#{unique_id}", file_unique_id: unique_id}]
    }
  end
end
