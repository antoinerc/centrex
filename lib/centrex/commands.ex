defmodule Centrex.Commands do
  @add %{
    name: "track",
    description: "track a listing",
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

  def all do
    [@add, @search]
  end
end
