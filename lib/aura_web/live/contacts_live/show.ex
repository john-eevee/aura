defmodule AuraWeb.ContactsLive.Show do
  use AuraWeb, :live_view

  alias Aura.Clients

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Contacts {@contacts.id}
        <:subtitle>This is a contacts record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/contacts"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/contacts/#{@contacts}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit contacts
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@contacts.name}</:item>
        <:item title="Phone">{@contacts.phone}</:item>
        <:item title="Email">{@contacts.email}</:item>
        <:item title="Role">{@contacts.role}</:item>
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
     |> assign(:page_title, "Show Contacts")
     |> assign(:contacts, Clients.get_contacts!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %Aura.Clients.Contacts{id: id} = contacts},
        %{assigns: %{contacts: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :contacts, contacts)}
  end

  def handle_info(
        {:deleted, %Aura.Clients.Contacts{id: id}},
        %{assigns: %{contacts: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current contacts was deleted.")
     |> push_navigate(to: ~p"/contacts")}
  end

  def handle_info({type, %Aura.Clients.Contacts{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
