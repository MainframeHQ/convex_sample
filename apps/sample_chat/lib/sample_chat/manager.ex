defmodule SampleChat.Manager do
  @moduledoc false

  @behaviour Convex.Director


  #===========================================================================
  # Includes
  #===========================================================================

  use GenServer

  import Convex.Sigils

  alias __MODULE__, as: This
  alias SampleChat.Supervisor
  alias SampleChat.Server

  alias Convex.Context, as: Ctx
  alias Convex.GenServer, as: CvxGenServer


  #===========================================================================
  # Attributes
  #===========================================================================

  @server_name :sample_chat_manager
  @from_room_id :sample_chat_from_room_id
  @from_pid :sample_chat_from_pid
  @from_name :sample_chat_from_name


  #===========================================================================
  # Types
  #===========================================================================

  @type t :: %This{}

  defstruct []


  #===========================================================================
  # API Functions
  #===========================================================================

  def start_link(opts) do
    GenServer.start_link(This, opts, name: @server_name)
  end


  #===========================================================================
  # Behaviour Convex.Director Callback Functions
  #===========================================================================

  def perform(ctx, op, args) do
    perform_inline(ctx, op, args)
  end


  #===========================================================================
  # Behaviour GenServer Callback Functions
  #===========================================================================

  def init(_opts) do
    Process.flag(:trap_exit, true)
    initialise_tables()
    {:ok, %This{}}
  end


  def handle_cast({:perform, packet}, this) do
    CvxGenServer.handle_perform packet, this
  end

  def handle_cast(request, this) do
    super(request, this)
  end


  def handle_info({:EXIT, pid, _reason}, this) do
    delete_pid(pid)
    {:noreply, this}
  end

  def handle_info(message, this) do
    super(message, this)
  end


  #===========================================================================
  # Convex.GenServer Operation Handling Callback Functions
  #===========================================================================

  def handle_operation(ctx, ~o"chat.join" = op, %{name: name} = args, this) do
    case start_link_server(name) do
      {:ok, _room_id, pid} -> {this, delegate_to_server(pid, ctx, op, args)}
      {:error, reason} -> {:error, this, reason}
    end
  end


  #===========================================================================
  # Inline Operation Handling Functions
  #===========================================================================

  defp perform_inline(%Ctx{auth: nil} = ctx, _op, _args) do
    Ctx.failed(ctx, :forbidden)
  end

  defp perform_inline(ctx, ~o"chat.join" = op, %{name: name} = args) do
    # If we don't find the room pid we delegate to the manager process
    # to serialize the creation of the room processes
    case from_name(name) do
      {:error, _} -> delegate_to_manager(ctx, op, args)
      {:ok, _room_id, pid} ->
        try do
          delegate_to_server(pid, ctx, op, args)
        catch
          :exit, {:noproc, _} ->
            # Process died and we didn't update the lookup table yet
            delegate_to_manager(ctx, op, args)
        end
    end
  end

  defp perform_inline(ctx, op, %{room_id: id} = args) do
    case from_room_id(id) do
      {:error, reason} -> Ctx.failed(ctx, reason)
      {:ok, _name, pid} ->
        try do
          delegate_to_server(pid, ctx, op, args)
        catch
          :exit, {:noproc, _} ->
            # Process died and we didn't update the lookup table yet
            Ctx.failed(ctx, :room_not_found)
        end
    end
  end


  #===========================================================================
  # Internal Functions
  #===========================================================================

  defp initialise_tables() do
    :ets.new(@from_pid,
         [:set, :named_table, :protected,  {:keypos, 3},
          {:write_concurrency, false},
          {:read_concurrency, true}])
    :ets.new(@from_room_id,
         [:set, :named_table, :protected, {:keypos, 1},
          {:write_concurrency, false},
          {:read_concurrency, true}])
    :ets.new(@from_name,
         [:set, :named_table, :protected, {:keypos, 2},
          {:write_concurrency, false},
          {:read_concurrency, true}])
  end


  defp add_room(room_id, name, pid) do
    obj = {room_id, name, pid}
    :ets.insert(@from_pid, obj)
    :ets.insert(@from_room_id, obj)
    :ets.insert(@from_name, obj)
  end


  defp from_room_id(room_id) do
    case :ets.lookup(@from_room_id, room_id) do
      [{^room_id, username, pid}] -> {:ok, username, pid}
      _ -> {:error, :room_not_found}
    end
  end


  defp from_name(name) do
    case :ets.lookup(@from_name, name) do
      [{room_id, ^name, pid}] -> {:ok, room_id, pid}
      _ -> {:error, :room_not_found}
    end
  end


  defp delete_pid(pid) do
    case :ets.take(@from_pid, pid) do
      [{room_id, name, ^pid}] ->
        :ets.delete(@from_room_id, room_id)
        :ets.delete(@from_name, name)
        {:ok, room_id}
      _ -> {:error, :room_not_found}
    end
  end


  defp generate_room_id() do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64()
  end


  defp delegate_to_server(pid, ctx, op, args) do
    Server.perform(pid, ctx, op, args)
  end


  defp delegate_to_manager(ctx, op, args) do
    CvxGenServer.perform(@server_name, ctx, op, args)
  end


  defp start_link_server(name) do
    # Check again that the room wasn't created while the operation was inflight
    case from_name(name) do
      {:ok, room_id, pid} -> {:ok, room_id, pid}
      {:error, _} ->
        room_id = generate_room_id()
        case Supervisor.start_child(room_id, name) do
          {:error, reason} -> {:error, reason}
          {:ok, pid} ->
            try do
              Process.link(pid)
            catch
              :error, :noproc -> {:error, :internal_error}
            else
              _ ->
                add_room(room_id, name, pid)
                {:ok, room_id, pid}
            end
        end
    end
  end

end
