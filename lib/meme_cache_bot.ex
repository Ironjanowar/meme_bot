defmodule MemeCacheBot do
  alias MemeCacheBot.Store.{MemeStore, UserStore}
  alias MemeCacheBot.MessageFormatter
  alias MemeCacheBot.Model.Meme
  alias MemeCacheBot.Steps

  require Logger

  def count_memes(telegram_id) do
    MemeStore.count_memes(telegram_id: telegram_id)
    |> MessageFormatter.format_count_message()
  end

  def process_message(message) do
    case get_meme_from_message(message) do
      {:ok, meme_params} -> meme_params |> Meme.build() |> add_step(message)
      {:error, :no_meme, message} -> MessageFormatter.unrecognized_meme_format(message)
    end
  end

  def apply_meme_action(uuid, from, message) do
    case Steps.get_step(uuid) do
      {:ok, meme, :add} ->
        save_meme(meme, from, message)

      {:ok, meme, :delete} ->
        meme
        |> MemeStore.delete_meme()
        |> create_delete_message_from_result(message)

      error ->
        Logger.error("Tried to get step for UUID #{inspect(uuid)}. Got: #{inspect(error)}")
        MessageFormatter.unknown_error()
    end
  end

  # Private
  defp save_meme(meme, %{id: telegram_id}, message) do
    case UserStore.find_user(telegram_id: telegram_id) do
      nil ->
        MessageFormatter.can_not_save_meme(message)

      user ->
        meme
        |> Map.from_struct()
        |> Map.put(:user, user)
        |> MemeStore.insert_meme()
        |> create_add_message_from_result(message)
    end
  end

  defp create_add_message_from_result({:ok, _}, message), do: MessageFormatter.meme_saved(message)

  defp create_add_message_from_result({:error, _}, message),
    do: MessageFormatter.meme_already_saved(message)

  defp create_delete_message_from_result({:ok, _}, message),
    do: MessageFormatter.meme_deleted(message)

  defp create_delete_message_from_result({:error, _}, message),
    do: MessageFormatter.can_not_delete_meme(message)

  defp add_step(
         %Meme{meme_unique_id: meme_unique_id} = meme,
         %{from: %{id: telegram_id}} = message
       ) do
    case MemeStore.find_meme(telegram_id: telegram_id, meme_unique_id: meme_unique_id) do
      nil ->
        uuid = Steps.add_step(meme, :add)
        MessageFormatter.add_meme_message(message, uuid)

      meme ->
        uuid = Steps.add_step(meme, :delete)
        MessageFormatter.delete_meme_message(message, uuid)
    end
  end

  defp add_step(unrecognized, message) do
    Logger.debug("Unrecognized meme: #{inspect(unrecognized)}")
    MessageFormatter.unrecognized_meme_format(message)
  end

  defp get_meme_from_message(%{animation: %{file_id: meme_id, file_unique_id: meme_unique_id}}),
    do: {:ok, %{meme_id: meme_id, meme_unique_id: meme_unique_id, meme_type: "gif"}}

  defp get_meme_from_message(%{photo: [%{file_id: meme_id, file_unique_id: meme_unique_id} | _]}),
    do: {:ok, %{meme_id: meme_id, meme_unique_id: meme_unique_id, meme_type: "photo"}}

  defp get_meme_from_message(%{sticker: %{file_unique_id: meme_unique_id, file_id: meme_id}}),
    do: {:ok, %{meme_id: meme_id, meme_unique_id: meme_unique_id, meme_type: "sticker"}}

  defp get_meme_from_message(%{video: %{file_unique_id: meme_unique_id, file_id: meme_id}}),
    do: {:ok, %{meme_id: meme_id, meme_unique_id: meme_unique_id, meme_type: "video"}}

  defp get_meme_from_message(%{voice: %{file_unique_id: meme_unique_id, file_id: meme_id}}),
    do: {:ok, %{meme_id: meme_id, meme_unique_id: meme_unique_id, meme_type: "voice"}}

  defp get_meme_from_message(message), do: {:error, :no_meme, message}
end
