defmodule Centrex.Listings do
  alias Centrex.Listings.Listing
  alias Centrex.Repo

  import Ecto.Query, warn: false

  def search_listings(address) do
    like = "%#{address}%"
    Repo.all(from l in Listing, where: ilike(l.address, ^like))
  end

  def get_listing(address) do
    Repo.get(Listing, address)
  end

  def track_listing(address, price, link, type) do
    %Listing{}
    |> Ecto.Changeset.cast(
      %{
        "address" => address,
        "price_history" => [price],
        "links_history" => [link],
        "type" => type
      },
      [:price_history, :links_history, :address, :type],
      empty_value: ["", []]
    )
    |> Ecto.Changeset.validate_required([:price_history, :links_history, :address, :type])
    |> Ecto.Changeset.unique_constraint(:address, name: :listings_pkey)
    |> Repo.insert()
  end

  def update_listing(
        %Listing{price_history: price_history, links_history: links_history} = listing,
        price,
        link
      ) do
    changes =
      %{}
      |> add_price(price_history, price)
      |> add_link(links_history, link)

    listing
    |> Ecto.Changeset.cast(
      changes,
      [:price_history, :links_history]
    )
    |> Ecto.Changeset.validate_required([:price_history, :links_history, :address, :type])
    |> Ecto.Changeset.unique_constraint(:address, name: :listings_pkey)
    |> Repo.update()
  end

  defp add_price(changes, [new_price | _], new_price), do: changes

  defp add_price(changes, prices, new_price),
    do: Map.put(changes, :price_history, [new_price | prices])

  defp add_link(changes, [new_link | _], new_link), do: changes

  defp add_link(changes, links, new_link),
    do: Map.put(changes, :links_history, [new_link | links])

  def create_changeset(%Listing{} = listing, attrs \\ %{}) do
    listing
    |> Ecto.Changeset.cast(attrs, [:price_history, :links_history, :address])
    |> Ecto.Changeset.validate_required([:price_history, :links_history, :address])
    |> Ecto.Changeset.apply_action(:insert)
  end
end
