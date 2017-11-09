defmodule Sample do
  @moduledoc false

  #===========================================================================
  # Includes
  #===========================================================================

  use Convex.Director


  #===========================================================================
  # Director Routing
  #===========================================================================

  def delegate("auth.*"), do: SampleAuth
  def delegate("directory.*"), do: SampleDirectory
  def delegate("chat.*"), do: SampleChat

end