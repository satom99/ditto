defmodule Ditto do
  use Application
  use Supervisor
  alias Ditto.Brain

  @table :ditto

  def start(_type, _args) do
    cluster = nodes()

    :mnesia.start()
    :mnesia.change_config(:extra_db_nodes, cluster)

    ensure_table @table, [
      type: :set,
      index: [:pid, :node],
      attributes: [:key, :pid, :node],
      ram_copies: cluster,
      storage_properties: [
        ets: [read_concurrency: true]
      ]
    ]

    children = [
      worker(Brain, [])
    ]
    options = [
      strategy: :one_for_one,
      name: __MODULE__
    ]
    Supervisor.start_link(children, options)
  end

  defp nodes do
    Application.get_env(:ditto, :nodes, [])
    |> :erlang.++([node()])
    |> Enum.map(& :"#{&1}")
    |> Enum.filter(&Node.connect(&1))
  end

  defp ensure_table(name, opts) do
    case :mnesia.create_table(name, opts) do
      {:atomic, :ok} ->
        :ok
      {:aborted, {:already_exists, _}} ->
        copy_table(name)
      error ->
        raise error
    end
  end

  defp copy_table(name) do
    :mnesia.wait_for_tables([name], 10_000)

    case :mnesia.add_table_copy(name, node(), :ram_copies) do
      {:atomic, :ok} ->
        :ok
      {:aborted, {:already_exists, _, _}} ->
        :ok
      error ->
        raise error
    end
  end

  # :via API
  def send(key, data) do
    case find(key) do
      %{pid: pid} ->
        Kernel.send(pid, data)
      _ ->
        :erlang.error(:badarg, [:key, "not found"])
    end
  end

  def whereis_name(key) do
    case find(key) do
      %{pid: pid} ->
        pid
      _ ->
        :undefined
    end
  end

  def register_name(key, pid) do
    case register(key, pid) do
      :ok ->
        :yes
      _ ->
        :no
    end
  end

  def unregister_name(key) do
    unregister(key)
  end

  # Methods
  def spin(module, key) do
    {Brain, get_node()}
    |> GenServer.call({:spin, module, key})
    |> case do
      :error ->
        nil
      pid ->
        pid
    end
  end

  def find(key) do
    :mnesia.dirty_read(@table, key)
    |> structure
    |> List.last
  end

  def find_pid(pid) do
    :mnesia.dirty_index_read(@table, pid, :pid)
    |> structure
    |> List.last
  end

  def register(key, pid) do
    Brain
    |> GenServer.call {:register, key, pid}
  end

  def unregister(key) do
    Brain
    |> GenServer.call {:unregister, key}
  end

  def list_node(node) do
    :mnesia.dirty_index_read(@table, node, :node)
    |> structure
  end

  def get_node do
    :mnesia.system_info(:running_db_nodes)
    |> Enum.random

    #|> Enum.reduce(
    #  node(),
    #  fn new, acc ->
    #    # determine whether
    #    # new is more suitable
    #    new
    #  end
    #)
  end

  defp structure(rows) do
    rows
    |> Enum.map(
      fn {_, key, pid, node} ->
        %{
          key: key,
          pid: pid,
          node: node
        }
      end
    )
  end
end
