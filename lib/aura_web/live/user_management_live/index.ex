defmodule AuraWeb.UserManagementLive.Index do
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
            <h1 class="text-3xl font-bold text-base-content">User Management</h1>

            <p class="text-base-content/70 mt-2">Manage users and their permissions in the system.</p>
          </div>

          <.button
            phx-click="create_user"
            class="btn btn-primary"
          >
            <.icon name="hero-plus" class="w-5 h-5 mr-2" /> Add User
          </.button>
        </div>
        <!-- Users List -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <div class="overflow-x-auto">
              <table class="table table-zebra w-full">
                <thead>
                  <tr>
                    <th>Email</th>

                    <th>Permissions</th>

                    <th>Joined</th>

                    <th>Actions</th>
                  </tr>
                </thead>

                <tbody>
                  <%= for user <- @users do %>
                    <tr>
                      <td class="font-medium">{user.email}</td>

                      <td>
                        <.button
                          phx-click="view_permissions"
                          phx-value-user-id={user.id}
                          class="btn btn-sm btn-ghost btn-info"
                        >
                          <.icon name="hero-eye" class="w-4 h-4 mr-1" />
                          {length(user.permissions)} permissions
                        </.button>
                      </td>

                      <td class="text-sm text-base-content/70">
                        {Calendar.strftime(user.inserted_at, "%B %d, %Y")}
                      </td>

                      <td>
                        <div class="flex gap-2">
                          <.button
                            phx-click="manage_permissions"
                            phx-value-user-id={user.id}
                            class="btn btn-sm btn-outline btn-info"
                          >
                            <.icon name="hero-shield-check" class="w-4 h-4" />
                          </.button>
                          <.button
                            phx-click="edit_user"
                            phx-value-user-id={user.id}
                            class="btn btn-sm btn-outline btn-warning"
                          >
                            <.icon name="hero-pencil" class="w-4 h-4" />
                          </.button>
                          <.button
                            phx-click="delete_user"
                            phx-value-user-id={user.id}
                            class="btn btn-sm btn-outline btn-error"
                            data-confirm="Are you sure you want to delete this user? This action cannot be undone."
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
      </div>
      <!-- User Form Modal -->
      <div :if={@show_form} class="modal modal-open">
        <div class="modal-box max-w-md">
          <.live_component
            module={AuraWeb.UserManagementLive.FormComponent}
            id={@user.id || :new}
            title={@live_action_title}
            action={@live_action}
            user={@user}
            return_to={~p"/users"}
          />
        </div>

        <div class="modal-backdrop" phx-click="close_modal"></div>
      </div>
      <!-- Permissions Modal -->
      <div :if={@show_permissions} class="modal modal-open">
        <div class="modal-box max-w-2xl">
          <.live_component
            module={AuraWeb.PermissionsLive.UserPermissionsComponent}
            id={@selected_user.id || :new}
            user={@selected_user}
            permissions={@permissions}
            return_to={~p"/users"}
          />
        </div>

        <div class="modal-backdrop" phx-click="close_modal"></div>
      </div>
      
    <!-- View Permissions Modal -->
      <div :if={@show_view_permissions} class="modal modal-open">
        <div class="modal-box max-w-md">
          <div class="flex justify-between items-center mb-6">
            <h3 class="text-lg font-bold">{@view_permissions_user.email}'s Permissions</h3>
            <button
              type="button"
              class="btn btn-sm btn-circle btn-ghost"
              phx-click="close_view_permissions_modal"
            >
              <.icon name="hero-x-mark" class="w-5 h-5" />
            </button>
          </div>

          <div class="space-y-4">
            <%= if Enum.empty?(@view_permissions_user.permissions) do %>
              <div class="text-center py-8">
                <div class="text-base-content/50">
                  <.icon name="hero-shield-exclamation" class="w-12 h-12 mx-auto mb-4 opacity-50" />
                  <p class="text-lg font-medium">No permissions assigned</p>
                  <p class="text-sm">This user has no permissions yet.</p>
                </div>
              </div>
            <% else %>
              <div class="space-y-3">
                <%= for permission <- @view_permissions_user.permissions do %>
                  <div class="flex items-center gap-3 p-3 bg-base-200 rounded-lg">
                    <div class="flex-shrink-0">
                      <.icon name="hero-shield-check" class="w-5 h-5 text-success" />
                    </div>
                    <div class="flex-1">
                      <div class="font-medium text-base-content">{permission.name}</div>
                      <%= if permission.description do %>
                        <div class="text-sm text-base-content/70">{permission.description}</div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <div class="flex justify-end mt-6">
            <.button
              type="button"
              class="btn btn-ghost"
              phx-click="close_view_permissions_modal"
            >
              Close
            </.button>
          </div>
        </div>

        <div class="modal-backdrop" phx-click="close_view_permissions_modal"></div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:users, list_users_with_permissions())
     |> assign(:permissions, Accounts.list_permissions())
     |> assign(:show_form, false)
     |> assign(:show_permissions, false)
     |> assign(:show_view_permissions, false)
     |> assign(:user, %Aura.Accounts.User{})
     |> assign(:selected_user, %Aura.Accounts.User{})
     |> assign(:view_permissions_user, %Aura.Accounts.User{})
     |> assign(:live_action_title, "")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "User Management")
    |> assign(:user, %Aura.Accounts.User{})
  end

  @impl true
  def handle_event("create_user", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:user, %Aura.Accounts.User{})
     |> assign(:live_action_title, "Create User")}
  end

  def handle_event("edit_user", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:user, user)
     |> assign(:live_action_title, "Edit User")}
  end

  def handle_event("delete_user", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)
    {:ok, _} = Accounts.delete_user(user)

    {:noreply,
     socket
     |> put_flash(:info, "User deleted successfully")
     |> assign(:users, list_users_with_permissions())}
  end

  def handle_event("manage_permissions", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user_with_permissions(user_id)

    {:noreply,
     socket
     |> assign(:show_permissions, true)
     |> assign(:selected_user, user)}
  end

  def handle_event("view_permissions", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user_with_permissions(user_id)

    {:noreply,
     socket
     |> assign(:show_view_permissions, true)
     |> assign(:view_permissions_user, user)}
  end

  def handle_event("close_view_permissions_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_view_permissions, false)
     |> assign(:view_permissions_user, %Aura.Accounts.User{})}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> assign(:show_permissions, false)}
  end

  @impl true
  def handle_info({:user_created, _user}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "User created successfully")
     |> assign(:show_form, false)
     |> assign(:users, list_users_with_permissions())}
  end

  def handle_info({:user_updated, _user}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "User updated successfully")
     |> assign(:show_form, false)
     |> assign(:users, list_users_with_permissions())}
  end

  def handle_info({:user_permissions_updated, _user}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "User permissions updated successfully")
     |> assign(:show_permissions, false)
     |> assign(:users, list_users_with_permissions())}
  end

  def handle_info({:close_modal}, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> assign(:show_permissions, false)
     |> assign(:show_view_permissions, false)}
  end

  defp list_users_with_permissions do
    import Ecto.Query

    Aura.Repo.all(
      from u in Aura.Accounts.User,
        preload: [:permissions],
        order_by: [desc: u.inserted_at]
    )
  end
end
