defmodule MemeCacheBot.TagEditSessionsTest do
  use ExUnit.Case, async: false

  alias MemeCacheBot.TagEditSessions

  setup do
    :sys.replace_state(TagEditSessions, fn state ->
      %{state | sessions: %{}, timeout: 50}
    end)

    on_exit(fn ->
      if Process.whereis(TagEditSessions) do
        :sys.replace_state(TagEditSessions, fn state ->
          %{state | sessions: %{}, timeout: 60 * 60 * 1000}
        end)
      end
    end)

    :ok
  end

  test "starts a pending edit for a user" do
    assert {:ok, token} =
             TagEditSessions.start(101, %{meme_id: "meme-1", prompt_message_id: 42})

    assert {:ok, %{meme_id: "meme-1", prompt_message_id: 42, telegram_id: 101, token: ^token}} =
             TagEditSessions.get(101)

    assert :none = TagEditSessions.get(202)
  end

  test "cancels the requesting user's pending edit" do
    {:ok, token} = TagEditSessions.start(101, %{meme_id: "meme-1"})

    assert {:ok, %{meme_id: "meme-1"}} = TagEditSessions.cancel(101, token)
    assert :none = TagEditSessions.get(101)
  end

  test "expires abandoned sessions" do
    TagEditSessions.start(101, %{meme_id: "meme-1"})
    Process.sleep(60)
    force_cleanup()

    assert :none = TagEditSessions.get(101)
  end

  test "does not expire a session before its full timeout" do
    Process.sleep(30)
    TagEditSessions.start(101, %{meme_id: "fresh"})
    Process.sleep(30)
    force_cleanup()

    assert {:ok, %{meme_id: "fresh"}} = TagEditSessions.get(101)
  end

  test "a newer edit replaces the user's previous session" do
    TagEditSessions.start(101, %{meme_id: "old"})
    TagEditSessions.start(101, %{meme_id: "new"})

    assert {:ok, %{meme_id: "new"}} = TagEditSessions.get(101)
  end

  test "a stale token cannot cancel a newer edit" do
    assert {:ok, old_token} = TagEditSessions.start(101, %{meme_id: "old"})
    assert {:ok, new_token} = TagEditSessions.start(101, %{meme_id: "new"})

    assert {:error, :stale} = TagEditSessions.cancel(101, old_token)
    assert {:ok, %{meme_id: "new", token: ^new_token}} = TagEditSessions.get(101)
    assert {:ok, %{meme_id: "new"}} = TagEditSessions.cancel(101, new_token)
    assert :none = TagEditSessions.get(101)
  end

  test "claiming is conditional on the current session token" do
    assert {:ok, old_token} = TagEditSessions.start(101, %{meme_id: "old"})
    assert {:ok, new_token} = TagEditSessions.start(101, %{meme_id: "new"})

    assert {:error, :stale} = TagEditSessions.claim(101, old_token)
    assert {:ok, %{meme_id: "new"}} = TagEditSessions.get(101)

    assert {:ok, %{meme_id: "new"}} = TagEditSessions.claim(101, new_token)
    assert :none = TagEditSessions.get(101)
  end

  defp force_cleanup do
    send(Process.whereis(TagEditSessions), :cleanup)
    :sys.get_state(TagEditSessions)
  end
end
