defmodule Centrex.Commands do
  @add %{
    name: "track",
    description: "track a listing",
    options: [
      %{
        type: 3,
        name: "address",
        description: "address of property",
        required: true
      },
      %{
        type: 3,
        name: "price",
        description: "current price for the listing",
        required: true
      },
      %{
        type: 3,
        name: "link",
        description: "link to listing",
        required: true
      },
      %{
        type: 3,
        name: "type",
        description: "whether it's a house or a condo",
        required: false,
        choices: [%{name: "house", value: "house"}, %{name: "condo", value: "condo"}]
      }
    ]
  }

  @search %{
    name: "search",
    description: "search for a listing",
    options: [
      %{
        type: 3,
        name: "address",
        description: "address of property",
        required: true
      }
    ]
  }

  @set_channel %{
    name: "set_channel",
    description: "associate the channel type with the channel name",
    options: [
      %{
        type: 3,
        name: "type",
        description: "whether it's a house or a condo",
        required: true,
        choices: [%{name: "house", value: "house"}, %{name: "condo", value: "condo"}]
      },
      %{
        type: 3,
        name: "channel_id",
        description: "specify the channel id, if missing the current channel will be used",
        required: false
      }
    ]
  }

  @unset_channel %{
    name: "unset_channel",
    description: "free the channel type from the currently associated channel",
    options: [
      %{
        type: 3,
        name: "type",
        description: "whether it's a house or a condo",
        required: true,
        choices: [%{name: "house", value: "house"}, %{name: "condo", value: "condo"}]
      }
    ]
  }

  @scan %{
    name: "scan",
    description: "scan a URL for listing informations",
    options: [
      %{
        type: 3,
        name: "link",
        description: "link of listing",
        required: true
      }
    ]
  }

  def all do
    [@add, @search, @set_channel, @unset_channel, @scan]
  end
end
