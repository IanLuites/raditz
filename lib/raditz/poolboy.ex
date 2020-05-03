defmodule Raditz.PoolBoy do
  @moduledoc false
  use GenServer

  @behaviour Raditz.Pool

  @impl Raditz.Pool
  def child_spec(pool, opts \\ []) do
    :poolboy.child_spec(
      pool,
      [
        name: {:local, pool},
        worker_module: __MODULE__,
        size: Keyword.get(opts, :pool_size, 1),
        max_overlow: Keyword.get(opts, :pool_overflow, 5)
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
    conn = connect(config)
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

  @spec connect(Keyword.t()) :: Redix.Connection.t()
  defp connect(config) do
    url = redis_url(config) || raise "Missing Redis url."
    {:ok, conn} = Redix.start_link(url)
    conn
  end

  @spec redis_url(Keyword.t()) :: String.t()
  defp redis_url(config),
    do: Application.get_env(config[:otp_app], config[:server], [])[:url] || config[:url]

  @spec load_scripts(Redix.Connection.t(), Keyword.t()) :: map
  defp load_scripts(conn, config) do
    scripts =
      Application.get_env(config[:otp_app], config[:server], [])[:scripts] || config[:scripts]

    Enum.reduce(scripts || [], %{}, fn {script, opts}, acc ->
      sha = Redix.command!(conn, ["SCRIPT", "LOAD", opts[:code]])
      Map.put(acc, script, {sha, opts[:keys]})
    end)
  end
end
