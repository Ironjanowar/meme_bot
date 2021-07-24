defmodule MemeCacheBot.Store do
  import Ecto.Query

  def maybe_limit(query, nil), do: query
  def maybe_limit(query, limit) when is_integer(limit), do: limit(query, ^limit)
end
