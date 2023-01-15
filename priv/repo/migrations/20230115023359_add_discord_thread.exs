defmodule Centrex.Repo.Migrations.AddDiscordThread do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :discord_thread, :bigint, default: nil
    end
  end
end
