defmodule MemeCacheBot.MessageFormatter do
  def format_count_message(count) do
    """
    You have saved *#{count}* memes in total!
    """
  end
end
