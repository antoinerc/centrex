defmodule Centrex do
  @moduledoc """
  Centrex keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  use Application

  def start(_type, _args) do
    # TODO: Maybe move DiscordConsumer into its own supervisor
    children = [
      Centrex.ListingRegistry.child_spec(),
      Centrex.ListingSupervisor,
      Centrex.Repo,
      Centrex.DiscordConsumer
    ]

    opts = [strategy: :one_for_one, name: Centrex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
