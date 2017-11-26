defmodule Ditto.Brain do
  use GenServer

  @table :ditto

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def handle_call({:spin, module, key}, _from, state) do
    case module.start(key) do
      {:ok, pid} ->
        register(key, pid)
        {:reply, pid, state}
      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call({:register, key, pid}, _from, state) do
    case Ditto.find(key) do
      nil ->
        register(key, pid)
        {:reply, :ok, state}
      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call({:unregister, key}, _from, state) do
    unregister(key)
    {:reply, :ok, state}
  end

  def handle_info({:DOWN, _ref, _process, pid, _reason}, state) do
    case Ditto.find_pid(pid) do
      %{key: key} ->
        unregister(key)
      _ ->
        :ok
    end
    {:noreply, state}
  end

  defp register(key, pid) do
    Process.monitor(pid)
    :mnesia.dirty_write {@table, key, pid, node()}
  end

  defp unregister(key) do
    :mnesia.dirty_delete @table, key
  end
end
