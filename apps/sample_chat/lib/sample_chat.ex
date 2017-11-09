defmodule SampleChat do
  @moduledoc false

  #===========================================================================
  # Includes
  #===========================================================================

  use Convex.Director


  #===========================================================================
  # Convex.Director Routing
  #===========================================================================

  def delegate("*"), do: SampleChat.Manager

  def validate("chat.join", %{name: n})
    when is_binary(n), do: :ok

  def validate("chat.produce.history", %{room_id: id, size: s, bind: b})
    when is_binary(id) and is_integer(s) and is_boolean(b), do: :ok

  def validate("chat.produce.history", %{room_id: id, size: s})
    when is_binary(id) and is_integer(s) do
      %{room_id: id, size: s, bind: false}
  end

  def validate("chat.leave", %{room_id: id})
    when is_binary(id), do: :ok

  def validate("chat.produce.participants", %{room_id: id})
    when is_binary(id), do: :ok

  def validate("chat.post", %{room_id: id, message: msg})
    when is_binary(id) and is_binary(msg), do: :ok

end
