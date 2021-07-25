defmodule MemeCacheBot.Store do
  import Ecto.Query

  def maybe_limit(query, nil), do: query
  def maybe_limit(query, limit) when is_integer(limit), do: limit(query, ^limit)

  def maybe_order_by(query, nil), do: query
  def maybe_order_by(query, order), do: order_by(query, ^order)

  def maybe_where_telegram_id(query, nil), do: query

  def maybe_where_telegram_id(query, telegram_id) when is_integer(telegram_id),
    do: where(query, telegram_id: ^telegram_id)

  def maybe_preload(query, nil), do: query
  def maybe_preload(query, preload) when is_atom(preload), do: preload(query, ^preload)
end
