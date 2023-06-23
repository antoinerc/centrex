defmodule Centrex.Scanner do
  alias Centrex.Scanners

  @spec scan(url :: String.t()) :: %{
          address: String.t(),
          type: String.t(),
          price: String.t(),
          link: String.t()
        }
  def scan(url) do
    url
    |> get_listing_page()
    |> get_listing_details(url)
  end

  defp get_listing_page(url) do
    %{body: body} = HTTPoison.get!(url, timeout: 50_000, recv_timeout: 50_000)

    body
  end

  defp get_listing_details(page, url) do
    parsed_page = Floki.parse_document!(page)

    scanner =
      case get_provider(url) do
        "centris" -> Scanners.CentrisScanner
        "duproprio" -> Scanners.DuproprioScanner
        provider -> raise ArgumentError, message: "Unrecognized provider #{provider}"
      end

    %{
      address: scanner.get_address_from_page(parsed_page),
      type: scanner.get_type_from_page(parsed_page),
      price: scanner.get_price_from_page(parsed_page),
      link: url
    }
  end

  defp get_provider(url) do
    case Regex.run(~r/https:\/\/w*\.?([a-z]*).[a-z]*/, url) do
      [_, provider] -> provider
      nil -> raise ArgumentError, message: "Invalid URL format"
    end
  end
end
