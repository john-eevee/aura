defmodule AuraWeb.DashboardLive.Index do
  use AuraWeb, :live_view

  alias Aura.Clients

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <!-- Welcome Header -->
        <div class="card bg-gradient-to-r from-primary/10 to-secondary/10 shadow-xl border border-primary/20">
          <div class="card-body">
            <div class="flex items-center gap-4">
              <div class="avatar placeholder">
                <div class="bg-primary text-primary-content rounded-full w-16">
                  <span class="text-2xl font-bold">{String.first(@current_scope.user.email)}</span>
                </div>
              </div>

              <div>
                <h1 class="text-3xl font-bold text-base-content">
                  Welcome back, {String.split(@current_scope.user.email, "@") |> List.first()}!
                </h1>

                <p class="text-base-content/70 mt-1">
                  Here's what's happening with your client relationships today.
                </p>
              </div>
            </div>
          </div>
        </div>
        <!-- Quick Actions -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <!-- Clients Management -->
          <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-all duration-300 hover:scale-105 border border-base-300">
            <div class="card-body text-center">
              <div class="w-16 h-16 bg-gradient-to-br from-primary to-primary/70 rounded-full flex items-center justify-center mx-auto mb-4">
                <.icon name="hero-users" class="text-2xl text-white" />
              </div>

              <h3 class="card-title justify-center text-xl font-bold mb-2">Client Management</h3>

              <p class="text-base-content/70 mb-4">
                View and manage your client database. Add new clients, update information, and track relationships.
              </p>

              <.button
                variant="primary"
                navigate={~p"/clients"}
                class="btn btn-primary btn-block"
              >
                <.icon name="hero-users" class="w-5 h-5 mr-2" /> View Clients
              </.button>
            </div>
          </div>
          <!-- Add New Client -->
          <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-all duration-300 hover:scale-105 border border-base-300">
            <div class="card-body text-center">
              <div class="w-16 h-16 bg-gradient-to-br from-secondary to-secondary/70 rounded-full flex items-center justify-center mx-auto mb-4">
                <.icon name="hero-plus" class="text-2xl text-white" />
              </div>

              <h3 class="card-title justify-center text-xl font-bold mb-2">Add New Client</h3>

              <p class="text-base-content/70 mb-4">
                Quickly add a new client to your database. Start building stronger relationships today.
              </p>

              <.button
                navigate={~p"/clients/new"}
                class="btn btn-secondary btn-block"
              >
                <.icon name="hero-plus" class="w-5 h-5 mr-2" /> New Client
              </.button>
            </div>
          </div>
          <!-- Contact Management -->
          <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-all duration-300 hover:scale-105 border border-base-300">
            <div class="card-body text-center">
              <div class="w-16 h-16 bg-gradient-to-br from-accent to-accent/70 rounded-full flex items-center justify-center mx-auto mb-4">
                <.icon name="hero-phone" class="text-2xl text-white" />
              </div>

              <h3 class="card-title justify-center text-xl font-bold mb-2">Contact Management</h3>

              <p class="text-base-content/70 mb-4">
                Manage all your client contacts in one place. Keep track of important contact information.
              </p>

              <.button
                navigate={~p"/contacts"}
                class="btn btn-accent btn-block"
              >
                <.icon name="hero-phone" class="w-5 h-5 mr-2" /> View Contacts
              </.button>
            </div>
          </div>
        </div>
        <!-- Recent Activity / Stats -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Quick Stats -->
          <div class="card bg-base-100 shadow-xl border border-base-300">
            <div class="card-body">
              <h3 class="card-title text-lg font-bold mb-4">
                <.icon name="hero-chart-bar" class="w-5 h-5 mr-2" /> Quick Stats
              </h3>

              <div class="stats stats-vertical lg:stats-horizontal shadow">
                <div class="stat">
                  <div class="stat-figure text-primary">
                    <.icon name="hero-users" class="w-8 h-8" />
                  </div>

                  <div class="stat-title">Total Clients</div>

                  <div class="stat-value text-primary">{@total_clients}</div>

                  <div class="stat-desc">Active relationships</div>
                </div>

                <div class="stat">
                  <div class="stat-figure text-secondary">
                    <.icon name="hero-phone" class="w-8 h-8" />
                  </div>

                  <div class="stat-title">Total Contacts</div>

                  <div class="stat-value text-secondary">{@total_contacts}</div>

                  <div class="stat-desc">Contact points</div>
                </div>
              </div>
            </div>
          </div>
          <!-- Recent Clients -->
          <div class="card bg-base-100 shadow-xl border border-base-300">
            <div class="card-body">
              <h3 class="card-title text-lg font-bold mb-4">
                <.icon name="hero-clock" class="w-5 h-5 mr-2" /> Recent Clients
              </h3>

              <div class="space-y-3">
                <%= for client <- @recent_clients do %>
                  <div
                    class="flex items-center justify-between p-3 bg-base-200 rounded-lg hover:bg-base-300 transition-colors cursor-pointer"
                    phx-click={JS.navigate(~p"/clients/#{client}")}
                  >
                    <div class="flex items-center gap-3">
                      <div class="avatar placeholder">
                        <div class="bg-primary text-primary-content rounded-full w-8">
                          <span class="text-xs font-bold">{String.first(client.name)}</span>
                        </div>
                      </div>

                      <div>
                        <div class="font-medium">{client.name}</div>

                        <div class="text-sm text-base-content/60">
                          Added {client.inserted_at |> Calendar.strftime("%b %d")}
                        </div>
                      </div>
                    </div>
                    <.icon name="hero-chevron-right" class="w-5 h-5 text-base-content/40" />
                  </div>
                <% end %>

                <%= if Enum.empty?(@recent_clients) do %>
                  <div class="text-center py-8 text-base-content/60">
                    <p>
                      No clients yet.
                      <a href={~p"/clients/new"} class="link link-primary">Add your first client</a>
                    </p>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    total_clients = Clients.count_clients(socket.assigns.current_scope)
    total_contacts = Clients.count_contacts(socket.assigns.current_scope)
    recent_clients = Clients.list_recent_clients(socket.assigns.current_scope, limit: 5)

    {:ok,
     socket
     |> assign(:total_clients, total_clients)
     |> assign(:total_contacts, total_contacts)
     |> assign(:recent_clients, recent_clients)}
  end
end
