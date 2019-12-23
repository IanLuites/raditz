# Raditz

Pooled Redis client for Elixir based on Redix.

## Quick Start

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

## Installation

The package can be installed
by adding `raditz` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:raditz, "~> 0.0.1"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/raditz](https://hexdocs.pm/raditz).
