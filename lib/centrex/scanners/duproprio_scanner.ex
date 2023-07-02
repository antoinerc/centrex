defmodule Centrex.Scanners.DuproprioScanner do
  @behaviour Centrex.Scanners.Scanner

  def get_type_from_page(parsed_page) do
    parsed_page
    |> Floki.find("title")
    |> List.first()
    |> Floki.text()
    |> get_type()
  end

  def get_address_from_page(parsed_page) do
    parsed_page
    |> Floki.find("div.listing-location__address")
    |> List.first()
    |> Floki.children()
    |> Floki.text(sep: ", ")
  end

  def get_price_from_page(parsed_page) do
    parsed_page
    |> Floki.find("div.listing-price__amount")
    |> List.first()
    |> Floki.text()
    |> String.replace("$", "")
    |> String.trim()
  end

  defp get_type(type) do
    type
    |> String.downcase()
    |> String.contains?("condo")
    |> case do
      true -> "condo"
      _ -> "house"
    end
  end
end
