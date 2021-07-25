defmodule MemeCacheBot.Utils do
  import ExGram.Dsl.Keyboard

  require Logger

  def generate_buttons(uuid) do
    keyboard :inline do
      row do
        button("Yes", callback_data: "#{uuid}")
      end
    end
  end

  def get_page_from_text(text) do
    case Integer.parse(text) do
      {page, _} -> page
      _ -> 0
    end
  end

  def is_admin(user_id) do
    case ExGram.Config.get(:meme_cache_bot, :admins) |> Jason.decode() do
      {:ok, admins} ->
        user_id in admins

      _ ->
        Logger.error(
          "The admins env var may be not correctly configurated, the format should be an array of strings. For example: [\"admin\", \"admin2\"]"
        )

        false
    end
  end
end
