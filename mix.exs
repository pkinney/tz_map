defmodule TzMap.MixProject do
  use Mix.Project

  def project do
    [
      app: :tz_map,
      version: "0.1.0",
      elixir: "~> 1.14",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {TzMap.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rstar, github: "armon/erl-rstar", branch: "master"},
      {:topo, "~> 0.5"},
      {:geo, "~> 2.0 or ~> 3.0"},
      {:envelope, "~> 1.0"},
      {:exshape, "~> 2.1.2", only: :dev},
      {:tzdata, "~> 1.1", only: :dev},
      {:size, "~> 0.1.0", only: :dev},
      {:stream_data, "~> 0.5", only: [:test, :dev]}
    ]
  end

  defp description() do
    """
    Provides a mapping of spatial coordinates to time zone names.
    """
  end

  defp package() do
    [
      files: ["lib", "priv", "mix.exs", "README*"],
      maintainers: ["Powell Kinney"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/pkinney/tz_map"}
    ]
  end
end
