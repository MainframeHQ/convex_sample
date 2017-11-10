defmodule SampleWeb.Proxy do
  @moduledoc false

  @behaviour Convex.Proxy


  #===========================================================================
  # Includes
  #===========================================================================

  alias __MODULE__, as: This
  alias Convex.Proxy


  #===========================================================================
  # Types
  #===========================================================================

  defstruct [
    pid: nil
  ]


  #===========================================================================
  # API Functions
  #===========================================================================

  def new(pid) do
    Proxy.new(This, pid: pid)
  end


  #===========================================================================
  # Behaviour Convex.Proxy Callback Functions
  #===========================================================================

  def init(opts) do
    %This{pid: Keyword.fetch!(opts, :pid)}
  end


  def pid(%This{pid: pid}), do: pid


  def unbind(_this), do: :ok


  def post(msg, %This{pid: pid}), do: send(pid, msg)


  def post(_ctx, msg, %This{pid: pid}), do: send(pid, msg)


  def close(_this), do: :ok


  def policy_changed(_this, _policy), do: :ok

end
