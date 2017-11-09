defmodule SampleChat.Server do
  @moduledoc false

  #===========================================================================
  # Includes
  #===========================================================================

  use GenServer

  import Convex.Sigils

  alias __MODULE__, as: This
  alias Convex.Context, as: Ctx
  alias Convex.GenServer, as: CvxGenServer
  alias Convex.Proxy


  #===========================================================================
  # Types
  #===========================================================================

  @type t :: %This{
    id: String.t,
    name: String.t,
    participants: MapSet.t,
    next_index: integer,
    messages: [{integer, integer, String.t, String.t}],
    bindings: %{optional(String.t) => Proxy.t},
    monitored: %{optional(reference) => String.t},
  }

  defstruct [
    :id,
    :name,
    participants: MapSet.new(),
    next_index: 1,
    messages: [],
    bindings: %{},
    monitored: %{},
  ]


  #===========================================================================
  # API Functions
  #===========================================================================

  @spec start_link(Keyword.t, String.t, String.t) :: {:ok, pid} | {:error, term}

  def start_link(opts, room_id, name) do
    GenServer.start_link(This, [room_id, name, opts])
  end


  @spec perform(pid, Ctx.t, Ctx.op, map) :: Ctx.t

  def perform(pid, ctx, op, args) do
    CvxGenServer.perform(pid, ctx, op, args)
  end


  #===========================================================================
  # Behaviour GenServer Callback Functions
  #===========================================================================

  def init([room_id, name, _opts]) do
    {:ok, %This{id: room_id, name: name}}
  end


  def handle_cast({:perform, packet}, this) do
    CvxGenServer.handle_perform(packet, this)
  end

  def handle_cast(request, this) do
    super(request, this)
  end


  def handle_info({:DOWN, ref, :process, _pid, _reason}, this) do
    case Map.pop(this.monitored, ref) do
      {nil, _} -> {:noreply, this}
      {user_id, monitored} ->
        this = %This{this | monitored: monitored}
        this = unbind(user_id, this)
        this = leave(user_id, this)
        {:noreply, this}
    end
  end

  def handle_info(msg, this) do
    super(msg, this)
  end


  #===========================================================================
  # Convex.GenServer Operation Handling Callback Functions
  #===========================================================================

  @spec handle_operation(Ctx.t, Ctx.op, map, This.t) :: {This.t, Ctx.t}

  def handle_operation(%Ctx{auth: nil}, _op, _args, this) do
    {:error, this, :forbidden}
  end

  def handle_operation(ctx, ~o"chat.join", _args, this) do
    {:ok, join(ctx.auth, this), this.id}
  end

  def handle_operation(ctx, ~o"chat.leave", _args, this) do
    {:ok, leave(ctx.auth, this), this.id}
  end

  def handle_operation(_ctx, ~o"chat.produce.participants", _args, this) do
    {:produce, this, this.participants}
  end

  def handle_operation(ctx, ~o"chat.produce.history",
                       %{size: size, bind: bind?}, this) do
    case bind? and not Map.has_key?(this.bindings, ctx.auth) do
      false ->
        {:produce, this, get_history(size, this)}
      true ->
        case bind(ctx, this) do
          {:error, this, ctx, reason} ->
            {this, Ctx.failed(ctx, reason)}
          {:ok, this, ctx} ->
            # If we use the context we CANNOT use the shorthand `:produce`
            # return value anymore because we MUST return the new context.
            {this, Ctx.produce(ctx, get_history(size, this))}
        end
    end
  end

  def handle_operation(ctx, ~o"chat.post", %{message: msg}, this) do
    {:ok, post(ctx.auth, msg, this), nil}
  end


  #===========================================================================
  # Internal Functions
  #===========================================================================

  defp get_history(size, this) do
    # Producing values do not ensure ordering so we don't need to reverse,
    # this is the responsability of the pipeline initiator.
    Enum.take(this.messages, size)
  end


  defp join(user_id, this) do
    case MapSet.member?(this.participants, user_id) do
      true -> this
      false ->
        participants = MapSet.put(this.participants, user_id)
        this = %This{this | participants: participants}
        broadcast({:joined, user_id}, user_id, this)
    end
  end


  defp leave(user_id, this) do
    case MapSet.member?(this.participants, user_id) do
      false -> this
      true ->
        participants = MapSet.delete(this.participants, user_id)
        this = %This{this | participants: participants}
        broadcast({:left, user_id}, user_id, this)
    end
  end


  defp post(user_id, msg, this) do
    rec = {this.next_index, :os.timestamp(), user_id, msg}
    messages = [rec | this.messages]
    this = %This{this | next_index: this.next_index + 1, messages: messages}
    broadcast({:posted, rec}, user_id, this)
  end


  defp broadcast(msg, except, this) do
    Enum.each this.bindings, fn
      ({^except, _}) -> :ok
      ({_user_id, proxy}) -> Proxy.post(msg, proxy)
    end
    this
  end


  defp bind(ctx, this) do
    case Ctx.bind(ctx) do
      {:error, ctx, reason} ->
        {:error, this, ctx, reason}
      {:ok, ctx, proxy} ->
        ref = Process.monitor(Proxy.pid(proxy))
        bindings = Map.put(this.bindings, ctx.auth, proxy)
        monitored = Map.put(this.monitored, ref, ctx.auth)
        {:ok, %This{this | bindings: bindings, monitored: monitored}, ctx}
    end
  end


  defp unbind(user_id, this) do
    case Map.pop(this.bindings, user_id) do
      {nil, _} -> this
      {proxy, bindings} ->
        Proxy.unbind(proxy)
        %This{this | bindings: bindings}
    end
  end

end
