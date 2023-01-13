defmodule Centrex.ListingSupervisor do
  use DynamicSupervisor

  alias Centrex.Listings.{Listing, ListingProcess}

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_listing_to_supervisor(%Listing{} = listing) do
    child_spec = %{
      id: ListingProcess,
      start: {ListingProcess, :start_link, [listing]},
      restart: :transient
    }

    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def all_listing_pids do
    __MODULE__
    |> DynamicSupervisor.which_children()
    |> Enum.reduce([], fn {_, listing_pid, _, _}, acc -> [listing_pid | acc] end)
  end
end
