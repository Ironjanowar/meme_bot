defmodule MemeCacheBot.Repo do
  use Ecto.Repo,
    otp_app: :meme_cache_bot,
    adapter: Ecto.Adapters.SQLite3
end
