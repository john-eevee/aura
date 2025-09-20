defmodule AuraWeb.ClientLive.Index do
  use AuraWeb, :live_view

  alias Aura.Clients

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Clients
        <:actions>
          <.button variant="primary" navigate={~p"/clients/new"}>
            <.icon name="hero-plus" /> New Client
          </.button>
        </:actions>
      </.header>

      <.table
        id="clients"
        rows={@streams.clients}
        row_click={fn {_id, client} -> JS.navigate(~p"/clients/#{client}") end}
      >
        <:col :let={{_id, client}} label="Name">{client.name}</:col>
        <:col :let={{_id, client}} label="Since">{client.since}</:col>
        <:col :let={{_id, client}} label="Status">{client.status}</:col>
        <:col :let={{_id, client}} label="Industry type">{client.industry_type}</:col>
        <:action :let={{_id, client}}>
          <div class="sr-only">
            <.link navigate={~p"/clients/#{client}"}>Show</.link>
          </div>
          <.link navigate={~p"/clients/#{client}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, client}}>
          <.link
            phx-click={JS.push("delete", value: %{id: client.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Clients.subscribe_clients(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Clients")
     |> stream(:clients, list_clients(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    client = Clients.get_client!(socket.assigns.current_scope, id)
    {:ok, _} = Clients.delete_client(socket.assigns.current_scope, client)

    {:noreply, stream_delete(socket, :clients, client)}
  end

  @impl true
  def handle_info({type, %Aura.Clients.Client{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :clients, list_clients(socket.assigns.current_scope), reset: true)}
  end

  defp list_clients(current_scope) do
    Clients.list_clients(current_scope)
  end
end
