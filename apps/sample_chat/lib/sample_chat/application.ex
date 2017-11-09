defmodule SampleChat.Application do
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
      supervisor(SampleChat.RootSupervisor, [options]),
    ]

    opts = [strategy: :one_for_one, name: SampleChat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
