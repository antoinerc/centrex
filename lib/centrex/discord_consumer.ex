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

  def handle_event(
        {:INTERACTION_CREATE, %Struct.Interaction{data: %{name: "set_channel"}} = interaction,
         _ws_state}
      ) do
    manage_set_channel(interaction)
  end

  def handle_event(
        {:INTERACTION_CREATE, %Struct.Interaction{data: %{name: "scan"}} = interaction, _ws_state}
      ) do
    manage_scan_listing(interaction)
  end

  def handle_event(_event) do
    :noop
  end

  defp manage_track_listing(
         %Struct.Interaction{data: %{options: options}, channel_id: channel_id} = interaction
       ) do
    case parse_options(options, channel_id) do
      {:ok, parsed_options} ->
        parsed_options
        |> Listings.track_listing()
        |> reply_tracking(interaction)

        cleanup(interaction)

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

  defp parse_options(
         [
           %{name: "address", value: address},
           %{name: "price", value: price},
           %{name: "link", value: link}
         ],
         channel_id
       ) do
    type = Centrex.Discord.get_by_channel(channel_id)

    case type do
      nil ->
        {:error, :type_inferance_error}

      %{type: type} ->
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
    {:ok, %{address: address, price: price, link: link, type: type}}
  end

  defp reply_to_interaction(interaction, message) do
    Api.create_interaction_response(interaction, %{
      type: 4,
      data: %{content: message}
    })
  end

  defp manage_scan_listing(%Struct.Interaction{data: %{options: options}} = interaction) do
    [%{name: "link", value: link}] = options

    link
    |> Centrex.Scanner.scan()
    |> Listings.track_listing()
    |> reply_tracking(interaction)

    cleanup(interaction)
  end

  defp create_thread(%{guild_id: guild_id, channel_id: channel_id}, listing) do
    {:ok, %{id: thread_id}} = Api.start_thread(channel_id, %{name: listing.address, type: 11})

    guild_id
    |> Api.list_guild_members!(limit: 5)
    |> Enum.each(&Api.add_thread_member(thread_id, &1.user.id))

    Listings.associate_discord_thread(listing, thread_id)
    {:ok, thread_id}
  end

  def reply_tracking(
        {:new,
         %{
           address: address,
           price_history: [current_price | past_prices],
           links_history: [link | _]
         } = listing},
        interaction
      ) do
    {:ok, thread_id} = create_thread(interaction, listing)

    Api.create_message!(thread_id, %{
      content:
        "**NEW LISTING**\n**#{address}**\nPrice history: **#{current_price}$**#{Enum.map(past_prices, &", #{&1}$")} \nLatest link: #{link}\n"
    })
  end

  def reply_tracking(
        {:updated,
         %{
           address: address,
           price_history: [current_price | past_prices],
           links_history: [link | _],
           discord_thread: discord_thread
         }},
        _interaction
      ) do
    Api.create_message!(discord_thread, %{
      content:
        "**UPDATED LISTING**\n**#{address}**\nPrice history: **#{current_price}$**#{Enum.map(past_prices, &", #{&1}$")} \nLatest link: #{link}\n"
    })
  end

  def reply_tracking(
        {:ok,
         %{
           discord_thread: discord_thread
         }},
        _interaction
      ) do
    Api.create_message!(discord_thread, %{
      content: "Here is your listing: #{%Struct.Channel{id: discord_thread}}"
    })
  end

  def reply_tracking({:error, _error}, interaction) do
    reply_to_interaction(
      interaction,
      "An error occured while tracking the listing"
    )
  end

  def cleanup(interaction) do
    reply_to_interaction(
      interaction,
      "Ok"
    )

    Api.delete_interaction_response(interaction)
  end
end
