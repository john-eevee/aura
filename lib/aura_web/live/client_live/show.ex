defmodule AuraWeb.ClientLive.Show do
  use AuraWeb, :live_view

  alias Aura.Clients

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Client {@client.id}
        <:subtitle>This is a client record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/clients"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/clients/#{@client}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit client
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@client.name}</:item>
        <:item title="Since">{@client.since}</:item>
        <:item title="Status">{@client.status}</:item>
        <:item title="Industry type">{@client.industry_type}</:item>
      </.list>
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
