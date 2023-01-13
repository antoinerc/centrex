defmodule Centrex.Repo.Migrations.CreateListing do
  use Ecto.Migration

  def change do
    create table(:listings, primary_key: false) do
      add :address, :string, primary_key: true
      add :type, :string
      add :favorite?, :boolean
      add :price_history, {:array, :string}
      add :links_history, {:array, :string}
      timestamps()
    end

    create unique_index(:listings, [:address])
  end
end
