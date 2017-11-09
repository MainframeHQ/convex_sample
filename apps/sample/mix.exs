defmodule Sample.Mixfile do
  use Mix.Project

  def project do
    [
      app: :sample,
      version: "0.0.1",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.4",
      elixirc_paths: ["lib"],
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      aliases: [],
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Sample.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [{:convex, github: "thusfresh/convex", ref: "draft"}]
  end

end
