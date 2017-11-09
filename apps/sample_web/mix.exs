defmodule SampleWeb.Mixfile do
  use Mix.Project

  def project do
    [
      app: :sample_web,
      version: "0.0.1",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.4",
      elixirc_paths: ["lib"],
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: [],
      deps: deps()
    ]
  end

  def application do
    [
      mod: {SampleWeb.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:sample, in_umbrella: true},
      {:cowboy, "~> 1.0"},
      {:convex, github: "thusfresh/convex", ref: "draft"}
    ]
  end

end
