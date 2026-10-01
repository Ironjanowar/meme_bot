defmodule MemeCacheBot.TagEditSessions do
  @moduledoc false
  use GenServer

  @timeout 60 * 60 * 1000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start(telegram_id, session) do
    GenServer.call(__MODULE__, {:start, telegram_id, session})
  end

  def get(telegram_id) do
    GenServer.call(__MODULE__, {:get, telegram_id})
  end

  def cancel(telegram_id, token) do
    GenServer.call(__MODULE__, {:cancel, telegram_id, token})
  end

  def claim(telegram_id, token) do
    GenServer.call(__MODULE__, {:claim, telegram_id, token})
  end

  @impl true
  def init(opts) do
    timeout = Keyword.get(opts, :timeout, @timeout)
    schedule_cleanup(timeout)
    {:ok, %{sessions: %{}, timeout: timeout}}
  end

  @impl true
  def handle_call({:start, telegram_id, session}, _from, state) do
    token = UUID.uuid4()
    session = session |> Map.put(:telegram_id, telegram_id) |> Map.put(:token, token)
    entry = %{session: session, started_at: now_ms()}
    {:reply, {:ok, token}, put_in(state, [:sessions, telegram_id], entry)}
  end

  def handle_call({:get, telegram_id}, _from, state) do
    reply =
      case Map.fetch(state.sessions, telegram_id) do
        {:ok, %{session: session}} -> {:ok, session}
        :error -> :none
      end

    {:reply, reply, state}
  end

  def handle_call({:cancel, telegram_id, token}, _from, state) do
    case Map.get(state.sessions, telegram_id) do
      %{session: %{token: ^token} = session} ->
        sessions = Map.delete(state.sessions, telegram_id)
        {:reply, {:ok, session}, %{state | sessions: sessions}}

      _other ->
        {:reply, {:error, :stale}, state}
    end
  end

  def handle_call({:claim, telegram_id, token}, _from, state) do
    case Map.get(state.sessions, telegram_id) do
      %{session: %{token: ^token} = session} ->
        sessions = Map.delete(state.sessions, telegram_id)
        {:reply, {:ok, session}, %{state | sessions: sessions}}

      _other ->
        {:reply, {:error, :stale}, state}
    end
  end

  @impl true
  def handle_info(:cleanup, state) do
    cutoff = now_ms() - state.timeout

    sessions =
      Map.reject(state.sessions, fn {_telegram_id, entry} -> entry.started_at <= cutoff end)

    schedule_cleanup(state.timeout)
    {:noreply, %{state | sessions: sessions}}
  end

  defp now_ms, do: System.monotonic_time(:millisecond)
  defp schedule_cleanup(timeout), do: Process.send_after(self(), :cleanup, timeout)
end
