defmodule AuraWeb.ContactsLive.Index do
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
            <.icon name="hero-plus" /> New Contacts
          </.button>
        </:actions>
      </.header>

      <.table
        id="contacts"
        rows={@streams.contacts_collection}
        row_click={fn {_id, contacts} -> JS.navigate(~p"/contacts/#{contacts}") end}
      >
        <:col :let={{_id, contacts}} label="Name">{contacts.name}</:col>
        <:col :let={{_id, contacts}} label="Phone">{contacts.phone}</:col>
        <:col :let={{_id, contacts}} label="Email">{contacts.email}</:col>
        <:col :let={{_id, contacts}} label="Role">{contacts.role}</:col>
        <:action :let={{_id, contacts}}>
          <div class="sr-only">
            <.link navigate={~p"/contacts/#{contacts}"}>Show</.link>
          </div>
          <.link navigate={~p"/contacts/#{contacts}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, contacts}}>
          <.link
            phx-click={JS.push("delete", value: %{id: contacts.id}) |> hide("##{id}")}
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
     |> stream(:contacts_collection, list_contacts(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    contacts = Clients.get_contacts!(socket.assigns.current_scope, id)
    {:ok, _} = Clients.delete_contacts(socket.assigns.current_scope, contacts)

    {:noreply, stream_delete(socket, :contacts_collection, contacts)}
  end

  @impl true
  def handle_info({type, %Aura.Clients.Contacts{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :contacts_collection, list_contacts(socket.assigns.current_scope), reset: true)}
  end

  defp list_contacts(current_scope) do
    Clients.list_contacts(current_scope)
  end
end
