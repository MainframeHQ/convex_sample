defmodule Sample.Application do
  @moduledoc false


  #===========================================================================
  # Includes
  #===========================================================================

  use Application


  #===========================================================================
  # Behaviour Application Callback Functions
  #===========================================================================

  def start(_type, _args) do
    Supervisor.start_link([], strategy: :one_for_one, name: Sample.Supervisor)
  end

end
