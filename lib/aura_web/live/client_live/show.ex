defmodule AuraWeb.ClientLive.Show do
  use AuraWeb, :live_view

  alias Aura.Clients
  alias Aura.Projects
  alias Aura.Projects.Project

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto space-y-6">
        <div class="card bg-base-100 shadow-xl border border-base-300">
          <div class="card-body">
            <.header>
              Client Details
              <:subtitle>This is a client record from your database.</:subtitle>
              <:actions>
                <.button navigate={~p"/clients"} class="btn btn-ghost btn-sm">
                  <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back to Clients
                </.button>
                <.button
                  variant="primary"
                  navigate={~p"/clients/#{@client}/edit?return_to=show"}
                  class="btn btn-primary btn-sm"
                >
                  <.icon name="hero-pencil-square" class="w-4 h-4 mr-2" /> Edit Client
                </.button>
              </:actions>
            </.header>
          </div>
        </div>

        <div class="card bg-base-100 shadow-xl border border-base-300">
          <div class="card-body">
            <h3 class="text-xl font-semibold mb-6 text-base-content">Client Information</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="space-y-2">
                <dt class="text-sm font-medium text-base-content/70 uppercase tracking-wide">Name</dt>
                <dd class="text-lg font-medium text-base-content">{@client.name}</dd>
              </div>
              <div class="space-y-2">
                <dt class="text-sm font-medium text-base-content/70 uppercase tracking-wide">
                  Industry Type
                </dt>
                <dd class="text-lg font-medium text-base-content">{@client.industry_type}</dd>
              </div>
              <div class="space-y-2">
                <dt class="text-sm font-medium text-base-content/70 uppercase tracking-wide">
                  Since
                </dt>
                <dd class="text-lg font-medium text-base-content">{@client.since}</dd>
              </div>
              <div class="space-y-2">
                <dt class="text-sm font-medium text-base-content/70 uppercase tracking-wide">
                  Status
                </dt>
                <dd>
                  <span class={[
                    "inline-flex items-center px-3 py-1 rounded-full text-sm font-medium",
                    @client.status == :active &&
                      "bg-success/10 text-success border border-success/20",
                    @client.status == :inactive &&
                      "bg-base-300 text-base-content/70 border border-base-content/20",
                    @client.status == :pending &&
                      "bg-warning/10 text-warning border border-warning/20"
                  ]}>
                    {String.capitalize(to_string(@client.status))}
                  </span>
                </dd>
              </div>
            </div>
          </div>
        </div>

        <div class="card bg-base-100 shadow-xl border border-base-300">
          <div class="card-body">
            <h3 class="text-xl font-semibold mb-6 text-base-content">Projects</h3>
            <div class="flex justify-end mb-4">
              <.button
                variant="primary"
                phx-click={JS.patch(~p"/clients/#{@client}?action=new_project")}
                class="btn btn-primary btn-sm"
              >
                <.icon name="hero-plus" class="w-4 h-4 mr-2" /> New Project
              </.button>
            </div>

            <div :if={@projects == []}>
              <p class="text-base-content/70">No projects yet. Create one to get started!</p>
            </div>

            <div :if={@projects != []}>
              <div class="space-y-2">
                <div
                  :for={project <- @projects}
                  class="flex items-center justify-between p-3 border border-base-300 rounded-lg"
                >
                  <div>
                    <p class="font-medium">{project.name}</p>
                    <p class="text-sm text-base-content/60">{project.description}</p>
                  </div>
                  <div class="flex gap-2">
                    <.link navigate={~p"/projects/#{project}"}>
                      <.button class="btn btn-sm btn-ghost">
                        <.icon name="hero-eye" class="w-4 h-4" />
                      </.button>
                    </.link>
                    <.link patch={
                      ~p"/clients/#{@client}?action=edit_project&project_id=#{project.id}"
                    }>
                      <.button class="btn btn-sm btn-ghost">
                        <.icon name="hero-pencil-square" class="w-4 h-4" />
                      </.button>
                    </.link>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <.modal
        :if={@live_action == :new_project}
        id="new-project-modal"
        show
        on_cancel={JS.patch(~p"/clients/#{@client}")}
      >
        <.live_component
          module={AuraWeb.ProjectsLive.FormComponent}
          id={:new}
          title="New Project"
          action={:new}
          project={%Project{}}
          current_user={@current_user}
          current_scope={@current_scope}
          client_id={@client.id}
          patch={~p"/clients/#{@client}"}
        />
      </.modal>

      <.modal
        :if={@live_action == :edit_project}
        id="edit-project-modal"
        show
        on_cancel={JS.patch(~p"/clients/#{@client}")}
      >
        <.live_component
          module={AuraWeb.ProjectsLive.FormComponent}
          id={@editing_project.id || :new}
          title="Edit Project"
          action={:edit}
          project={@editing_project}
          current_user={@current_user}
          current_scope={@current_scope}
          client_id={@client.id}
          patch={~p"/clients/#{@client}"}
        />
      </.modal>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Clients.subscribe_clients(socket.assigns.current_scope)
    end

    case Clients.get_client(socket.assigns.current_scope, id) do
      {:ok, client} ->
        projects = Projects.list_projects_for_client(client.id)

        {:ok,
         socket
         |> assign(:page_title, "Show Client")
         |> assign(:current_user, socket.assigns.current_scope.user)
         |> assign(:client, client)
         |> assign(:projects, projects)
         |> assign(:editing_project, nil)}

      {:error, :unauthorized} ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have permission to view this client.")
         |> redirect(to: ~p"/clients")}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Client not found.")
         |> redirect(to: ~p"/clients")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, params)}
  end

  defp apply_action(socket, %{"action" => "new_project"}) do
    socket
    |> assign(:live_action, :new_project)
    |> assign(:editing_project, nil)
  end

  defp apply_action(socket, %{"action" => "edit_project", "project_id" => project_id}) do
    project = Projects.get_project!(project_id)

    socket
    |> assign(:live_action, :edit_project)
    |> assign(:editing_project, project)
  end

  defp apply_action(socket, _params) do
    socket
    |> assign(:live_action, nil)
    |> assign(:editing_project, nil)
  end

  @impl true
  def handle_info({AuraWeb.ProjectsLive.FormComponent, {:saved, _project}}, socket) do
    # Reload projects list
    projects = Projects.list_projects_for_client(socket.assigns.client.id)

    {:noreply,
     socket
     |> assign(:projects, projects)
     |> push_patch(to: ~p"/clients/#{socket.assigns.client}")}
  end

  @impl true
  def handle_info(
        {:updated, %Aura.Clients.Client{id: id} = client},
        %{assigns: %{client: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :client, client)}
  end

  def handle_info(
        {:deleted, %Aura.Clients.Client{id: id}},
        %{assigns: %{client: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current client was deleted.")
     |> push_navigate(to: ~p"/clients")}
  end

  def handle_info({type, %Aura.Clients.Client{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
