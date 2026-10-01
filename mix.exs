defmodule MemeCacheBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :meme_cache_bot,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MemeCacheBot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp aliases do
    ["ecto.reset": ["ecto.drop", "ecto.create", "ecto.migrate"]]
  end

  defp deps do
    [
      {:ex_gram, "~> 0.70.1"},
      {:req, "~> 0.7.4"},
      {:jason, "~> 1.4"},
      {:ecto_sql, "~> 3.14"},
      {:ecto_sqlite3, "~> 0.25.0"},
      {:credo, "~> 1.7.19", only: [:dev, :test], runtime: false},
      {:uuid, "~> 1.1"}
    ]
  end
end
