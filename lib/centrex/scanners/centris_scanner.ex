defmodule Centrex.Scanners.CentrisScanner do
  @behaviour Centrex.Scanners.Scanner

  def get_type_from_page(parsed_page) do
    parsed_page
    |> Floki.find("span[data-id=\"PageTitle\"]")
    |> List.first()
    |> Floki.text()
    |> get_type()
  end

  def get_address_from_page(parsed_page) do
    parsed_page
    |> Floki.find("h2[itemprop=\"address\"]")
    |> List.first()
    |> Floki.text()
  end

  def get_price_from_page(parsed_page) do
    parsed_page
    |> Floki.find("span#BuyPrice")
    |> List.first()
    |> Floki.text()
  end

  defp get_type(type) do
    type = String.downcase(type)

    if String.contains?(String.downcase(type), ["maison", "house"]) do
      "house"
    else
      "condo"
    end
  end
end
