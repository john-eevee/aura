defmodule AuraWeb.PermissionsLive.FormComponent do
  use AuraWeb, :live_component

  alias Aura.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between items-center mb-4">
        <.header>{@title}</.header>

        <button
          type="button"
          class="btn btn-sm btn-circle btn-ghost"
          phx-click="close"
          phx-target={@myself}
        >
          <.icon name="hero-x-mark" class="w-5 h-5" />
        </button>
      </div>

      <.form
        for={@form}
        id="permission-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" placeholder="e.g., create_user" />
        <.input
          field={@form[:description]}
          type="textarea"
          label="Description"
          placeholder="Describe what this permission allows"
        />

        <div class="flex justify-end">
          <.button phx-disable-with="Saving...">Save Permission</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{permission: permission} = assigns, socket) do
    changeset = Accounts.change_permission(permission)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"permission" => permission_params}, socket) do
    changeset =
      socket.assigns.permission
      |> Accounts.change_permission(permission_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"permission" => permission_params}, socket) do
    action = if socket.assigns.permission.id, do: :edit, else: :new
    save_permission(socket, action, permission_params)
  end

  def handle_event("close", _params, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.patch)}
  end

  defp save_permission(socket, :edit, permission_params) do
    case Accounts.update_permission(socket.assigns.permission, permission_params) do
      {:ok, permission} ->
        notify_parent({:permission_updated, permission})

        {:noreply,
         socket
         |> put_flash(:info, "Permission updated successfully")
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_permission(socket, :new, permission_params) do
    case Accounts.create_permission(permission_params) do
      {:ok, permission} ->
        notify_parent({:permission_created, permission})

        {:noreply,
         socket
         |> put_flash(:info, "Permission created successfully")
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), msg)
end
