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

  scope "/", SampleWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    get "/register", PageController, :register

    get "/login", PageController, :login

    get "/join", PageController, :join

    get "/chat", PageController, :chat
  end

end
