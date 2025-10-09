defmodule Aura.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AuraWeb.Telemetry,
      Aura.Repo,
      {DNSCluster, query: Application.get_env(:aura, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Aura.PubSub},
      # Start a worker by calling: Aura.Worker.start_link(arg)
      # {Aura.Worker, arg},
      Aura.Documents.Cleaner,
      # Start to serve requests, typically the last entry
      AuraWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Aura.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AuraWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
