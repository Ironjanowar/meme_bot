defmodule MemeCacheBot.Steps do
  use GenServer

  # 1 hour
  @timeout 60 * 60 * 1000

  require Logger

  # Child specification
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  # Client API
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def add_step(meme_info, action, user_id) do
    GenServer.call(__MODULE__, {:add_step, action, meme_info, user_id})
  end

  def take_step(uuid, user_id) do
    GenServer.call(__MODULE__, {:take_step, uuid, user_id})
  end

  # Server callbacks
  def init(:ok) do
    Process.send_after(self(), :timeout, @timeout)
    {:ok, %{first_gen: %{}, second_gen: %{}}}
  end

  def handle_info(:timeout, %{first_gen: first_gen}) do
    Logger.debug("Cleaning Steps genserver, next clean up in #{@timeout} ms")
    Process.send_after(self(), :timeout, @timeout)
    {:noreply, %{first_gen: %{}, second_gen: first_gen}}
  end

  def handle_call({:add_step, action, meme, user_id}, _from, %{
        first_gen: first_gen,
        second_gen: second_gen
      }) do
    uuid = UUID.uuid4()
    new_first_gen = Map.put(first_gen, uuid, %{meme: meme, action: action, user_id: user_id})
    {:reply, uuid, %{first_gen: new_first_gen, second_gen: second_gen}}
  end

  def handle_call(
        {:take_step, uuid, user_id},
        _from,
        %{first_gen: first_gen, second_gen: second_gen} = state
      ) do
    case get_from_generations(uuid, first_gen, second_gen) do
      %{user_id: ^user_id, meme: meme, action: action} ->
        new_state = delete_from_generations(state, uuid)
        {:reply, {:ok, meme, action}, new_state}

      %{user_id: _other_user_id} ->
        {:reply, {:error, :forbidden}, state}

      _ ->
        {:reply, {:error, :not_found}, state}
    end
  end

  # Private
  defp get_from_generations(uuid, first_gen, second_gen) do
    case Map.get(first_gen, uuid, :not_found) do
      :not_found -> Map.get(second_gen, uuid)
      found -> found
    end
  end

  defp delete_from_generations(state, uuid) do
    %{
      first_gen: Map.delete(state.first_gen, uuid),
      second_gen: Map.delete(state.second_gen, uuid)
    }
  end
end
