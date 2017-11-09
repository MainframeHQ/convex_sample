defmodule SampleAuth.Application do
  @moduledoc false

  #===========================================================================
  # Includes
  #===========================================================================

  use Application


  #===========================================================================
  # Behaviour Application Callback Functions
  #===========================================================================

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    options = []

    children = [
      worker(SampleAuth.Server, [options]),
    ]

    opts = [strategy: :one_for_one, name: SampleAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
