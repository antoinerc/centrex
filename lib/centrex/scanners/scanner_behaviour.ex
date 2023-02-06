defmodule Centrex.Scanners.Scanner do
  @callback get_address_from_page(html_page :: list(tuple())) :: String.t()
  @callback get_type_from_page(html_page :: list(tuple())) :: String.t()
  @callback get_price_from_page(html_page :: list(tuple())) :: String.t()
end
