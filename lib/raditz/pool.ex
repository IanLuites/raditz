defmodule Raditz.Pool do
  @moduledoc ~S"""
  Connection pool behavior.
  """

  @callback child_spec(module, Keyword.t()) :: tuple

  @callback command(module, [binary], Keyword.t()) ::
              {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}

  @callback multi(module, [[binary]], Keyword.t()) ::
              {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}

  @callback script(module, atom, [binary], Keyword.t()) ::
              {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}
end
