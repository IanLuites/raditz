defmodule Raditz do
  @moduledoc ~S"""
  Pooled Redis client.

  # Quick Installation

  ```
  defmodule Redis do
    use Raditz, url: "redis://localhost"
  end
  ```

  Dynamic configuration:
  ```
  defmodule Redis do
    use Raditz

    @impl Raditz
    def configure, do: [url: System.get_env("REDIS_URL")]
  end
  ```
  """

  @doc ~S"""
  Apply dynamic configuration at startup.
  """
  @callback configure :: Keyword.t()

  @doc @moduledoc
  defmacro __using__(opts \\ []) do
    otp_app = opts[:otp_app]

    pool =
      cond do
        pool = Application.get_env(otp_app, __CALLER__, [])[:pool] -> pool
        pool = opts[:pool] -> pool
        pool = Application.get_env(:raditz, :pool) -> pool
        :default -> Raditz.PoolBoy
      end

    quote location: :keep do
      @behaviour unquote(__MODULE__)

      @doc false
      @spec child_spec(Keyword.t()) :: term
      def child_spec(opts),
        do: unquote(pool).child_spec(__MODULE__, Keyword.merge(configure(), opts))

      @doc """
      Execute a Redis command.

      ## Examples

      ```elixir
      iex> #{inspect(__MODULE__)}.command(~W(SET mykey somevalue))
      {:ok, "OK"}
      iex> #{inspect(__MODULE__)}.command(~W(GET mykey))
      {:ok, "somevalue"}
      ```
      """
      @spec command([binary], Keyword.t()) ::
              {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}
      def command(command, opts \\ []), do: unquote(pool).command(__MODULE__, command, opts)

      @doc """
      Run a multiple Redis commands in a transaction.

      The result on success will always start with `"OK"`
      (indicating the start of the transaction) followed by the keyword
      `"QUEUED"` for each command in the transaction.

      The last element in the result is a list with the return value
      for each queued command.

      ## Examples

      ```elixir
      iex> #{inspect(__MODULE__)}.multi([
      ...>   ~W(INCR foo),
      ...>   ~W(INCR bar)
      ...> ])
      {:ok, ["OK", "QUEUED", "QUEUED", [1, 1]]}
      ```
      """
      @spec multi([[binary]], Keyword.t()) ::
              {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}
      def multi(commands, opts \\ []), do: unquote(pool).multi(__MODULE__, commands, opts)

      ### Utility ###
      alias Raditz.Util

      @doc """
      Redis server information.

      ## Examples

      ```elixir
      iex> #{inspect(__MODULE__)}.info
      {:ok,
       %{
         sync_partial_err: "0",
         hz: "10",
         redis_build_id: "24cefa6406f92a1f",
         rdb_last_save_time: "1577100056",
         used_memory_dataset: "18642",
         role: "master",
         process_id: "1",
         used_memory_scripts: "0",
         used_memory_startup: "791264",
         used_memory_peak_perc: "71.49%",
         expired_keys: "62",
         migrate_cached_sockets: "0",
         os: "Linux 5.4.6-arch1-1 x86_64",
         used_cpu_sys_children: "0.007416",
         master_repl_offset: "0",
         active_defrag_running: "0",
         run_id: "a2fed687efef91a3de427a7e266cb54995674343",
         rdb_last_bgsave_time_sec: "0",
         maxmemory_human: "0B",
         config_file: "",
         aof_current_rewrite_time_sec: "-1",
         mem_fragmentation_bytes: "4072304",
         client_recent_max_output_buffer: "0",
         second_repl_offset: "-1",
         total_connections_received: "249",
         active_defrag_misses: "0",
         redis_git_sha1: "00000000",
         cluster_enabled: "0",
         slave_expires_tracked_keys: "0",
         active_defrag_key_misses: "0",
         used_memory_lua: "37888",
         allocator_frag_ratio: "1.34",
         aof_last_rewrite_time_sec: "-1",
         allocator_rss_ratio: "3.97",
         rss_overhead_bytes: "241664",
         allocator_resident: "4648960",
         aof_enabled: "0",
         maxmemory_policy: "noeviction",
         mem_aof_buffer: "0",
         allocator_rss_bytes: "3477504",
         used_cpu_sys: "851.991993",
         lazyfree_pending_objects: "0",
         redis_mode: "standalone",
         rdb_last_cow_size: "475136",
         rdb_changes_since_last_save: "86",
         used_memory_dataset_perc: "27.00%",
         repl_backlog_histlen: "0",
         used_memory: "860320",
         ...
       }}
      ```
      """
      @spec info :: {:ok, map} | {:error, atom}
      def info, do: Util.info(__MODULE__)

      ### Configuration ###

      @doc false
      @impl unquote(__MODULE__)
      def configure, do: unquote(opts)

      defoverridable configure: 0
    end
  end
end
