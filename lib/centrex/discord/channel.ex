defmodule Centrex.Discord.Channel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:type, :string, autogenerate: false}
  schema "channels" do
    field(:channel_id, :float, default: nil)
    timestamps()
  end

  @doc false
  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:channel_id, :type])
    |> validate_required([:id, :type])
    |> unique_constraint(:type, name: :type_pkey)
  end
end
