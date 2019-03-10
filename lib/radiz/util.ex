defmodule Raditz.Util do
  @moduledoc false

  @doc false
  @spec info(module) :: {:ok, map} | {:error, atom}
  def info(server) do
    with {:ok, info} <- server.command(["INFO"]) do
      {:ok,
       info
       |> String.split(~r/\r?\n/)
       |> Enum.reject(&(String.starts_with?(&1, "#") or &1 == ""))
       |> Map.new(fn info ->
         [field, info] = String.split(info, ":", parts: 2)
         {String.to_atom(field), info}
       end)}
    end
  end
end
