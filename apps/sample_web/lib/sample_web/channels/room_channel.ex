defmodule SampleWeb.RoomChannel do

  #===========================================================================
  # Includes
  #===========================================================================

  use SampleWeb, :channel

  import Convex.Pipeline

  alias Phoenix.Channel
  alias SampleWeb.Proxy
  alias Convex.Context.Sync
  alias Convex.Context.Async


  #===========================================================================
  # API Functions
  #===========================================================================

  def join("rooms:" <> room_name, _msg, socket) do
    ctx = sync_context(socket)
      with {:ok, room_id} <- do_join(ctx, room_name),
         {:ok, history} <- do_history(ctx, room_id) do
      Enum.each(history, fn item -> send(self(), {:posted, item}) end)
      {:ok, assign(socket, :room_id, room_id)}
    end
  end


  def handle_info({:posted, {_, _, user_id, msg}}, socket) do
    nick = user_nick(sync_context(socket), user_id)
    Channel.push(socket, "posted", %{nick: nick, body: msg})
    {:noreply, socket}
  end

  def handle_info({:joined, user_id}, socket) do
    nick = user_nick(sync_context(socket), user_id)
    Channel.push(socket, "joined", %{nick: nick})
    {:noreply, socket}
  end

  def handle_info({:left, user_id}, socket) do
    nick = user_nick(sync_context(socket), user_id)
    Channel.push(socket, "left", %{nick: nick})
    {:noreply, socket}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end


  def terminate(_reason, _socket) do
    :ok
  end


  def handle_in("posted", data, socket) do
    {:reply, {:posted, data}, socket}
  end

  def handle_in("joined", data, socket) do
    {:reply, {:left, data}, socket}
  end

  def handle_in("left", data, socket) do
    {:reply, {:left, data}, socket}
  end

  def handle_in("post", %{"message" => msg}, socket) do
    ctx = async_context(socket)
    nick = socket.assigns.profile.nick
    do_post(ctx, socket.assigns.room_id, msg)
    Channel.push(socket, "posted", %{nick: nick, body: msg})
    {:noreply, socket}
  end


  #===========================================================================
  # Internal Functions
  #===========================================================================

  def sync_context(socket) do
    base_ctx = socket.assigns.context
    pid = self()
    binder_fun = fn _ctx -> Proxy.new(pid) end
    Sync.recast(base_ctx, binder: binder_fun)
  end


  def async_context(socket) do
    base_ctx = socket.assigns.context
    Async.recast(base_ctx)
  end


  defp do_join(ctx, name) do
    perform ctx, do: chat.join(name: ^name)
  end


  defp do_history(ctx, room_id) do
    perform with: ctx do
      chat.produce.history room_id: ^room_id, size: 10, bind: true
    else
      {:error, _reason} = error -> error
      {:ok, history} -> {:ok, Enum.sort_by(history, &(elem(&1, 0)))}
    end
  end


  defp do_post(ctx, room_id, msg) do
    perform with: ctx do
      chat.post room_id: ^room_id, message: ^msg
    end
  end


  defp user_nick(ctx, user_id) do
    perform! with: ctx do
      %{nick: nick} = directory.lookup id: ^user_id
      nick
    end
  end

end
