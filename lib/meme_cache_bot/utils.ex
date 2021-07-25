defmodule MemeCacheBot.Utils do
  import ExGram.Dsl.Keyboard

  def generate_buttons(uuid) do
    keyboard :inline do
      row do
        button("Yes", callback_data: "#{uuid}")
      end
    end
  end
end
