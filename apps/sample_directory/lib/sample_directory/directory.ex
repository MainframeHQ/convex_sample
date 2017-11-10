defmodule SampleDirectory.Directory do
  @moduledoc false

  @behaviour Convex.Director


  #===========================================================================
  # Includes
  #===========================================================================

  import Convex.Sigils

  alias Convex.Context, as: Ctx


  #===========================================================================
  # Attributes
  #===========================================================================

  @id_to_profile :sample_directory_id_to_profile


  #===========================================================================
  # API Functions
  #===========================================================================

  def initialize() do
    :ets.new(@id_to_profile, [:named_table, :public, :set])
  end


  #===========================================================================
  # Behaviour Convex.Director
  #===========================================================================

  def perform(%Ctx{auth: nil} = ctx, _op, _args) do
    Ctx.failed(ctx, :forbidden)
  end

  def perform(ctx, ~o"directory.add", %{id: id, name: name, nick: nick}) do
    case directory_add(id, name, nick) do
      {:error, reason} -> Ctx.failed(ctx, reason)
      {:ok, result} -> Ctx.done(ctx, result)
    end
  end

  def perform(ctx, ~o"directory.lookup", %{id: id}) do
    case directory_lookup(id) do
      {:error, reason} -> Ctx.failed(ctx, reason)
      {:ok, profile} -> Ctx.done(ctx, profile)
    end
  end


  #===========================================================================
  # Internal Functions
  #===========================================================================

  defp directory_add(id, name, nick) do
    case :ets.lookup(@id_to_profile, id) do
      [_] -> {:error, :already_exists}
      [] ->
        profile = %{name: name, nick: nick}
        :ets.insert(@id_to_profile, {id, profile})
        {:ok, profile}
    end
  end


  def directory_lookup(id) do
    case :ets.lookup(@id_to_profile, id) do
      [] -> {:error, :not_found}
      [{_id, profile}] -> {:ok, profile}
    end
  end

end