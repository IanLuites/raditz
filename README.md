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

## Experimental Pools

### PoolGuy

A fast randomly distributed connection pool.
Optimized for speed gaining larger advantages at greater pool sizes.
Starts out 20% faster than PoolBoy, but at a pool size of 10 grows to be 500% faster.
At 50 it reached 900% leading to speeds of 10x times that of PoolBoy.

### PoolMan

A relatively fast round-robin distributed connection pool.

This pool is slower than PoolGuy, but offers a more controller round-robin approach to balancing the load.

Optimized for speed gaining larger advantages at greater pool sizes.
Starts out 20% faster than PoolBoy, but at a pool size of 10 grows to be 200% faster.
At 50 it reached 700% leading to speeds of 8x times that of PoolBoy.

## Installation

The package can be installed
by adding `raditz` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:raditz, "~> 0.1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/raditz](https://hexdocs.pm/raditz).
