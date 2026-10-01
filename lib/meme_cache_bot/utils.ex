defmodule MemeCacheBot.Utils do
  @moduledoc false

  import ExGram.Dsl.Keyboard

  require Logger

  def save_keyboard(uuid) do
    keyboard :inline do
      row do
        button("Save", callback_data: uuid)
      end
    end
  end

  def existing_meme_keyboard(delete_uuid, edit_uuid) do
    keyboard :inline do
      row do
        button("Delete", callback_data: delete_uuid)
        button("Edit tags", callback_data: edit_uuid)
      end
    end
  end

  def cancel_keyboard(uuid) do
    keyboard :inline do
      row do
        button("Cancel", callback_data: uuid)
      end
    end
  end

  def edit_tags_keyboard(uuid) do
    keyboard :inline do
      row do
        button("Edit tags", callback_data: uuid)
      end
    end
  end

  def get_page_from_text(text) do
    case Integer.parse(text) do
      {page, _} -> page
      _ -> 0
    end
  end

  def admin?(user_id) do
    case ExGram.Config.get(:meme_cache_bot, :admins) |> Jason.decode() do
      {:ok, admins} ->
        user_id in admins

      _ ->
        Logger.error(
          ~s(The admins env var may be not correctly configurated, the format should be an array of strings. For example: ["admin", "admin2"])
        )

        false
    end
  end
end
