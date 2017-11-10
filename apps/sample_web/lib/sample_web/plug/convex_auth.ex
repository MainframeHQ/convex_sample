defmodule SampleWeb.Plug.ConvexAuth do

  @behaviour Plug

  #===========================================================================
  # Includes
  #===========================================================================

  import Plug.Conn

  alias Phoenix.Controller


  #===========================================================================
  # Plug Behaviour Functions
  #===========================================================================

  def init(opts), do: opts


  def call(conn, _opts) do
    ctx = get_session(conn, :context)
    if ctx == nil or ctx[:auth] == nil do
        conn
        |> clear_session()
        |> Controller.put_flash(:info, "Not Logged In")
        |> Controller.redirect(to: "/login")
        |> halt
    else
      conn
    end
  end

end