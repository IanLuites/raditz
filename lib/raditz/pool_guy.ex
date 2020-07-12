defmodule Raditz.PoolGuy do
  use Raditz.PoolEntity, actions: true

  @impl Raditz.Pool
  def child_spec(pool, opts \\ []) do
    mod = :"#{pool}.Pool"
    opts = Keyword.update(opts, :pool_size, 1, &max(&1, 1))
    start = if(opts[:pool_size] > 1, do: :start_link_multi, else: :start_link_single)

    %{
      id: mod,
      start: {__MODULE__, start, [mod, opts]}
    }
  end

  @doc false
  @spec start_link_multi(module, maybe_improper_list) :: :ignore | {:error, any} | {:ok, pid}
  def start_link_multi(mod, opts) do
    size = opts[:pool_size]

    with {:ok, code, scripts} <-
           Enum.reduce(0..(size - 1), {:ok, nil, %{}}, fn
             i, {:ok, acc, _} ->
               with {:ok, pid} <- connect(opts) do
                 {:ok,
                  quote do
                    unquote(acc)
                    defp conn(unquote(i)), do: unquote(pid)
                  end, load_scripts(pid, opts)}
               end

             _, err ->
               err
           end) do
      Code.compile_quoted(
        quote do
          defmodule unquote(mod) do
            @moduledoc false

            @doc false
            @spec conn :: pid
            def conn do
              conn(rem(:erlang.unique_integer([:positive]), unquote(size)))
            end

            @spec conn(non_neg_integer) :: pid
            defp conn(index)
            unquote(code)

            unquote(script_gen(scripts))
          end
        end
      )

      {:ok, self()}
    end
  end

  @doc false
  @spec start_link_single(module, maybe_improper_list) :: :ignore | {:error, any} | {:ok, pid}
  def start_link_single(mod, opts) do
    with {:ok, pid} <- connect(opts) do
      Code.compile_quoted(
        quote do
          defmodule unquote(mod) do
            @moduledoc false

            @doc false
            @spec conn :: pid
            def conn, do: unquote(pid)

            unquote(script_gen(load_scripts(pid, opts)))
          end
        end
      )

      {:ok, pid}
    end
  end
end
