defmodule Raditz.MixProject do
  use Mix.Project

  def project do
    [
      app: :raditz,
      version: "0.0.3",
      description: "Pooled Redis client for Elixir based on Redix.",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [ignore_warnings: ".dialyzer", plt_add_deps: true],

      # Docs
      name: "Raditz",
      source_url: "https://github.com/IanLuites/raditz",
      homepage_url: "https://github.com/IanLuites/raditz",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def package do
    [
      name: :raditz,
      maintainers: ["Ian Luites"],
      licenses: ["MIT"],
      files: [
        # Elixir
        "lib/raditz",
        "lib/raditz.ex",
        ".formatter.exs",
        "mix.exs",
        "README*",
        "LICENSE*"
      ],
      links: %{
        "GitHub" => "https://github.com/IanLuites/raditz"
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:redix, "~> 0.10"},
      {:poolboy, "~> 1.5"},

      # Dev / Test
      {:analyze, "~> 0.1.4", only: [:dev, :test], runtime: false, optional: true}
    ]
  end
end
