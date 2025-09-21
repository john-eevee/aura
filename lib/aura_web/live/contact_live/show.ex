defmodule AuraWeb.ContactLive.Show do
  use AuraWeb, :live_view

  alias Aura.Clients

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Contact {@contact.id}
        <:subtitle>This is a contact record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/contacts"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/contacts/#{@contact}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit contact
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@contact.name}</:item>
        <:item title="Phone">{@contact.phone}</:item>
        <:item title="Email">{@contact.email}</:item>
        <:item title="Role">{@contact.role}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Clients.subscribe_contacts(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Contact")
     |> assign(:contact, Clients.get_contact!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %Aura.Clients.Contact{id: id} = contact},
        %{assigns: %{contact: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :contact, contact)}
  end

  def handle_info(
        {:deleted, %Aura.Clients.Contact{id: id}},
        %{assigns: %{contact: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current contact was deleted.")
     |> push_navigate(to: ~p"/contacts")}
  end

  def handle_info({type, %Aura.Clients.Contact{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
