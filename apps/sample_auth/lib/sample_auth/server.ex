defmodule SampleAuth.Server do
  @moduledoc false

  @behaviour Convex.Director


  #===========================================================================
  # Includes
  #===========================================================================

  use GenServer

  import Convex.Sigils

  alias __MODULE__, as: This
  alias Convex.Context, as: Ctx
  alias Convex.GenServer, as: CvxGenServer


  #===========================================================================
  # Types
  #===========================================================================

  @type t :: %This{
    users: %{optional(String.t) => {String.t, String.t}}
  }

  defstruct [
    users: %{}
  ]


  #===========================================================================
  # Attributes
  #===========================================================================

  @server_name :sample_auth_server


  #===========================================================================
  # API Functions
  #===========================================================================

  @spec start_link(Keyword.t) :: {:ok, pid} | {:error, term}

  def start_link(opts) do
    GenServer.start_link(This, opts, name: @server_name)
  end


  #===========================================================================
  # Behaviour Convex.Director Callback Functions
  #===========================================================================

  def perform(ctx, op, args) do
    CvxGenServer.perform(@server_name, ctx, op, args)
  end


  #===========================================================================
  # Behaviour GenServer Callback Functions
  #===========================================================================

  def init(_opts) do
    {:ok, %This{}}
  end


  def handle_cast({:perform, packet}, this) do
    CvxGenServer.handle_perform(packet, this)
  end

  def handle_cast(request, this) do
    super(request, this)
  end


  #===========================================================================
  # Convex.GenServer Operation Handling Callback Functions
  #===========================================================================

  def handle_operation(ctx, ~o"auth.register",
                       %{username: u, password: p}, this) do
    case user_register(u, p, this) do
      {:error, reason} -> {:error, this, reason}
      {:ok, this, user_id} ->
        ctx = ctx
          |> Ctx.authenticate(user_id, %{can_join: true, can_post: true})
          |> Ctx.done(user_id)
        {this, ctx}
    end
  end

  def handle_operation(ctx, ~o"auth.login",
                       %{username: u, password: p}, this) do
    case user_login(u, p, this) do
      {:error, reason} -> {:error, this, reason}
      {:ok, user_id} ->
        ctx = ctx
          |> Ctx.authenticate(user_id, %{can_join: true, can_post: true})
          |> Ctx.done(user_id)
        {this, ctx}
    end
  end


  #===========================================================================
  # Internal Functions
  #===========================================================================

  defp generate_user_id() do
    :crypto.strong_rand_bytes(16)
      |> Base.url_encode64()
  end


  defp user_register(username, password, this) do
    case Map.fetch(this.users, username) do
      {:ok, _} -> {:error, :username_already_exists}
      :error ->
        user_id = generate_user_id()
        users = Map.put(this.users, username, {password, user_id})
        this = %This{this | users: users}
        {:ok, this, user_id}
    end
  end


  defp user_login(username, password, this) do
    case Map.fetch(this.users, username) do
      :error -> {:error, :user_not_found}
      {:ok, {^password, user_id}} -> {:ok, user_id}
      {:ok, _} -> {:error, :bad_password}
    end
  end

end
