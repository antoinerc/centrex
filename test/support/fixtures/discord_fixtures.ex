defmodule Centrex.DiscordFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Centrex.Discord` context.
  """

  @doc """
  Generate a channel.
  """
  def channel_fixture(attrs \\ %{}) do
    {:ok, channel} =
      attrs
      |> Enum.into(%{
        id: 120.5,
        type: "some type"
      })
      |> Centrex.Discord.create_channel()

    channel
  end
end
