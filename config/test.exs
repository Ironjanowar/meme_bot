import Config

config :meme_cache_bot, MemeCacheBot.Repo,
  database: Path.expand("../meme_cache_bot_test.db", __DIR__),
  pool: Ecto.Adapters.SQL.Sandbox

config :meme_cache_bot, start_bot: false
config :logger, level: :warning
