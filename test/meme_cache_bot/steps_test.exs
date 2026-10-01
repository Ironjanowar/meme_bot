defmodule MemeCacheBot.StepsTest do
  use ExUnit.Case, async: false

  alias MemeCacheBot.Steps

  setup do
    case Process.whereis(Steps) do
      nil -> start_supervised!(Steps)
      _pid -> :sys.replace_state(Steps, fn _state -> %{first_gen: %{}, second_gen: %{}} end)
    end

    :ok
  end

  test "only the initiating user can consume a pending action" do
    meme = %{meme_unique_id: "meme-1", telegram_id: 101}
    uuid = Steps.add_step(meme, :delete, 101)

    assert {:error, :forbidden} = Steps.take_step(uuid, 202)
    assert {:ok, ^meme, :delete} = Steps.take_step(uuid, 101)
    assert {:error, :not_found} = Steps.take_step(uuid, 101)
  end
end
