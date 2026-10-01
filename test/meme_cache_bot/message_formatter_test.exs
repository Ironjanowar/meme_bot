defmodule MemeCacheBot.MessageFormatterTest do
  use ExUnit.Case, async: true

  alias ExGram.Model.ReplyParameters
  alias MemeCacheBot.{MessageFormatter, Utils}

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

  test "builds an explicit Save button" do
    keyboard = Utils.save_keyboard("save-step")

    assert [[%{text: "Save", callback_data: "save-step"}]] = keyboard.inline_keyboard
  end

  test "shows existing tags with separate Delete and Edit tags actions" do
    assert {text, opts} =
             MessageFormatter.existing_meme_message(
               %{message_id: 42},
               ["feliz", "gato"],
               "delete-step",
               "edit-step"
             )

    assert text =~ "Current tags: feliz, gato"

    assert [[delete_button, edit_button]] = opts[:reply_markup].inline_keyboard
    assert %{text: "Delete", callback_data: "delete-step"} = delete_button
    assert %{text: "Edit tags", callback_data: "edit-step"} = edit_button
  end

  test "prompts for tags with current values and a Cancel action" do
    assert {text, opts} = MessageFormatter.tag_edit_prompt([], "cancel-step")
    assert text =~ "Current tags: none"
    assert text =~ "one-word tags separated by commas"

    assert [[%{text: "Cancel", callback_data: "cancel-step"}]] =
             opts[:reply_markup].inline_keyboard
  end

  test "help explains personal tag editing and inline OR search" do
    assert {text, []} = MessageFormatter.help_command()
    assert text =~ "Edit tags"
    assert text =~ "matches any tag"
  end
end
