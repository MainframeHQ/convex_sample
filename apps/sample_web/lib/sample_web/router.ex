defmodule SampleWeb.Router do
  @moduledoc false

  use SampleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug SampleWeb.Plug.ConvexAuth
  end

  pipeline :channel_setup do
    plug :put_channel_token
  end

  scope "/", SampleWeb do
    pipe_through [:browser]
    get  "/register", PageController, :register
    post "/register", PageController, :register_callback
    get  "/login",  PageController, :login
    post "/login",  PageController, :login_callback
  end

  scope "/", SampleWeb do
    pipe_through [:browser, :auth]
    get  "/", PageController, :join
    get  "/chat", PageController, :join
    get  "/logout", PageController, :logout
  end

  scope "/", SampleWeb do
    pipe_through [:browser, :auth, :channel_setup]
    post "/chat", PageController, :chat
  end


  #===========================================================================
  # Internal functions
  #===========================================================================

  defp put_channel_token(conn, _) do
    if user_id = get_session(conn, :context)[:auth] do
      token = Phoenix.Token.sign(conn, "user socket", user_id)
      assign(conn, :channel_token, token)
    else
      conn
    end
  end

end
