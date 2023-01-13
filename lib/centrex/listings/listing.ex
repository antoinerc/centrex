defmodule Centrex.Listings.Listing do
  use Ecto.Schema

  @primary_key {:address, :string, autogenerate: false}
  schema "listings" do
    field(:favorite?, :boolean, default: false)
    field(:type, :string)
    field(:price_history, {:array, :string})
    field(:links_history, {:array, :string})

    timestamps()
  end
end
