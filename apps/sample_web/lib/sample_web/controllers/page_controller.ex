defmodule SampleWeb.PageController do
  use SampleWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end


  def register(conn, _params) do
    render conn, "register.html"
  end


  def login(conn, _params) do
    render conn, "login.html"
  end


  def join(conn, _params) do
    render conn, "join.html"
  end


  def chat(conn, _params) do
    render conn, "chat.html"
  end
end
