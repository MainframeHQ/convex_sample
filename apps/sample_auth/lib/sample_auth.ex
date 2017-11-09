defmodule SampleAuth do
  @moduledoc false

  #===========================================================================
  # Includes
  #===========================================================================

  use Convex.Director


  #===========================================================================
  # Convex.Director Routing
  #===========================================================================

  def delegate("*"), do: SampleAuth.Server

  def validate("auth.register", %{username: u, password: p})
    when is_binary(u) and is_binary(p), do: :ok

  def validate("auth.login", %{username: u, password: p})
    when is_binary(u) and is_binary(p), do: :ok

end
