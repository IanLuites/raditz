defmodule Raditz.Pool do
  @moduledoc ~S"""
  Connection pool behavior.
  """

  @callback child_spec(module, Keyword.t()) :: Supervisor.child_spec() | :supervisor.child_spec()

  @callback command(module, [binary], Keyword.t()) ::
              {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}

  @callback multi(module, [[binary]], Keyword.t()) ::
              {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}

  @callback pipeline(module, [[binary]], Keyword.t()) ::
              {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}

  @callback script(module, atom, [binary], Keyword.t()) ::
              {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}
end
