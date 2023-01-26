defmodule MemeCacheBot.Middlewares.RegisterUser do
  use ExGram.Middleware

  alias ExGram.Cnt
  alias MemeCacheBot.Store.UserStore

  import ExGram.Dsl

  def call(%Cnt{update: update} = cnt, _opts) do
    with {:ok, %{id: telegram_id} = user} <- extract_user(update) do
      maybe_register_user(telegram_id, user)
    end

    cnt
  end

  def call(cnt, _), do: cnt

  defp maybe_register_user(telegram_id, user) do
    if UserStore.find_user(telegram_id: telegram_id) == nil do
      user
      |> Map.put(:telegram_id, telegram_id)
      |> UserStore.insert_user()
    end
  end
end
