defmodule Centrex.Replies do
  def new_listing(%{
        address: address,
        links_history: [latest_link | _],
        price_history: [latest_price | _]
      }),
      do:
        "**NEW LISTING**\n**#{address}**\nPrice history: **#{latest_price}$**\nLatest link: #{latest_link}\n"

  def updated_listing(%{
        address: address,
        price_history: [current_price | past_prices],
        links_history: [link | _]
      }),
      do:
        "**UPDATED LISTING**\n**#{address}**\nPrice history: **#{current_price}$**#{Enum.map(past_prices, &", #{&1}$")} \nLatest link: #{link}\n"
end
