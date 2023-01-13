defmodule Centrex.ListingRegistry do
  def child_spec do
    Registry.child_spec(
      keys: :unique,
      name: __MODULE__,
      partitions: System.schedulers_online()
    )
  end

  def lookup_property(property_id) do
    key =
      property_id
      |> format_address()
      |> find_address_key()

    case Registry.lookup(__MODULE__, key) do
      [{property_id, _}] -> {:ok, property_id}
      [] -> {:error, :not_found}
    end
  end

  defp find_address_key(address) do
    Registry.select(__MODULE__, [{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.find(&String.contains?(format_address(&1), address))
  end

  defp format_address(address) do
    address
    |> String.trim()
    |> String.downcase()
    |> String.replace(",", "")
  end
end
