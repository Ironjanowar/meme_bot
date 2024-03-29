defmodule MemeCacheBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :meme_cache_bot,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
  defp deps do
    [
      {:ex_gram, "~> 0.23"},
      {:tesla, "~> 1.8"},
      {:hackney, "~> 1.20"},
      {:jason, "~> 1.4"},
      {:logger_file_backend, "0.0.11"},
      {:ecto_sql, "~> 3.11"},
      {:postgrex, "~> 0.17"},
      {:credo, "~> 1.2", only: [:dev, :test], runtime: false},
      {:uuid, "~> 1.1"}
    ]
  end
end
