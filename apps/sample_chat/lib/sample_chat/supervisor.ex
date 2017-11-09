defmodule SampleChat.Supervisor do
  @moduledoc false

  #===========================================================================
  # Includes
  #===========================================================================

  use Supervisor


  #===========================================================================
  # Attributes
  #===========================================================================

  @server_name :sample_chat_process_supervisor


  #===========================================================================
  # API Functions
  #===========================================================================

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: @server_name)
  end


  def start_child(room_id, name) do
    Supervisor.start_child(@server_name, [room_id, name])
  end


  #===========================================================================
  # Supervisor Callback Functions
  #===========================================================================

  def init(opts) do
    supervise([
        worker(SampleChat.Server, [opts], restart: :temporary)
      ], strategy: :simple_one_for_one)
  end

end
