defmodule Centrex.Repo.Migrations.CreateChannels do
  use Ecto.Migration

  def change do
    create table(:channels, primary_key: false) do
      add :type, :string
      add :channel_id, :bigint

      timestamps()
    end

    create unique_index(:channels, [:type])
  end
end
