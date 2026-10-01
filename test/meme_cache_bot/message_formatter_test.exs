defmodule MemeCacheBot.MessageFormatterTest do
  use ExUnit.Case, async: true

  alias ExGram.Model.ReplyParameters
  alias MemeCacheBot.MessageFormatter

  test "uses Telegram reply parameters for response messages" do
    assert {"Meme saved!", opts} = MessageFormatter.meme_saved(%{message_id: 42})
    assert %ReplyParameters{message_id: 42} = opts[:reply_parameters]
    refute Keyword.has_key?(opts, :reply_to_message_id)
  end

  test "uses Telegram reply parameters alongside callback buttons" do
    assert {_text, opts} = MessageFormatter.add_meme_message(%{message_id: 42}, "step-id")
    assert %ReplyParameters{message_id: 42} = opts[:reply_parameters]
    assert opts[:reply_markup]
  end
end
