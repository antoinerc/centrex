defmodule Centrex.DiscordTest do
  use Centrex.DataCase

  alias Centrex.Discord

  describe "channels" do
    alias Centrex.Discord.Channel

    import Centrex.DiscordFixtures

    @invalid_attrs %{id: nil, type: nil}

    test "list_channels/0 returns all channels" do
      channel = channel_fixture()
      assert Discord.list_channels() == [channel]
    end

    test "get_channel!/1 returns the channel with given id" do
      channel = channel_fixture()
      assert Discord.get_channel!(channel.id) == channel
    end

    test "create_channel/1 with valid data creates a channel" do
      valid_attrs = %{id: 120.5, type: "some type"}

      assert {:ok, %Channel{} = channel} = Discord.create_channel(valid_attrs)
      assert channel.id == 120.5
      assert channel.type == "some type"
    end

    test "create_channel/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Discord.create_channel(@invalid_attrs)
    end

    test "update_channel/2 with valid data updates the channel" do
      channel = channel_fixture()
      update_attrs = %{id: 456.7, type: "some updated type"}

      assert {:ok, %Channel{} = channel} = Discord.update_channel(channel, update_attrs)
      assert channel.id == 456.7
      assert channel.type == "some updated type"
    end

    test "update_channel/2 with invalid data returns error changeset" do
      channel = channel_fixture()
      assert {:error, %Ecto.Changeset{}} = Discord.update_channel(channel, @invalid_attrs)
      assert channel == Discord.get_channel!(channel.id)
    end

    test "delete_channel/1 deletes the channel" do
      channel = channel_fixture()
      assert {:ok, %Channel{}} = Discord.delete_channel(channel)
      assert_raise Ecto.NoResultsError, fn -> Discord.get_channel!(channel.id) end
    end

    test "change_channel/1 returns a channel changeset" do
      channel = channel_fixture()
      assert %Ecto.Changeset{} = Discord.change_channel(channel)
    end
  end
end
