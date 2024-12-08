defmodule Decidr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DecidrWeb.Telemetry,
      Decidr.Repo,
      {DNSCluster, query: Application.get_env(:decidr, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Decidr.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Decidr.Finch},
      # Start a worker by calling: Decidr.Worker.start_link(arg)
      # {Decidr.Worker, arg},
      # Start to serve requests, typically the last entry
      DecidrWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Decidr.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DecidrWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
