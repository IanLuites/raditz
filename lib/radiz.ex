defmodule Raditz do
  @moduledoc """
  Documentation for Raditz.
  """

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
      @doc false
      @spec child_spec(Keyword.t()) :: term
      def child_spec(opts),
        do: unquote(pool).child_spec(__MODULE__, Keyword.merge(unquote(opts), opts))

      @doc ~S"""
      Execute a Redis command.
      """
      @spec command([binary], Keyword.t()) ::
              {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}
      def command(command, opts \\ []), do: unquote(pool).command(__MODULE__, command, opts)

      @doc ~S"""
      Run a multi Redis command.
      """
      @spec multi([[binary]], Keyword.t()) ::
              {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}
      def multi(commands, opts \\ []), do: unquote(pool).multi(__MODULE__, commands, opts)

      ### Utility ###
      alias Raditz.Util

      @doc ~S"""
      Redis server information.
      """
      @spec info :: {:ok, map} | {:error, atom}
      def info, do: Util.info(__MODULE__)
    end
  end
end
