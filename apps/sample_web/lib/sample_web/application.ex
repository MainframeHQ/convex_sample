defmodule SampleWeb.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(SampleWeb.Endpoint, []),
    ]

    opts = [strategy: :one_for_one, name: SampleWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    SampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
