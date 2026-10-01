defmodule MemeCacheBot do
  @moduledoc false

  alias MemeCacheBot.MessageFormatter
  alias MemeCacheBot.Model.Meme
  alias MemeCacheBot.Steps
  alias MemeCacheBot.Store.{MemeStore, UserStore}
  alias MemeCacheBot.TagEditSessions
  alias MemeCacheBot.Tags

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

  def process_pending_tag_message(%{from: %{id: telegram_id}, text: text} = message)
      when is_binary(text) and text != "" do
    case TagEditSessions.get(telegram_id) do
      :none ->
        :not_pending

      {:ok, %{meme_id: meme_id, token: token}} ->
        process_tag_text(message, telegram_id, meme_id, token, text)
    end
  end

  def process_pending_tag_message(%{from: %{id: telegram_id}} = message) do
    case TagEditSessions.get(telegram_id) do
      :none -> :not_pending
      {:ok, _session} -> MessageFormatter.tags_require_text(message)
    end
  end

  def apply_meme_action(uuid, from, message) do
    case Steps.take_step(uuid, from.id) do
      {:ok, meme, :add} ->
        save_meme(meme, from, message)

      {:ok, meme, :delete} ->
        meme
        |> MemeStore.delete_meme()
        |> create_delete_message_from_result(message)

      {:ok, meme, :edit_tags} ->
        open_tag_edit(meme, from, message)

      {:ok, %{token: token}, :cancel_tags} ->
        case TagEditSessions.cancel(from.id, token) do
          {:ok, _session} -> MessageFormatter.tag_edit_canceled()
          {:error, :stale} -> MessageFormatter.tag_edit_expired()
        end

      error ->
        Logger.error("Tried to get step for UUID #{inspect(uuid)}. Got: #{inspect(error)}")
        MessageFormatter.unknown_error()
    end
  end

  def get_meme_articles(text, %{id: telegram_id}) do
    query = String.trim(text)

    opts = inline_query_options(query, telegram_id)

    opts
    |> MemeStore.find_memes()
    |> MessageFormatter.get_inline_articles()
  end

  def update_last_used(%{from: %{id: telegram_id}, result_id: meme_unique_id}) do
    case MemeStore.find_meme(meme_unique_id: meme_unique_id, telegram_id: telegram_id) do
      nil ->
        Logger.error(
          "Could not find meme #{inspect(meme_unique_id)} to update last used for user #{inspect(telegram_id)}"
        )

        :error

      meme ->
        now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        MemeStore.update_meme(meme, %{last_used: now})
        :ok
    end
  end

  def get_stats do
    meme_count = MemeStore.count_memes()
    user_count = UserStore.count_users()
    meme_master = UserStore.get_meme_master()

    MessageFormatter.format_stats(meme_count, user_count, meme_master)
  end

  def get_top_users do
    UserStore.top_users()
    |> MessageFormatter.format_top_users()
  end

  # Private
  defp inline_query_options("", telegram_id), do: [telegram_id: telegram_id, page: 1]

  defp inline_query_options(query, telegram_id) do
    case Integer.parse(query) do
      {page, ""} when page in 1..1_000_000 -> [telegram_id: telegram_id, page: page]
      _other -> [telegram_id: telegram_id, tags: Tags.parse_query(query), page: 1]
    end
  end

  defp process_tag_text(message, telegram_id, meme_id, token, text) do
    case Tags.parse(text) do
      {:ok, tags} -> replace_pending_tags(message, telegram_id, meme_id, token, tags)
      {:error, _reason} = error -> MessageFormatter.tag_validation_error(message, error)
    end
  end

  defp replace_pending_tags(message, telegram_id, meme_id, token, tags) do
    case MemeStore.find_meme(id: meme_id, telegram_id: telegram_id) do
      nil ->
        close_unavailable_session(message, telegram_id, token)

      meme ->
        case TagEditSessions.claim(telegram_id, token) do
          {:ok, _session} ->
            meme
            |> MemeStore.replace_tags(tags)
            |> format_tag_replacement(message, tags)

          {:error, :stale} ->
            MessageFormatter.tag_edit_expired()
        end
    end
  end

  defp close_unavailable_session(message, telegram_id, token) do
    case TagEditSessions.cancel(telegram_id, token) do
      {:ok, _session} -> MessageFormatter.tag_edit_unavailable(message)
      {:error, :stale} -> MessageFormatter.tag_edit_expired()
    end
  end

  defp format_tag_replacement({:ok, tags}, message, tags),
    do: MessageFormatter.tags_saved(message, tags)

  defp format_tag_replacement({:error, error}, message, _tags) do
    Logger.error("Could not replace meme tags: #{inspect(error)}")
    MessageFormatter.can_not_save_tags(message)
  end

  defp save_meme(meme, %{id: telegram_id}, message) do
    case UserStore.find_user(telegram_id: telegram_id) do
      nil ->
        MessageFormatter.can_not_save_meme(message)

      user ->
        meme
        |> Map.from_struct()
        |> Map.put(:user, user)
        |> MemeStore.insert_meme()
        |> create_add_message_from_result(message, telegram_id)
    end
  end

  defp create_add_message_from_result({:ok, meme}, message, telegram_id) do
    edit_uuid = Steps.add_step(meme, :edit_tags, telegram_id)
    MessageFormatter.meme_saved(message, edit_uuid)
  end

  defp create_add_message_from_result({:error, _}, message, _telegram_id),
    do: MessageFormatter.meme_already_saved(message)

  defp create_delete_message_from_result({:ok, _}, message),
    do: MessageFormatter.meme_deleted(message)

  defp create_delete_message_from_result({:error, _}, message),
    do: MessageFormatter.can_not_delete_meme(message)

  defp open_tag_edit(%{meme_unique_id: meme_unique_id}, %{id: telegram_id}, message) do
    case MemeStore.find_meme(telegram_id: telegram_id, meme_unique_id: meme_unique_id) do
      nil ->
        MessageFormatter.unknown_error()

      meme ->
        tags = MemeStore.list_tags(meme)

        {:ok, token} =
          TagEditSessions.start(telegram_id, %{
            meme_id: meme.id,
            prompt_message_id: message.message_id
          })

        cancel_uuid = Steps.add_step(%{token: token}, :cancel_tags, telegram_id)

        MessageFormatter.tag_edit_prompt(tags, cancel_uuid)
    end
  end

  defp add_step(
         %Meme{meme_unique_id: meme_unique_id} = meme,
         %{from: %{id: telegram_id}} = message
       ) do
    case MemeStore.find_meme(telegram_id: telegram_id, meme_unique_id: meme_unique_id) do
      nil ->
        uuid = Steps.add_step(meme, :add, telegram_id)
        MessageFormatter.add_meme_message(message, uuid)

      meme ->
        delete_uuid = Steps.add_step(meme, :delete, telegram_id)
        edit_uuid = Steps.add_step(meme, :edit_tags, telegram_id)
        tags = MemeStore.list_tags(meme)
        MessageFormatter.existing_meme_message(message, tags, delete_uuid, edit_uuid)
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
