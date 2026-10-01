ExUnit.start()

if Process.whereis(MemeCacheBot.Repo) do
  Ecto.Adapters.SQL.Sandbox.mode(MemeCacheBot.Repo, :manual)
end
