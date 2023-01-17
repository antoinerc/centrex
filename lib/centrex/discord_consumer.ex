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
    |> IO.inspect()
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

  def handle_event(
        {:INTERACTION_CREATE, %Struct.Interaction{data: %{name: "set_channel"}} = interaction,
         _ws_state}
      ) do
    manage_set_channel(interaction)
  end

  def handle_event(_event) do
    :noop
  end

  defp manage_track_listing(
         %Struct.Interaction{data: %{options: options}, channel_id: channel_id} = interaction
       ) do
    case parse_options(options, channel_id) do
      {:ok, %{address: address} = parsed_options} ->
        listing = Listings.get_listing(address)

        case listing do
          nil ->
            manage_new_listing(parsed_options, interaction)

          %{address: ^address} ->
            manage_existing_listing(listing, parsed_options, interaction)
        end

      {:error, :type_inferance_error} ->
        reply_to_interaction(interaction, "Unable to infer listing type.")
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
    reply_to_interaction(interaction, response)
  end

  defp manage_set_channel(
         %Struct.Interaction{channel_id: channel_id, data: %{options: [%{value: type}]}} =
           interaction
       ) do
    Centrex.Discord.set_channel(type, channel_id)
    reply_to_interaction(interaction, "Channel type set")
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

  defp parse_options(
         [
           %{name: "address", value: address},
           %{name: "price", value: price},
           %{name: "link", value: link}
         ],
         channel_id
       ) do
    %{type: type} = Centrex.Discord.get_by_channel(channel_id)

    case type do
      nil ->
        {:error, :type_inferance_error}

      type ->
        {:ok, %{address: address, price: price, link: link, type: type}}
    end
  end

  defp parse_options(
         [
           %{name: "address", value: address},
           %{name: "price", value: price},
           %{name: "link", value: link},
           %{name: "type", value: type}
         ],
         _
       ) do
       IO.inspect(type)
    {:ok, %{address: address, price: price, link: link, type: type}}
  end

  defp reply_to_interaction(interaction, message) do
    Api.create_interaction_response(interaction, %{
      type: 4,
      data: %{content: message}
    })
  end

  defp manage_new_listing(%{address: address, type: type, price: price, link: link}, interaction) do
    {:ok,
     %Listings.Listing{
       address: address,
       price_history: [current_price | past_price],
       links_history: [link | _]
     } = listing} = Listings.track_listing(address, price, link, type)

    response =
      "**NEW LISTING**\n**#{address}**\nPrice history: **#{current_price}$**#{Enum.map(past_price, &", #{&1}$")} \nLatest link: #{link}\n"

    {:ok, %{id: thread_id}} =
      Api.start_thread(interaction.channel_id, %{
        name: address,
        type: 11,
        auto_archive_duration: 10080
      })

    Listings.associate_discord_thread(listing, thread_id)

    reply_to_interaction(
      interaction,
      "Here is your listing: #{%Struct.Channel{id: thread_id}}"
    )

    Api.create_message!(thread_id, %{content: response})
  end

  defp manage_existing_listing(
         %{price_history: [new_price | _], links_history: [new_link | _]} = listing,
         %{price: new_price, link: new_link},
         interaction
       ) do
    discord_thread = get_discord_thread(listing, interaction.channel_id)

    reply_to_interaction(
      interaction,
      "Here is your listing: #{%Struct.Channel{id: discord_thread}}"
    )
  end

  defp manage_existing_listing(listing, %{price: new_price, link: new_link}, interaction) do
    {:ok,
     %{address: address, price_history: [current_price | past_price], links_history: [link | _]} =
       listing} = Listings.update_listing(listing, new_price, new_link)

    response =
      "**UPDATED LISTING**\n**#{address}**\nPrice history: **#{current_price}$**#{Enum.map(past_price, &", #{&1}$")} \nLatest link: #{link}\n"

    discord_thread = get_discord_thread(listing, interaction.channel_id)

    reply_to_interaction(
      interaction,
      "Here is your listing: #{%Struct.Channel{id: discord_thread}}"
    )

    Api.create_message!(discord_thread, %{content: response})
  end
end
