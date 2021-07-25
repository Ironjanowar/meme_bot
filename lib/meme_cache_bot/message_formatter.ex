defmodule MemeCacheBot.MessageFormatter do
  alias MemeCacheBot.Utils

  def help_command do
    text = """
    Send me a meme in any of these formats:
     - Sticker
     - GIF
     - Photo
     - Video

    If you don't have it, I'll ask if you want to save it!

    If you already have that meme, I'll ask if you want to delete it.
    """

    {text, []}
  end

  def about_command do
    text = """
    __This bot was made by [@Ironjanowar](https://github.com/Ironjanowar) with ❤️__

    If you want to share some love and give a star ⭐️ to the repo [here it is](https://github.com/Ironjanowar/meme_bot)
    """

    {text, parse_mode: "Markdown"}
  end

  def format_count_message(count) do
    text = "You have saved *#{count}* memes in total!"
    {text, parse_mode: "Markdown"}
  end

  def add_meme_message(message, uuid) do
    text = "Do you want to save this meme?"
    meme_message(text, message, uuid)
  end

  def delete_meme_message(message, uuid) do
    text = "You already have that meme saved, do you want to delete it?"
    meme_message(text, message, uuid)
  end

  def meme_saved(%{message_id: message_id}) do
    text = "Meme saved!"
    {text, reply_to_message_id: message_id}
  end

  def meme_already_saved(%{message_id: message_id}) do
    text = "That meme was already saved!"
    {text, reply_to_message_id: message_id}
  end

  def can_not_save_meme(%{message_id: message_id}) do
    text = "Sorry I could not save your meme :("
    {text, reply_to_message_id: message_id}
  end

  def meme_deleted(%{message_id: message_id}) do
    text = "Meme deleted!"
    {text, reply_to_message_id: message_id}
  end

  def can_not_delete_meme(%{message_id: message_id}) do
    text = "Sorry I could not delete your meme :("
    {text, reply_to_message_id: message_id}
  end

  def unrecognized_meme_format(%{message_id: message_id}) do
    text = "Sorry I don't recognize that as a meme :("
    {text, [reply_to_message_id: message_id]}
  end

  def unknown_error() do
    text = "Sorry there was an unexpected error :("
    {text, []}
  end

  # Private
  defp meme_message(text, %{message_id: message_id}, uuid) do
    keyboard = Utils.generate_buttons(uuid)
    {text, [reply_markup: keyboard, reply_to_message_id: message_id]}
  end
end
