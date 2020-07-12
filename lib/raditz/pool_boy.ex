defmodule Raditz.PoolBoy do
  @moduledoc false
  use GenServer
  use Raditz.PoolEntity

  @impl Raditz.Pool
  def child_spec(pool, opts \\ []) do
    :poolboy.child_spec(
      pool,
      [
        name: {:local, pool},
        worker_module: __MODULE__,
        size: Keyword.get(opts, :pool_size, 1),
        max_overflow: Keyword.get(opts, :pool_overflow, 5)
      ],
      Keyword.put(opts, :server, pool)
    )
  end

  @impl Raditz.Pool
  def command(pool, command, opts \\ []) do
    :poolboy.transaction(
      pool,
      &GenServer.call(&1, {:command, command, opts}),
      Keyword.get(opts, :timeout, 5000)
    )
  end

  @impl Raditz.Pool
  def multi(pool, commands, opts \\ []) do
    :poolboy.transaction(
      pool,
      &GenServer.call(&1, {:pipeline, [["MULTI"] | commands] ++ [["EXEC"]], opts}),
      Keyword.get(opts, :timeout, 5000)
    )
  end

  @impl Raditz.Pool
  def pipeline(pool, commands, opts \\ []) do
    :poolboy.transaction(
      pool,
      &GenServer.call(&1, {:pipeline, commands, opts}),
      Keyword.get(opts, :timeout, 5000)
    )
  end

  @impl Raditz.Pool
  def script(pool, script, command, opts \\ []) do
    :poolboy.transaction(
      pool,
      &GenServer.call(&1, {:script, script, command, opts}),
      Keyword.get(opts, :timeout, 5000)
    )
  end

  ## Client API

  @doc false
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(config),
    do: GenServer.start_link(__MODULE__, %{config: config, conn: nil, scripts: %{}}, [])

  ## Server API

  @impl GenServer
  def init(state), do: {:ok, state}

  @impl GenServer
  def handle_call(command, from, state = %{config: config, conn: nil}) do
    {:ok, conn} = connect(config)
    scripts = load_scripts(conn, config)

    handle_call(command, from, %{state | conn: conn, scripts: scripts})
  end

  def handle_call({:script, script, args, opts}, _from, state = %{conn: conn, scripts: scripts}) do
    case Map.get(scripts, script) do
      {sha, keys} -> {:reply, Redix.command(conn, ["EVALSHA", sha, keys | args], opts), state}
      _ -> {:reply, {:error, :unknown_script}, state}
    end
  end

  def handle_call({command, args, opts}, _from, state = %{conn: conn}) do
    {:reply, apply(Redix, command, [conn, args, opts]), state}
  end
end
