defmodule Raditz.PoolEntity do
  @moduledoc false

  defmacro __using__(opts \\ []) do
    imported =
      quote location: :keep do
        @behaviour Raditz.Pool
        import unquote(__MODULE__), only: [script_gen: 1, connect: 1, load_scripts: 2]
      end

    if opts[:actions] do
      quote location: :keep do
        unquote(imported)

        @impl Raditz.Pool
        def command(pool, command, opts \\ []) do
          Redix.command(apply(:"#{pool}.Pool", :conn, []), command, opts)
        end

        @impl Raditz.Pool
        def multi(pool, commands, opts \\ []) do
          Redix.pipeline(
            apply(:"#{pool}.Pool", :conn, []),
            [["MULTI"] | commands] ++ [["EXEC"]],
            opts
          )
        end

        @impl Raditz.Pool
        def pipeline(pool, commands, opts \\ []) do
          Redix.pipeline(apply(:"#{pool}.Pool", :conn, []), commands, opts)
        end

        @impl Raditz.Pool
        def script(pool, script, command, opts \\ []) do
          p = :"#{pool}.Pool"
          {sha, keys} = apply(p, :script, [script])
          Redix.command(apply(p, :conn, []), ["EVALSHA", sha, keys | command], opts)
        end
      end
    else
      imported
    end
  end

  @spec connect(Keyword.t()) :: :gen_statem.start_ret()
  def connect(opts) do
    url = redis_url(opts) || raise "Missing Redis url."
    Redix.start_link(url)
  end

  @spec redis_url(Keyword.t()) :: String.t() | nil
  def redis_url(opts),
    do: Application.get_env(opts[:otp_app], opts[:server], [])[:url] || opts[:url]

  @spec load_scripts(Redix.connection(), Keyword.t()) :: map
  def load_scripts(conn, config) do
    scripts =
      Application.get_env(config[:otp_app], config[:server], [])[:scripts] || config[:scripts]

    Enum.reduce(scripts || [], %{}, fn {script, opts}, acc ->
      sha = Redix.command!(conn, ["SCRIPT", "LOAD", opts[:code]])
      Map.put(acc, script, {sha, opts[:keys]})
    end)
  end

  @doc false
  @spec script_gen(map) :: term
  def script_gen(scripts) do
    a =
      Enum.reduce(
        scripts,
        quote do
          @doc false
          @spec script(term) :: {String.t(), term} | nil
          def script(script)
        end,
        fn acc, {script, v} ->
          quote do
            unquote(acc)
            def script(unquote(script)), do: unquote(v)
          end
        end
      )

    quote do
      unquote(a)
      def script(_), do: nil
    end
  end
end
