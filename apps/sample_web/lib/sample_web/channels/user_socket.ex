defmodule SampleWeb.UserSocket do

  #===========================================================================
  # Includes
  #===========================================================================

  use Phoenix.Socket

  import Convex.Pipeline

  alias Convex.Context.Sync


  #===========================================================================
  # Channel API
  #===========================================================================

  transport :websocket, Phoenix.Transports.WebSocket

  channel "rooms:*", SampleWeb.RoomChannel


  def connect(%{"token" => token} = params, socket) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
      {:error, _reason} -> :error
      {:ok, user_id} ->
        case setup_context(user_id) do
          {:error, _reason} -> :error
          {:ok, {ctx, profile}} ->
            socket =
              socket
              |> assign(:profile, profile)
              |> assign(:context, ctx)
            {:ok, socket}
        end
    end
  end


  def id(_socket), do: nil


  #===========================================================================
  # Internal Functinos
  #===========================================================================

  defp setup_context(user_id) do
    perform with: Sync.new(), as: user_id do
      profile = directory.lookup id: ^user_id
      {ctx, profile}
    end
  end

end
