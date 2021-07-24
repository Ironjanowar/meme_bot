defmodule MemeCacheBot do
  alias MemeCacheBot.Store.MemeStore
  alias MemeCacheBot.MessageFormatter

  def count_memes(telegram_id) do
    MemeStore.count_memes(telegram_id: telegram_id)
    |> MessageFormatter.format_count_message()
  end
end
