defmodule SampleDirectory do
  @moduledoc false


  #===========================================================================
  # Includes
  #===========================================================================

  use Convex.Director


  #===========================================================================
  # Convex.Director Routing
  #===========================================================================

  def delegate("*"), do: SampleDirectory.Directory


  def validate("directory.add", %{id: id, name: n, nick: a})
    when is_binary(id) and is_binary(n) and is_binary(a), do: :ok

  def validate("directory.lookup", %{id: id})
    when is_binary(id), do: :ok

end
