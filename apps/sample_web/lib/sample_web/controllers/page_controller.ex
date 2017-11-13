defmodule SampleWeb.PageController do

  #===========================================================================
  # Includes
  #===========================================================================

  use SampleWeb, :controller

  import Convex.Pipeline

  alias Convex.Context.Sync


  #===========================================================================
  # Router Handler Functions
  #===========================================================================

  def register(conn, _params) do
    render(conn, "register.html")
  end


  def register_callback(conn, %{"info" => info}) do
    %{"username" => username,
      "password" => password,
      "name" => name,
      "nick" => nick,
    } = info

    cond do
      username == "" ->
        conn
          |> put_flash(:info, "Wrong username")
          |> render("register.html")
      password == "" ->
        conn
          |> put_flash(:info, "Wrong password")
          |> render("register.html")
      name == "" ->
        conn
          |> put_flash(:info, "Wrong name")
          |> render("register.html")
      nick == "" ->
        conn
          |> put_flash(:info, "Wrong nick")
          |> render("register.html")
      true ->
        case do_register(username, password, name, nick) do
          {:error, :username_already_exists} ->
            conn
              |> put_flash(:info, "Username already exists")
              |> render("register.html")
          {:error, reason} ->
            conn
              |> put_flash(:info, "Registration error: #{inspect reason}")
              |> render("register.html")
          {:ok, {ctx, profile}} ->
            conn
              |> put_session(:profile, profile)
              |> put_session(:context, ctx)
              |> put_flash(:info, "Logged in")
              |> redirect(to: "/")
        end
    end
  end


  def login(conn, _params) do
    render conn, "login.html"
  end


  def login_callback(conn, %{"creds" => creds}) do
    %{"username" => username, "password" => password} = creds
    case do_login(username, password) do
      {:error, _reason} ->
        conn
          |> put_flash(:info, "Wrong username or password")
          |> render("login.html")
      {:ok, {ctx, profile}} ->
        conn
          |> put_session(:profile, profile)
          |> put_session(:context, ctx)
          |> put_flash(:info, "Logged in")
          |> redirect(to: "/")
    end
  end


  def join(conn, _params) do
    profile = get_session(conn, :profile)
    render conn, "join.html", profile: profile
  end


  def chat(conn, %{"room" => %{"name" => name}}) do
    profile = get_session(conn, :profile)
    render conn, "chat.html", profile: profile, room_name: name
  end


  def logout(conn, _params) do
    conn
      |> clear_session()
      |> put_flash(:info, "Logged out")
      |> redirect(to: "/")
  end


  #===========================================================================
  # Internal Functions
  #===========================================================================

  defp do_login(username, password) do
    perform with: Sync.new() do
      auth.login username: ^username, password: ^password
      profile = directory.lookup id: ctx.auth
      {ctx, profile}
    end
  end


  defp do_register(username, password, name, nick) do
    perform with: Sync.new() do
      auth.register username: ^username, password: ^password
      profile = directory.add id: ctx.auth, name: ^name, nick: ^nick
      {ctx, profile}
    end
  end

end
