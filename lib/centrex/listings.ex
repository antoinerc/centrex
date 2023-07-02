defmodule Centrex.Listings do
  alias Centrex.Listings.Listing
  alias Centrex.Repo

  import Ecto.Query, warn: false
  import Ecto.Changeset

  def search_listings(address) do
    like = "%#{address}%"
    Repo.all(from l in Listing, where: ilike(l.address, ^like))
  end

  def get_listing(address) do
    Repo.get(Listing, address)
  end

  @spec track_listing(%{
          String.t() => String.t(),
          String.t() => String.t(),
          String.t() => String.t(),
          String.t() => String.t()
        }) ::
          {:new, %Listing{}}
          | {:updated, %Listing{}}
          | {:ok, %Listing{}}
          | {:error, Ecto.Changeset.t()}
  def track_listing(%{"address" => address, "price" => price, "link" => link, "type" => type}) do
    case get_listing(address) do
      nil -> track_new_listing(address, price, link, type)
      %{price_history: [^price | _], links_history: [^link | _]} = listing -> {:ok, listing}
      listing -> update_listing(listing, price, link)
    end
  end

  defp track_new_listing(address, price, link, type) do
    %Listing{}
    |> cast(
      %{
        "address" => address,
        "price_history" => [price],
        "links_history" => [link],
        "type" => type
      },
      [:price_history, :links_history, :address, :type],
      empty_value: ["", []]
    )
    |> validate_required([:price_history, :links_history, :address, :type])
    |> unique_constraint(:address, name: :listings_pkey)
    |> Repo.insert()
    |> case do
      {:ok, listing} -> {:new, listing}
      error -> error
    end
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
    |> cast(
      changes,
      [:price_history, :links_history]
    )
    |> validate_required([:price_history, :links_history, :address, :type])
    |> unique_constraint(:address, name: :listings_pkey)
    |> Repo.update()
    |> case do
      {:ok, listing} -> {:updated, listing}
      error -> error
    end
  end

  def associate_discord_thread(%Listing{} = listing, discord_thread) do
    listing
    |> cast(%{discord_thread: discord_thread}, [:discord_thread])
    |> unique_constraint(:discord_thread)
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
