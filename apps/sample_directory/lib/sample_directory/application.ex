defmodule SampleDirectory.Application do
  @moduledoc false


  #===========================================================================
  # Includes
  #===========================================================================

  use Application

  alias SampleDirectory.Directory


  #===========================================================================
  # Behaviour Application Callback Functions
  #===========================================================================

  def start(_type, _args) do
    Directory.initialize()
    opts = [strategy: :one_for_one, name: SampleDirectory.Supervisor]
    Supervisor.start_link([], opts)
  end

end
