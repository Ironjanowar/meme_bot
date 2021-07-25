defmodule MemeCacheBot.MessageFormatter do
  alias MemeCacheBot.Utils
  alias MemeCacheBot.Model.Meme

  alias ExGram.Model.{
    InlineQueryResultCachedGif,
    InlineQueryResultCachedPhoto,
    InlineQueryResultCachedSticker,
    InlineQueryResultCachedVideo,
    InlineQueryResultCachedVoice
  }

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
    {text, reply_to_message_id: message_id}
  end

  def unknown_error() do
    text = "Sorry there was an unexpected error :("
    {text, []}
  end

  def get_inline_articles(memes) do
    articles = memes |> Enum.map(&get_inline_article/1) |> Enum.reject(&is_nil/1)
    {articles, [is_personal: true, cache_time: 0]}
  end

  def format_stats(meme_count, user_count, meme_master) do
    text = """
    Total users: **#{user_count}**
    Total memes: **#{meme_count}**

    #{format_meme_master(meme_master)}
    """

    {text, parse_mode: "Markdown"}
  end

  # Private
  defp format_meme_master(nil), do: "No meme master :("
  defp format_meme_master(meme_master), do: "Da Meme Master: @#{meme_master.username}"

  defp type_struct("gif"), do: {:ok, InlineQueryResultCachedGif, :gif_file_id, %{}}
  defp type_struct("photo"), do: {:ok, InlineQueryResultCachedPhoto, :photo_file_id, %{}}
  defp type_struct("sticker"), do: {:ok, InlineQueryResultCachedSticker, :sticker_file_id, %{}}

  defp type_struct("voice"),
    do: {:ok, InlineQueryResultCachedVoice, :voice_file_id, %{title: "Voice Message Meme"}}

  defp type_struct("video"),
    do: {:ok, InlineQueryResultCachedVideo, :video_file_id, %{title: "Meme"}}

  defp type_struct(invalid_type), do: {:error, :invalid_type, invalid_type}

  defp get_inline_article(%Meme{} = meme) do
    case type_struct(meme.meme_type) do
      {:ok, struct_module, file_param, extras} ->
        params =
          %{type: meme.meme_type, id: meme.meme_unique_id}
          |> Map.put(file_param, meme.meme_id)
          |> Map.merge(extras)

        struct(struct_module, params)

      _ ->
        nil
    end
  end

  defp get_inline_article(_), do: nil

  defp meme_message(text, %{message_id: message_id}, uuid) do
    keyboard = Utils.generate_buttons(uuid)
    {text, [reply_markup: keyboard, reply_to_message_id: message_id]}
  end
end
