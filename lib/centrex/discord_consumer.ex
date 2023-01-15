defmodule Centrex.DiscordConsumer do
  use Nostrum.Consumer
  alias Nostrum.Api

  alias Nostrum.Struct
  alias Centrex.Commands
  alias Centrex.Listings

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

  defp manage_track_listing(%Struct.Interaction{data: data, channel_id: channel_id} = interaction) do
    %{
      options: [
        %{name: "type", value: type},
        %{name: "address", value: address},
        %{name: "price", value: price},
        %{name: "link", value: link}
      ]
    } = data

    [discord_thread, response] =
      case Listings.get_listing(address) do
        %Listings.Listing{
          address: ^address,
          type: ^type,
          price_history: [^price | _],
          links_history: [^link | _]
        } = listing ->
          discord_thread = get_discord_thread(listing, channel_id)
          [discord_thread, nil]

        %Listings.Listing{} = listing ->
          {:ok,
           %Listings.Listing{
             address: address,
             price_history: [current_price | past_price],
             links_history: [link | _]
           } = listing} = Listings.update_listing(listing, price, link)

          response =
            "**UPDATED LISTING**\n**#{address}**\nPrice history: **#{current_price}$**#{Enum.map(past_price, &", #{&1}$")} \nLatest link: #{link}\n"

          discord_thread = get_discord_thread(listing, channel_id)

          [discord_thread, response]

        nil ->
          {:ok,
           %Listings.Listing{
             address: address,
             price_history: [current_price | past_price],
             links_history: [link | _]
           } = listing} = Listings.track_listing(address, price, link, type)

          response =
            "**NEW LISTING**\n**#{address}**\nPrice history: **#{current_price}$**#{Enum.map(past_price, &", #{&1}$")} \nLatest link: #{link}\n"

          {:ok, %{id: thread_id}} =
            Api.start_thread(channel_id, %{name: address, type: 11, auto_archive_duration: 10080})

          Listings.associate_discord_thread(listing, thread_id)

          [thread_id, response]
      end

    Api.create_interaction_response(interaction, %{
      type: 4,
      data: %{content: "Here is your listing: #{%Struct.Channel{id: discord_thread}}"}
    })

    if not is_nil(response) do
      Api.create_message!(discord_thread, %{content: response})
    end
  end

  defp manage_search_listing(%Struct.Interaction{data: data} = interaction) do
    [%{value: address}] = data.options

    response =
      case Listings.search_listings(address) do
        [] ->
          "No listing found"

        listings ->
          Enum.reduce(listings, "Found #{Enum.count(listings)} listings\n", fn
            %{
              address: address,
              price_history: [current_price | past_prices],
              links_history: [latest_link | _]
            },
            acc ->
              "#{acc}**#{address}**\nPrice history: **#{current_price}$**#{Enum.map(past_prices, &", #{&1}$")} \nLatest link: #{latest_link}\n"
          end)
      end

    Api.create_interaction_response(interaction, %{type: 4, data: %{content: response}})
  end

  defp get_discord_thread(%Listings.Listing{discord_thread: nil, address: address}, channel_id) do
    {:ok, %{id: thread}} =
      Api.start_thread(channel_id, %{
        name: address,
        type: 11,
        auto_archive_duration: 10080
      })

    thread
  end

  defp get_discord_thread(%Listings.Listing{discord_thread: thread}, _channel_id) do
    thread
  end
end
