defmodule AuraWeb.ClientLive.Form do
  use AuraWeb, :live_view

  alias Aura.Clients
  alias Aura.Clients.Client

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto">
        <div class="card bg-base-100 shadow-xl border border-base-300">
          <div class="card-body space-y-6">
            <.header>
              {@page_title}
              <:subtitle>Use this form to manage client records in your database.</:subtitle>
            </.header>

            <.form
              for={@form}
              id="client-form"
              phx-change="validate"
              phx-submit="save"
              class="space-y-6"
            >
              <div class="space-y-6">
                <.input
                  field={@form[:name]}
                  type="text"
                  label="Name"
                  class="input input-bordered focus:input-primary"
                />
                <.input
                  field={@form[:industry_type]}
                  type="text"
                  label="Industry type"
                  class="input input-bordered focus:input-primary"
                />
                <.input
                  field={@form[:since]}
                  type="datetime-local"
                  label="Since"
                  class="input input-bordered focus:input-primary"
                />
                <.input
                  field={@form[:status]}
                  type="select"
                  label="Status"
                  prompt="Choose a value"
                  options={Ecto.Enum.values(Aura.Clients.Client, :status)}
                  class="select select-bordered focus:select-primary"
                />
              </div>
              <div class="divider"></div>
              <div class="flex gap-4 justify-end">
                <.button phx-disable-with="Saving..." variant="primary" class="btn btn-primary btn-lg">
                  <.icon name="hero-check" class="w-5 h-5 mr-2" /> Save Client
                </.button>
                <.button
                  navigate={return_path(@current_scope, @return_to, @client)}
                  class="btn btn-ghost"
                >
                  Cancel
                </.button>
              </div>
            </.form>
          </div>
        </div>
      </div>
      
    <!-- Add Contacts Confirmation Dialog -->
      <div
        :if={@show_add_contacts_modal}
        class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50"
        phx-click="cancel_add_contacts"
      >
        <div
          class="bg-base-100 rounded-lg shadow-xl border border-base-300 p-6 max-w-md mx-4"
          phx-click-away="cancel_add_contacts"
        >
          <div class="space-y-4">
            <div class="text-center">
              <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-success/10 mb-4">
                <.icon name="hero-check-circle" class="h-6 w-6 text-success" />
              </div>
              <h3 class="text-lg font-semibold text-base-content">Client Created Successfully!</h3>
              <p class="text-base-content/70 mt-2">
                Would you like to add contacts for this client?
              </p>
            </div>
            <div class="flex gap-3 justify-center">
              <.button
                phx-click="add_contacts_yes"
                class="btn btn-primary flex-1"
              >
                <.icon name="hero-plus" class="w-4 h-4 mr-2" /> Yes, Add Contacts
              </.button>
              <.button
                phx-click="add_contacts_no"
                class="btn btn-ghost flex-1"
              >
                No, Go to Client List
              </.button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:show_add_contacts_modal, false)
     |> assign(:saved_client, nil)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    client = Clients.get_client!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Client")
    |> assign(:client, client)
    |> assign(:form, to_form(Clients.change_client(socket.assigns.current_scope, client)))
  end

  defp apply_action(socket, :new, _params) do
    client = %Client{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Client")
    |> assign(:client, client)
    |> assign(:form, to_form(Clients.change_client(socket.assigns.current_scope, client)))
  end

  @impl true
  def handle_event("validate", %{"client" => client_params}, socket) do
    changeset =
      Clients.change_client(socket.assigns.current_scope, socket.assigns.client, client_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"client" => client_params}, socket) do
    save_client(socket, socket.assigns.live_action, client_params)
  end

  def handle_event("add_contacts_yes", _params, socket) do
    client = socket.assigns.saved_client

    {:noreply,
     socket
     |> assign(:show_add_contacts_modal, false)
     |> push_navigate(to: ~p"/contacts/new?client_id=#{client.id}")}
  end

  def handle_event("add_contacts_no", _params, socket) do
    client = socket.assigns.saved_client

    {:noreply,
     socket
     |> assign(:show_add_contacts_modal, false)
     |> push_navigate(
       to: return_path(socket.assigns.current_scope, socket.assigns.return_to, client)
     )}
  end

  def handle_event("cancel_add_contacts", _params, socket) do
    client = socket.assigns.saved_client

    {:noreply,
     socket
     |> assign(:show_add_contacts_modal, false)
     |> push_navigate(
       to: return_path(socket.assigns.current_scope, socket.assigns.return_to, client)
     )}
  end

  defp save_client(socket, :edit, client_params) do
    case Clients.update_client(socket.assigns.current_scope, socket.assigns.client, client_params) do
      {:ok, client} ->
        {:noreply,
         socket
         |> put_flash(:info, "Client updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, client)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_client(socket, :new, client_params) do
    case Clients.create_client(socket.assigns.current_scope, client_params) do
      {:ok, client} ->
        {:noreply,
         socket
         |> put_flash(:info, "Client created successfully")
         |> assign(:show_add_contacts_modal, true)
         |> assign(:saved_client, client)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _client), do: ~p"/clients"
  defp return_path(_scope, "show", client), do: ~p"/clients/#{client}"
end
