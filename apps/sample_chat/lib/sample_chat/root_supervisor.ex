defmodule SampleChat.RootSupervisor do
  @moduledoc false

  #===========================================================================
  # Includes
  #===========================================================================

  use Supervisor


  #===========================================================================
  # Attributes
  #===========================================================================

  @server_name :sample_chat_root_supervisor


  #===========================================================================
  # API Functions
  #===========================================================================

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: @server_name)
  end


  #===========================================================================
  # Supervisor Callback Functions
  #===========================================================================

  def init(opts) do
    supervise([
        supervisor(SampleChat.Supervisor, [opts]),
        worker(SampleChat.Manager, [opts], [])
      ], strategy: :one_for_all)
  end

end
