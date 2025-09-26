defmodule AuraWeb.ClientLive.Index do
  use AuraWeb, :live_view

  alias Aura.Clients

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <div class="card bg-base-100 shadow-xl border border-base-300">
          <div class="card-body">
            <.header>
              Client Management
              <:subtitle>Manage your client database and track their information.</:subtitle>
              <:actions>
                <.button variant="primary" navigate={~p"/clients/new"} class="btn btn-primary btn-lg">
                  <.icon name="hero-plus" class="w-5 h-5 mr-2" /> New Client
                </.button>
              </:actions>
            </.header>
          </div>
        </div>

        <div class="card bg-base-100 shadow-xl border border-base-300">
          <div class="card-body">
            <div class="overflow-x-auto">
              <.table
                id="clients"
                rows={@streams.clients}
                row_click={fn {_id, client} -> JS.navigate(~p"/clients/#{client}") end}
              >
                <:col :let={{_id, client}} label="Name">
                  <div class="flex items-center gap-3">
                    <div class="avatar placeholder">
                      <div class="bg-primary text-primary-content rounded-full w-8">
                        <span class="text-xs font-bold">{String.first(client.name)}</span>
                      </div>
                    </div>
                    <span class="font-medium">{client.name}</span>
                  </div>
                </:col>
                <:col :let={{_id, client}} label="Since">
                  {client.since}
                </:col>
                <:col :let={{_id, client}} label="Status">
                  <span class={[
                    "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium",
                    client.status == :active && "bg-success/10 text-success border border-success/20",
                    client.status == :inactive &&
                      "bg-base-300 text-base-content/70 border border-base-content/20",
                    client.status == :pending && "bg-warning/10 text-warning border border-warning/20"
                  ]}>
                    {String.capitalize(to_string(client.status))}
                  </span>
                </:col>
                <:col :let={{_id, client}} label="Industry">
                  {client.industry_type}
                </:col>
                <:action :let={{_id, client}}>
                  <div class="flex gap-2">
                    <.link navigate={~p"/clients/#{client}"} class="btn btn-ghost btn-sm" title="View">
                      <.icon name="hero-eye" class="w-4 h-4" />
                    </.link>
                    <.link
                      navigate={~p"/clients/#{client}/edit"}
                      class="btn btn-ghost btn-sm"
                      title="Edit"
                    >
                      <.icon name="hero-pencil-square" class="w-4 h-4" />
                    </.link>
                  </div>
                </:action>
                <:action :let={{id, client}}>
                  <.link
                    phx-click={JS.push("delete", value: %{id: client.id}) |> hide("##{id}")}
                    data-confirm="Are you sure?"
                    class="btn btn-ghost btn-sm text-error hover:bg-error/10"
                    title="Delete"
                  >
                    <.icon name="hero-trash" class="w-4 h-4" />
                  </.link>
                </:action>
              </.table>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Clients.subscribe_clients(socket.assigns.current_scope)
    end

    case list_clients(socket.assigns.current_scope) do
      clients when is_list(clients) ->
        {:ok,
         socket
         |> assign(:page_title, "Listing Clients")
         |> stream(:clients, clients)}

      {:error, :unauthorized} ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have permission to view clients.")
         |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Clients.get_client(socket.assigns.current_scope, id) do
      {:ok, client} ->
        {:ok, _} = Clients.delete_client(socket.assigns.current_scope, client)
        {:noreply, stream_delete(socket, :clients, client)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to delete this client.")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Client not found.")}
    end
  end

  @impl true
  def handle_info({type, %Aura.Clients.Client{}}, socket)
      when type in [:created, :updated, :deleted] do
    case list_clients(socket.assigns.current_scope) do
      clients when is_list(clients) ->
        {:noreply, stream(socket, :clients, clients, reset: true)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You no longer have permission to view clients.")}
    end
  end

  defp list_clients(current_scope) do
    Clients.list_clients(current_scope)
  end
end
