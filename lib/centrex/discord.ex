defmodule Centrex.Discord do
  @moduledoc """
  The Discord context.
  """

  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Centrex.Repo

  alias Centrex.Discord.Channel

  @spec set_channel(String.t(), Float.t()) :: {:ok, Channel.t()} | {:error, :reason}
  def set_channel(type, channel_id) do
    %Channel{}
    |> cast(%{type: type, channel_id: channel_id}, [:type, :channel_id])
    |> validate_required([:channel_id, :type])
    |> unique_constraint(:type, name: :type_pkey)
    |> Repo.insert()
  end

  @spec get_by_channel(Integer.t()) :: Channel.t() | nil
  def get_by_channel(channel_id) do
    Repo.get_by(Channel, channel_id: channel_id)
  end
end
