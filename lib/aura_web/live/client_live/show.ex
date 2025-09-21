defmodule AuraWeb.ClientLive.Show do
  use AuraWeb, :live_view

  alias Aura.Clients

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto space-y-6">
        <div class="card bg-base-100 shadow-xl border border-base-300">
          <div class="card-body">
            <.header>
              Client Details
              <:subtitle>This is a client record from your database.</:subtitle>
              <:actions>
                <.button navigate={~p"/clients"} class="btn btn-ghost btn-sm">
                  <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back to Clients
                </.button>
                <.button
                  variant="primary"
                  navigate={~p"/clients/#{@client}/edit?return_to=show"}
                  class="btn btn-primary btn-sm"
                >
                  <.icon name="hero-pencil-square" class="w-4 h-4 mr-2" /> Edit Client
                </.button>
              </:actions>
            </.header>
          </div>
        </div>

        <div class="card bg-base-100 shadow-xl border border-base-300">
          <div class="card-body">
            <h3 class="text-xl font-semibold mb-6 text-base-content">Client Information</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="space-y-2">
                <dt class="text-sm font-medium text-base-content/70 uppercase tracking-wide">Name</dt>
                <dd class="text-lg font-medium text-base-content">{@client.name}</dd>
              </div>
              <div class="space-y-2">
                <dt class="text-sm font-medium text-base-content/70 uppercase tracking-wide">
                  Industry Type
                </dt>
                <dd class="text-lg font-medium text-base-content">{@client.industry_type}</dd>
              </div>
              <div class="space-y-2">
                <dt class="text-sm font-medium text-base-content/70 uppercase tracking-wide">
                  Since
                </dt>
                <dd class="text-lg font-medium text-base-content">{@client.since}</dd>
              </div>
              <div class="space-y-2">
                <dt class="text-sm font-medium text-base-content/70 uppercase tracking-wide">
                  Status
                </dt>
                <dd>
                  <span class={[
                    "inline-flex items-center px-3 py-1 rounded-full text-sm font-medium",
                    @client.status == :active &&
                      "bg-success/10 text-success border border-success/20",
                    @client.status == :inactive &&
                      "bg-base-300 text-base-content/70 border border-base-content/20",
                    @client.status == :pending &&
                      "bg-warning/10 text-warning border border-warning/20"
                  ]}>
                    {String.capitalize(to_string(@client.status))}
                  </span>
                </dd>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Clients.subscribe_clients(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Client")
     |> assign(:client, Clients.get_client!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %Aura.Clients.Client{id: id} = client},
        %{assigns: %{client: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :client, client)}
  end

  def handle_info(
        {:deleted, %Aura.Clients.Client{id: id}},
        %{assigns: %{client: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current client was deleted.")
     |> push_navigate(to: ~p"/clients")}
  end

  def handle_info({type, %Aura.Clients.Client{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
