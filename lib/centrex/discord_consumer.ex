defmodule Centrex.DiscordConsumer do
  use Nostrum.Consumer
  alias Nostrum.Api

  alias Nostrum.Struct
  alias Centrex.Commands
  alias Centrex.Listings
  alias Centrex.Listings.ListingProcess

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:READY, %{guilds: [guild]}, _ws_state}) do
    Api.bulk_overwrite_guild_application_commands(guild.id, Commands.all())
  end

  def handle_event(
        {:INTERACTION_CREATE, %Struct.Interaction{data: %{name: "track"}} = interaction,
         _ws_state}
      ) do
    manage_track_listing(interaction)
  end

  def handle_event(
        {:INTERACTION_CREATE, %Struct.Interaction{data: %{name: "search"}} = interaction,
         _ws_state}
      ) do
    manage_search_listing(interaction)
  end

  def handle_event(_event) do
    :noop
  end

  defp manage_track_listing(%Struct.Interaction{data: data} = interaction) do
    %{
      options: [
        %{name: "type", value: type},
        %{name: "address", value: address},
        %{name: "price", value: price},
        %{name: "link", value: link}
      ]
    } = data

    response =
      case ListingProcess.track(address, type, price, link) do
        {:ok,
         %Listings.Listing{price_history: [current_price | past_price], links_history: [link | _]}} ->
          "**NEW LISTING**\n**#{address}**\nPrice history: **#{current_price}$**#{Enum.map(past_price, &", #{&1}$")} \nLatest link: #{link}\n"

        {:no_change,
         %Listings.Listing{price_history: [current_price | past_price], links_history: [link | _]}} ->
          "Found an existing listing for\n**#{address}**\nPrice history: **#{current_price}$**#{Enum.map(past_price, &", #{&1}$")} \nLatest link: #{link}\n"

        {:updated,
         %Listings.Listing{price_history: [current_price | past_price], links_history: [link | _]}} ->
          "**UPDATED LISTING**\n**#{address}**\nPrice history: **#{current_price}$**#{Enum.map(past_price, &", #{&1}$")} \nLatest link: #{link}\n"
      end

    Api.create_interaction_response(interaction, %{type: 4, data: %{content: response}})
  end

  defp manage_search_listing(%Struct.Interaction{data: data} = interaction) do
    [%{value: address}] = data.options

    response =
      case ListingProcess.read(address) do
        %Centrex.Listings.Listing{
          address: address,
          price_history: [current_price | past_price],
          links_history: [link | _]
        } ->
          "**#{address}**\nPrice history: **#{current_price}$**#{Enum.map(past_price, &", #{&1}$")} \nLatest link: #{link}\n"

        _ ->
          "No listing found with address #{address}"
      end

    Api.create_interaction_response(interaction, %{type: 4, data: %{content: response}})
  end
end
