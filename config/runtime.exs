import Config

if config_env() == :prod do
  config :meme_cache_bot, MemeCacheBot.Repo,
    database: System.fetch_env!("DATABASE_PATH"),
    pool_size: 1,
    busy_timeout: 5_000,
    journal_mode: :wal,
    foreign_keys: :on

  config :logger, level: :info
end
