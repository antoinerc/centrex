defmodule Centrex.Listings.ListingProcess do
  use GenServer, restart: :transient

  alias Centrex.Listings
  alias Centrex.Listings.Listing
  alias Centrex.ListingRegistry

  def start_link(%Listing{} = listing) do
    GenServer.start_link(__MODULE__, listing,
      name: {:via, Registry, {Centrex.ListingRegistry, listing.address}}
    )
  end

  def track(address, type, price, link) do
    with {:error, :not_found} <- ListingRegistry.lookup_property(address),
         {:ok, listing} <- Listings.track_listing(address, price, link, type) do
      Centrex.ListingSupervisor.add_listing_to_supervisor(listing)
      {:ok, listing}
    else
      {:ok, pid} ->
        GenServer.call(pid, {:update, price, link})

      error ->
        error
    end
  end

  @spec read(String.t()) :: Listing.t() | {:error, atom()}
  def read(address) do
    address
    |> ListingRegistry.lookup_property()
    |> case do
      {:ok, pid} -> GenServer.call(pid, :read)
      error -> error
    end
  end

  @impl true
  def init(%Listing{} = state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:read, _from, %Listing{} = state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:update, price, link}, _from, %Listing{} = state) do
    case Listings.update_listing(state, price, link) do
      {:ok, updated_listing} ->
        {:reply, {:updated, updated_listing}, updated_listing}

      {:error, :no_change} ->
        {:reply, {:no_change, state}, state}

      error ->
        {:reply, error, state}
    end
  end
end
