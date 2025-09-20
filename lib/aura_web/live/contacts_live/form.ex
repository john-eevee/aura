defmodule AuraWeb.ContactsLive.Form do
  use AuraWeb, :live_view

  alias Aura.Clients
  alias Aura.Clients.Contacts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage contacts records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="contacts-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:phone]} type="text" label="Phone" />
        <.input field={@form[:email]} type="text" label="Email" />
        <.input field={@form[:role]} type="text" label="Role" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Contacts</.button>
          <.button navigate={return_path(@current_scope, @return_to, @contacts)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    contacts = Clients.get_contacts!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Contacts")
    |> assign(:contacts, contacts)
    |> assign(:form, to_form(Clients.change_contacts(socket.assigns.current_scope, contacts)))
  end

  defp apply_action(socket, :new, _params) do
    contacts = %Contacts{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Contacts")
    |> assign(:contacts, contacts)
    |> assign(:form, to_form(Clients.change_contacts(socket.assigns.current_scope, contacts)))
  end

  @impl true
  def handle_event("validate", %{"contacts" => contacts_params}, socket) do
    changeset = Clients.change_contacts(socket.assigns.current_scope, socket.assigns.contacts, contacts_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"contacts" => contacts_params}, socket) do
    save_contacts(socket, socket.assigns.live_action, contacts_params)
  end

  defp save_contacts(socket, :edit, contacts_params) do
    case Clients.update_contacts(socket.assigns.current_scope, socket.assigns.contacts, contacts_params) do
      {:ok, contacts} ->
        {:noreply,
         socket
         |> put_flash(:info, "Contacts updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, contacts)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_contacts(socket, :new, contacts_params) do
    case Clients.create_contacts(socket.assigns.current_scope, contacts_params) do
      {:ok, contacts} ->
        {:noreply,
         socket
         |> put_flash(:info, "Contacts created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, contacts)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _contacts), do: ~p"/contacts"
  defp return_path(_scope, "show", contacts), do: ~p"/contacts/#{contacts}"
end
