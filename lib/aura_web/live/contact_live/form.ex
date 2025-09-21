defmodule AuraWeb.ContactLive.Form do
  use AuraWeb, :live_view

  alias Aura.Clients
  alias Aura.Clients.Contact

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage contact records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="contact-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:phone]} type="text" label="Phone" />
        <.input field={@form[:email]} type="text" label="Email" />
        <.input field={@form[:role]} type="text" label="Role" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Contact</.button>
          <.button navigate={return_path(@current_scope, @return_to, @contact)}>Cancel</.button>
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
    contact = Clients.get_contact!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Contact")
    |> assign(:contact, contact)
    |> assign(:form, to_form(Clients.change_contact(socket.assigns.current_scope, contact)))
  end

  defp apply_action(socket, :new, _params) do
    contact = %Contact{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Contact")
    |> assign(:contact, contact)
    |> assign(:form, to_form(Clients.change_contact(socket.assigns.current_scope, contact)))
  end

  @impl true
  def handle_event("validate", %{"contact" => contact_params}, socket) do
    changeset = Clients.change_contact(socket.assigns.current_scope, socket.assigns.contact, contact_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"contact" => contact_params}, socket) do
    save_contact(socket, socket.assigns.live_action, contact_params)
  end

  defp save_contact(socket, :edit, contact_params) do
    case Clients.update_contact(socket.assigns.current_scope, socket.assigns.contact, contact_params) do
      {:ok, contact} ->
        {:noreply,
         socket
         |> put_flash(:info, "Contact updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, contact)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_contact(socket, :new, contact_params) do
    case Clients.create_contact(socket.assigns.current_scope, contact_params) do
      {:ok, contact} ->
        {:noreply,
         socket
         |> put_flash(:info, "Contact created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, contact)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _contact), do: ~p"/contacts"
  defp return_path(_scope, "show", contact), do: ~p"/contacts/#{contact}"
end
