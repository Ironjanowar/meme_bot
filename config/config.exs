import Config

config :meme_cache_bot, MemeCacheBot.Repo,
  database: Path.expand("../meme_cache_bot.db", __DIR__),
  pool_size: 1,
  busy_timeout: 5_000,
  journal_mode: :wal,
  foreign_keys: :on

config :meme_cache_bot,
  ecto_repos: [MemeCacheBot.Repo],
  admins: {:system, "ADMINS"},
  start_bot: true

config :ex_gram,
  token: {:system, "BOT_TOKEN"},
  adapter: ExGram.Adapter.Req

config :logger,
  level: :debug,
  truncate: :infinity

import_config "#{config_env()}.exs"
