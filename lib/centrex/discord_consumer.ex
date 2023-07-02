defmodule Centrex.DiscordConsumer do
  use Nostrum.Consumer
  alias Nostrum.Struct.Channel
  alias Nostrum.Api

  alias Nostrum.Struct
  alias Centrex.Commands
  alias Centrex.Listings

  def handle_event({:READY, %{guilds: [guild]}, _ws_state}) do
    Api.bulk_overwrite_guild_application_commands(guild.id, Commands.all())
  end

  def handle_event(
        {:INTERACTION_CREATE, %Struct.Interaction{data: %{name: "track"}} = interaction,
         _ws_state}
      ) do
    Api.create_interaction_response!(interaction, %{type: 5, data: %{flags: 64}})
    manage_track_listing(interaction)
  end

  def handle_event(
        {:INTERACTION_CREATE, %Struct.Interaction{data: %{name: "search"}} = interaction,
         _ws_state}
      ) do
    Api.create_interaction_response!(interaction, %{type: 5, data: %{flags: 64}})
    manage_search_listing(interaction)
  end

  def handle_event(
        {:INTERACTION_CREATE, %Struct.Interaction{data: %{name: "set_channel"}} = interaction,
         _ws_state}
      ) do
    Api.create_interaction_response!(interaction, %{type: 5, data: %{flags: 64}})
    manage_set_channel(interaction)
  end

  def handle_event(
        {:INTERACTION_CREATE, %Struct.Interaction{data: %{name: "unset_channel"}} = interaction,
         _ws_state}
      ) do
    Api.create_interaction_response!(interaction, %{type: 5, data: %{flags: 64}})
    manage_unset_channel(interaction)
  end

  def handle_event(
        {:INTERACTION_CREATE, %Struct.Interaction{data: %{name: "scan"}} = interaction, _ws_state}
      ) do
    Api.create_interaction_response!(interaction, %{type: 5, data: %{flags: 64}})
    manage_scan_listing(interaction)
  end

  def handle_event(_event) do
    :noop
  end

  defp manage_track_listing(%Struct.Interaction{data: %{options: options}} = interaction) do
    options
    |> Enum.reduce(%{}, fn %{name: name, value: value}, acc ->
      Map.put(acc, name, value)
    end)
    |> Listings.track_listing()
    |> reply(interaction)
  end

  defp manage_scan_listing(
         %Struct.Interaction{data: %{options: [%{name: "link", value: link}]}} = interaction
       ) do
    link
    |> Centrex.Scanner.scan()
    |> Listings.track_listing()
    |> reply(interaction)
  end

  defp reply({:ok, %{discord_thread: discord_thread}}, interaction) do
    Api.edit_interaction_response(interaction, %{
      content: "Here is your listing thread #{%Struct.Channel{id: discord_thread}}"
    })
  end

  defp reply({:new, %Listings.Listing{} = listing}, interaction) do
    with %{channel_id: channel_id} <- Centrex.Discord.get_by_type(listing.type),
         {:ok, channel} <-
           Api.start_thread_in_forum_channel(channel_id, %{
             name: listing.address,
             message: %{content: Centrex.Replies.new_listing(listing)}
           }),
         {:ok, listing} <- Centrex.Listings.associate_discord_thread(listing, channel.id) do
      reply({:ok, listing}, interaction)
    else
      _ -> reply({:error, "Something happened"}, interaction)
    end
  end

  defp reply({:updated, %Listings.Listing{discord_thread: discord_thread} = listing}, interaction) do
    Api.create_message!(discord_thread, %{
      content: Centrex.Replies.updated_listing(listing)
    })

    reply({:ok, listing}, interaction)
  end

  defp reply({:error, _error}, interaction) do
    Api.edit_interaction_response(
      interaction,
      %{content: "An error happened when trying to track the listing."}
    )
  end

  defp manage_search_listing(
         %Struct.Interaction{data: %{options: [%{value: address}]}} = interaction
       ) do
    response =
      case Listings.search_listings(address) do
        [] ->
          "No listing found"

        listings ->
          Enum.reduce(listings, "Found #{Enum.count(listings)} listings\n", fn %{
                                                                                 discord_thread:
                                                                                   thread
                                                                               },
                                                                               acc ->
            "#{acc}#{%Struct.Channel{id: thread}}\n"
          end)
      end

    Api.edit_interaction_response(
      interaction,
      %{content: response}
    )
  end

  defp manage_set_channel(
         %Struct.Interaction{data: %{options: [%{value: type}, %{value: channel_id}]}} =
           interaction
       ) do
    case Centrex.Discord.set_channel(type, channel_id) do
      {:ok, _} ->
        reply_to_interaction(
          interaction,
          "Channel type #{type} associated with channel #{%Channel{id: channel_id}}"
        )

      {:error, _} ->
        reply_to_interaction(
          interaction,
          "Channel type #{type} already associated with a channel. Unset it first using /unset_channel"
        )
    end
  end

  defp manage_set_channel(
         %Struct.Interaction{channel_id: channel_id, data: %{options: [%{value: type}]}} =
           interaction
       ) do
    case Centrex.Discord.set_channel(type, channel_id) do
      {:ok, _} ->
        reply_to_interaction(
          interaction,
          "Channel type #{type} associated with channel #{%Channel{id: channel_id}}"
        )

      {:error, _} ->
        reply_to_interaction(
          interaction,
          "Channel type #{type} already associated with a channel. Unset it first using /unset_channel"
        )
    end
  end

  defp manage_unset_channel(
         %Struct.Interaction{data: %{options: [%{value: type}]}} =
           interaction
       ) do
    Centrex.Discord.unset_channel(type)
    reply_to_interaction(interaction, "Channel type #{type} has been unset")
  end

  defp reply_to_interaction(interaction, message) do
    Api.edit_interaction_response(
      interaction,
      %{content: message}
    )
  end
end
