defmodule AuraWeb.PermissionsLive.UserPermissionsComponent do
  use AuraWeb, :live_component

  alias Aura.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Manage Permissions for {@user.email}
        <:subtitle>Assign or remove permissions for this user.</:subtitle>
      </.header>

      <div class="space-y-4">
        <%= for permission <- @permissions do %>
          <div class="flex items-center justify-between p-4 border border-base-300 rounded-lg">
            <div>
              <h3 class="font-semibold font-mono">{permission.name}</h3>

              <p class="text-sm text-base-content/70">{permission.description}</p>
            </div>

            <div class="flex gap-2">
              <%= if permission_assigned?(@user, permission) do %>
                <.button
                  phx-click="remove_permission"
                  phx-value-permission-id={permission.id}
                  phx-target={@myself}
                  class="btn btn-sm btn-outline btn-error"
                >
                  <.icon name="hero-minus" class="w-4 h-4 mr-2" /> Remove
                </.button>
              <% else %>
                <.button
                  phx-click="assign_permission"
                  phx-value-permission-id={permission.id}
                  phx-target={@myself}
                  class="btn btn-sm btn-primary"
                >
                  <.icon name="hero-plus" class="w-4 h-4 mr-2" /> Assign
                </.button>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>

      <div class="mt-6 flex justify-end">
        <.button phx-click="close" phx-target={@myself} class="btn btn-ghost">Close</.button>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("assign_permission", %{"permission-id" => permission_id}, socket) do
    permission = Accounts.get_permission!(permission_id)

    case Accounts.assign_permission_to_user(socket.assigns.user, permission) do
      {:ok, _user_permission} ->
        # Refresh the user with updated permissions
        updated_user = Accounts.get_user_with_permissions(socket.assigns.user.id)

        {:noreply,
         socket
         |> assign(:user, updated_user)
         |> put_flash(:info, "Permission assigned successfully")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to assign permission")}
    end
  end

  def handle_event("remove_permission", %{"permission-id" => permission_id}, socket) do
    permission = Accounts.get_permission!(permission_id)

    case Accounts.remove_permission_from_user(socket.assigns.user, permission) do
      {:ok, _user_permission} ->
        # Refresh the user with updated permissions
        updated_user = Accounts.get_user_with_permissions(socket.assigns.user.id)

        {:noreply,
         socket
         |> assign(:user, updated_user)
         |> put_flash(:info, "Permission removed successfully")}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "Permission was not assigned to this user")}
    end
  end

  def handle_event("close", _params, socket) do
    notify_parent({:user_permissions_updated, socket.assigns.user})
    {:noreply, socket}
  end

  defp permission_assigned?(user, permission) do
    Enum.any?(user.permissions, &(&1.id == permission.id))
  end

  defp notify_parent(msg), do: send(self(), msg)
end
