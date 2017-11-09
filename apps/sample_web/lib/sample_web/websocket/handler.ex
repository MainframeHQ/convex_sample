defmodule SampleWeb.Websocket.Handler do
  @moduledoc false

  @behaviour :cowboy_websocket_handler


  #===========================================================================
  # Includes
  #===========================================================================

  import Convex.Pipeline

  alias __MODULE__, as: This
  alias Convex.Handler.Process, as: Handler


  #===========================================================================
  # Types
  #===========================================================================

  @type t :: %This{
    handler: Handler.t,
    room_id: nil | :pending | String.t,
  }

  defstruct [
    :handler,
    :room_id
  ]


  #===========================================================================
  # Behaviour cowboy_web_socket Callback Functions
  #===========================================================================

  def init({:tcp, :http}, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end


  def websocket_init(_transport_name, req, _opts) do
    send(self(), :welcome)
    {:ok, req, %This{handler: Handler.new()}}
  end


  def websocket_handle({:text, ""}, req, this) do
    {:ok, req, this}
  end

  def websocket_handle({:text, packet}, req, this) do
    handle_command(String.trim(packet), this)
      |> handle_result(req)
  end

  def websocket_handle(:ping, req, this) do
    {:ok, req, this}
  end

  def websocket_handle({:pong, _}, req, this) do
    {:ok, req, this}
  end

  def websocket_handle(_frame, req, this) do
    {:shutdown, req, this}
  end


  def websocket_info(:welcome, req, this) do
    message = """
    Wecome to Convex's sample websocket text API.
    Commands:
      \\register USERNAME PASSWORD NAME NICK
      \\login USERNAME PASSWORD
      \\join ROOM_NAME
      \\post MESSAGE
      \\leave

    """
    {:reply, [{:text, message}], req, this}
  end

  def websocket_info(msg, req, this) do
    case Handler.handle_info(msg, this.handler) do
      {:ignored, handler} ->
        {:ok, req, %This{this | handler: handler}}
      {:ok, handler} ->
        {:ok, req, %This{this | handler: handler}}
      {:done, %{done: cb}, result, handler} ->
        cb.(result, %This{this | handler: handler})
          |> handle_result(req)
      {:failed, %{failed: cb}, reason, handler} ->
        cb.(reason, %This{this | handler: handler})
          |> handle_result(req)
      {:send, _ref, message, handler} ->
        handle_notif(message, %This{this | handler: handler})
          |> handle_result(req)
      {:shutdown, _reason, handler} ->
        # We don't care abaout shutdown requests
        {:ok, req, %This{this | handler: handler}}
    end
  end


  def websocket_terminate(_reason, _req, _this), do: :ok


  #===========================================================================
  # Internal Functions
  #===========================================================================

  defp handle_result(result, req) do
    case result do
      {:ok, this} -> {:ok, req, this}
      {:reply, msg, this} -> {:reply, [{:text, msg}], req, this}
    end
  end


  defp handle_command("\\register " <> rest, this) do
    case String.split(rest) do
      [username, password, name, nick] ->
        {:ok, register(username, password, name, nick, this)}
      _ -> {:reply, "**BAD COMMAND**", this}
    end
  end

  defp handle_command("\\login " <> rest, this) do
    case String.split(rest) do
      [username, password] ->
        {:ok, login(username, password, this)}
      _ -> {:reply, "**BAD COMMAND**", this}
    end
  end

  defp handle_command("\\join " <> name, this) do
    {:ok, join(name, this)}
  end

  defp handle_command("\\post " <> message, this) do
    {:ok, post(message, this)}
  end

  defp handle_command("\\leave", this) do
    {:ok, leave(this)}
  end

  defp handle_command(_command, this) do
    {:reply, "**BAD COMMAND**", this}
  end


  #---------------------------------------------------------------------------
  # Operations Functions
  #---------------------------------------------------------------------------

  defp register(username, password, name, nick, this) do
    params = %{done: &register_done/2, failed: &register_failed/2}
    {handler, ctx} = Handler.prepare(this.handler, nil, params)
    perform with: ctx do
      auth.register username: ^username, password: ^password
      directory.add id: ctx.auth, name: ^name, nick: ^nick
    end
    %This{this | handler: handler}
  end


  defp register_done(_result, this) do
    {:reply, "##AUTHENTICATED##", this}
  end


  defp register_failed(reason, this) do
    {:reply, "**REGISTRATION ERROR: #{inspect reason}**", this}
  end


  defp login(username, password, this) do
    params = %{done: &login_done/2, failed: &login_failed/2}
    {handler, ctx} = Handler.prepare(this.handler, nil, params)
    perform with: ctx do
      auth.login username: ^username, password: ^password
    end
    %This{this | handler: handler}
  end


  defp login_done(_result, this) do
    {:reply, "##AUTHENTICATED##", this}
  end


  defp login_failed(reason, this) do
    {:reply, "**LOGIN ERROR: #{inspect reason}**", this}
  end


  defp join(name, %This{room_id: nil} = this) do
    params = %{done: &join_done/2, failed: &join_failed/2}
    {handler, ctx} = Handler.prepare(this.handler, nil, params)
    perform with: ctx do
      room_id = chat.join name: ^name
    end
    %This{this | handler: handler, room_id: :pending}
  end

  defp join(_name, %This{room_id: :pending} = this) do
    {:reply, "**CURRENTLY JOINING/LEAVING**", this}
  end

  defp join(_name, this) do
    {:reply, "**ALREADY JOINED**", this}
  end


  defp join_done(room_id, this) do
    {:reply, "##ROOM JOINED##", history(10, %This{this | room_id: room_id})}
  end


  defp join_failed(reason, this) do
    {:reply, "**JOIN ERROR: #{inspect reason}**", this}
  end


  defp history(_size, %This{room_id: nil} = this) do
    {:reply, "**NOT JOINED**", this}
  end

  defp history(_size, %This{room_id: :pending} = this) do
    {:reply, "**CURRENTLY JOINING/LEAVING**", this}
  end

  defp history(size, %This{room_id: room_id} = this) do
    params = %{done: &history_done/2, failed: &history_failed/2}
    {handler, ctx} = Handler.prepare(this.handler, nil, params)
    perform with: ctx do
      {idx, ts, user_id, msg} =
        chat.produce.history room_id: ^room_id, size: ^size, bind: true
      %{nick: nick} = directory.lookup id: user_id
      {idx, ts, nick, msg}
    end
    %This{this | handler: handler}
  end


  defp history_done(history, this) do
    # The result is not ordered so we sort it on the message index
    sorted = Enum.sort_by(history, &(elem(&1, 0)))
    messages = for {_, _, nick, msg} <- sorted, do: "#{nick}: #{msg}"
    reply = "History:\n#{Enum.join(messages, "\n")}"
    {:reply, reply, this}
  end


  defp history_failed(reason, this) do
    {:reply, "**HISTORY ERROR: #{inspect reason}**", this}
  end


  defp post(_message, %This{room_id: nil} = this) do
    {:reply, "**NOT JOINED**", this}
  end

  defp post(_message, %This{room_id: :pending} = this) do
    {:reply, "**CURRENTLY JOINING/LEAVING**", this}
  end

  defp post(message, %This{room_id: room_id} = this) do
    params = %{done: &post_done/2, failed: &post_failed/2}
    {handler, ctx} = Handler.prepare(this.handler, nil, params)
    perform with: ctx do
      chat.post room_id: ^room_id, message: ^message
    end
    %This{this | handler: handler}
  end


  defp post_done(_result, this) do
    {:reply, "##POSTED##", this}
  end


  defp post_failed(reason, this) do
    {:reply, "**POST ERROR: #{inspect reason}**", this}
  end


  defp leave(%This{room_id: nil} = this) do
    {:reply, "**NOT JOINED**", this}
  end

  defp leave(%This{room_id: :pending} = this) do
    {:reply, "**CURRENTLY JOINING/LEAVING**", this}
  end

  defp leave(%This{room_id: room_id} = this) do
    params = %{done: &leave_done/2, failed: &leave_failed/2}
    {handler, ctx} = Handler.prepare(this.handler, nil, params)
    perform with: ctx do
      chat.leave room_id: ^room_id
    end
    %This{this | handler: handler, room_id: :pending}
  end


  defp leave_done(_result, this) do
    {:reply, "##LEFT##", %This{this | room_id: nil}}
  end


  defp leave_failed(reason, this) do
    {:reply, "**LEAVE ERROR: #{inspect reason}**", this}
  end


  #---------------------------------------------------------------------------
  # Notifications Functions
  #---------------------------------------------------------------------------

  defp handle_notif({:joined, user_id}, this) do
    resolve_nick this, user_id, fn nick, this ->
      {:reply, "##USER #{nick} JOINED##", this}
    end
  end

  defp handle_notif({:left, user_id}, this) do
    resolve_nick this, user_id, fn nick, this ->
      {:reply, "##USER #{nick} LEFT##", this}
    end
  end

  defp handle_notif({:posted, {_, _, user_id, msg}}, this) do
    resolve_nick this, user_id, fn nick, this ->
      {:reply, "#{nick}: #{msg}", this}
    end
  end


  defp resolve_nick(this, user_id, cb) do
    error_fun = fn reason, this ->
      {:reply, "**NICK RESOLUTION ERROR: #{inspect reason}**", this}
    end
    params = %{done: cb, failed: error_fun}
    {handler, ctx} = Handler.prepare(this.handler, nil, params)
    perform with: ctx do
      %{nick: nick} = directory.lookup id: ^user_id
      nick
    end
    {:ok, %This{this | handler: handler}}
  end

end
