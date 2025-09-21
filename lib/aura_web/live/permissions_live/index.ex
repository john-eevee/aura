defmodule AuraWeb.PermissionsLive.Index do
  use AuraWeb, :live_view

  alias Aura.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <!-- Header -->
        <div class="flex justify-between items-center">
          <div>
            <h1 class="text-3xl font-bold text-base-content">Permissions Management</h1>

            <p class="text-base-content/70 mt-2">
              Manage system permissions and user access control.
            </p>
          </div>

          <.button
            phx-click="create_permission"
            class="btn btn-primary"
          >
            <.icon name="hero-plus" class="w-5 h-5 mr-2" /> Add Permission
          </.button>
        </div>
        <!-- Permissions List -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <div class="overflow-x-auto">
              <table class="table table-zebra w-full">
                <thead>
                  <tr>
                    <th>Name</th>

                    <th>Description</th>

                    <th>Actions</th>
                  </tr>
                </thead>

                <tbody>
                  <%= for permission <- @permissions do %>
                    <tr>
                      <td class="font-mono text-sm">{permission.name}</td>

                      <td>{permission.description}</td>

                      <td>
                        <div class="flex gap-2">
                          <.button
                            phx-click="edit_permission"
                            phx-value-id={permission.id}
                            class="btn btn-sm btn-outline btn-info"
                          >
                            <.icon name="hero-pencil" class="w-4 h-4" />
                          </.button>
                          <.button
                            phx-click="delete_permission"
                            phx-value-id={permission.id}
                            class="btn btn-sm btn-outline btn-error"
                            data-confirm="Are you sure you want to delete this permission?"
                          >
                            <.icon name="hero-trash" class="w-4 h-4" />
                          </.button>
                        </div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
        <!-- User Permissions Management -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title text-xl mb-4">User Permissions</h2>

            <div class="space-y-4">
              <%= for user <- @users do %>
                <div class="border border-base-300 rounded-lg p-4">
                  <div class="flex justify-between items-center mb-3">
                    <div>
                      <h3 class="font-semibold">{user.email}</h3>

                      <p class="text-sm text-base-content/70">
                        {length(user.permissions)} permissions assigned
                      </p>
                    </div>

                    <.button
                      phx-click="manage_user_permissions"
                      phx-value-user-id={user.id}
                      class="btn btn-sm btn-outline btn-primary"
                    >
                      <.icon name="hero-cog" class="w-4 h-4 mr-2" /> Manage Permissions
                    </.button>
                  </div>

                  <div class="flex flex-wrap gap-2">
                    <%= for permission <- user.permissions do %>
                      <span class="badge badge-primary badge-outline">{permission.name}</span>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
      <!-- Permission Form Modal -->
      <div :if={@show_form} class="modal modal-open">
        <div class="modal-box max-w-md">
          <.live_component
            module={AuraWeb.PermissionsLive.FormComponent}
            id={@permission.id || :new}
            title={@live_action_title}
            action={@live_action}
            permission={@permission}
            flash={@flash}
            return_to={~p"/permissions"}
          />
        </div>

        <div class="modal-backdrop" phx-click="close_modal"></div>
      </div>
      <!-- User Permissions Modal -->
      <div :if={@show_user_permissions} class="modal modal-open">
        <div class="modal-box max-w-2xl">
          <.live_component
            module={AuraWeb.PermissionsLive.UserPermissionsComponent}
            id={@selected_user.id || :new}
            user={@selected_user}
            permissions={@permissions}
            flash={@flash}
            return_to={~p"/permissions"}
          />
        </div>

        <div class="modal-backdrop" phx-click="close_modal"></div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:permissions, list_permissions())
     |> assign(:users, list_users_with_permissions())
     |> assign(:show_form, false)
     |> assign(:show_user_permissions, false)
     |> assign(:permission, %Aura.Accounts.Permission{})
     |> assign(:selected_user, %Aura.Accounts.User{})
     |> assign(:live_action_title, "")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Permissions")
    |> assign(:permission, %Aura.Accounts.Permission{})
  end

  @impl true
  def handle_event("create_permission", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:permission, %Aura.Accounts.Permission{})
     |> assign(:live_action_title, "Create Permission")}
  end

  def handle_event("edit_permission", %{"id" => id}, socket) do
    permission = Accounts.get_permission!(id)

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:permission, permission)
     |> assign(:live_action_title, "Edit Permission")}
  end

  def handle_event("delete_permission", %{"id" => id}, socket) do
    permission = Accounts.get_permission!(id)
    {:ok, _} = Accounts.delete_permission(permission)

    {:noreply,
     socket
     |> put_flash(:info, "Permission deleted successfully")
     |> assign(:permissions, list_permissions())}
  end

  def handle_event("manage_user_permissions", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user_with_permissions(user_id)

    {:noreply,
     socket
     |> assign(:show_user_permissions, true)
     |> assign(:selected_user, user)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> assign(:show_user_permissions, false)}
  end

  @impl true
  def handle_info({:permission_created, _permission}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Permission created successfully")
     |> assign(:show_form, false)
     |> assign(:permissions, list_permissions())}
  end

  def handle_info({:permission_updated, _permission}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Permission updated successfully")
     |> assign(:show_form, false)
     |> assign(:permissions, list_permissions())}
  end

  def handle_info({:user_permissions_updated, _user}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "User permissions updated successfully")
     |> assign(:show_user_permissions, false)
     |> assign(:users, list_users_with_permissions())}
  end

  def handle_info({:close_modal}, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> assign(:show_user_permissions, false)}
  end

  defp list_permissions do
    Accounts.list_permissions()
  end

  defp list_users_with_permissions do
    # For now, just get all users with their permissions
    # In a real app, you might want to paginate this
    import Ecto.Query

    Aura.Repo.all(
      from u in Aura.Accounts.User,
        preload: [:permissions],
        order_by: [desc: u.inserted_at]
    )
  end
end
