defmodule AuraWeb.ContactLive.Index do
  use AuraWeb, :live_view

  alias Aura.Clients

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Contacts
        <:actions>
          <.button variant="primary" navigate={~p"/contacts/new"}>
            <.icon name="hero-plus" /> New Contact
          </.button>
        </:actions>
      </.header>

      <.table
        id="contacts"
        rows={@streams.contacts}
        row_click={fn {_id, contact} -> JS.navigate(~p"/contacts/#{contact}") end}
      >
        <:col :let={{_id, contact}} label="Name">{contact.name}</:col>
        <:col :let={{_id, contact}} label="Phone">{contact.phone}</:col>
        <:col :let={{_id, contact}} label="Email">{contact.email}</:col>
        <:col :let={{_id, contact}} label="Role">{contact.role}</:col>
        <:action :let={{_id, contact}}>
          <div class="sr-only">
            <.link navigate={~p"/contacts/#{contact}"}>Show</.link>
          </div>
          <.link navigate={~p"/contacts/#{contact}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, contact}}>
          <.link
            phx-click={JS.push("delete", value: %{id: contact.id}) |> hide("##{id}")}
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
      Clients.subscribe_contacts(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Contacts")
     |> stream(:contacts, list_contacts(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    contact = Clients.get_contact!(socket.assigns.current_scope, id)
    {:ok, _} = Clients.delete_contact(socket.assigns.current_scope, contact)

    {:noreply, stream_delete(socket, :contacts, contact)}
  end

  @impl true
  def handle_info({type, %Aura.Clients.Contact{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :contacts, list_contacts(socket.assigns.current_scope), reset: true)}
  end

  defp list_contacts(current_scope) do
    Clients.list_contacts(current_scope)
  end
end
