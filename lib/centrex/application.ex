defmodule Centrex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Centrex.Repo,
      # Start the Telemetry supervisor
      CentrexWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Centrex.PubSub},
      # Start the Endpoint (http/https)
      CentrexWeb.Endpoint,
      # Start a worker by calling: Centrex.Worker.start_link(arg)
      # {Centrex.Worker, arg}
      Centrex.ListingRegistry.child_spec(),
      Centrex.ListingSupervisor,
      Centrex.DiscordConsumer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Centrex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CentrexWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end