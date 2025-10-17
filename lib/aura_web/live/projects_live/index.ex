defmodule AuraWeb.ProjectsLive.Index do
  use AuraWeb, :live_view

  alias Aura.Projects
  alias Aura.Projects.Project

  @impl true
  def mount(_params, _session, socket) do
    case Projects.list_projects(socket.assigns.current_scope) do
      projects when is_list(projects) ->
        {:ok,
         socket
         |> assign(:current_user, socket.assigns.current_scope.user)
         |> assign(:current_scope, socket.assigns.current_scope)
         |> assign(:clients, Aura.Clients.list_clients(socket.assigns.current_scope))
         |> assign(:page_title, "Projects")
         |> stream(:projects, projects)}

      {:error, :unauthorized} ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have permission to view projects.")
         |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Project")
    |> assign(:project, Projects.get_project!(id))
    |> assign(:client_id, nil)
    |> assign(:patch, "/projects/#{id}")
  end

  defp apply_action(socket, :new, %{"client_id" => client_id}) do
    socket
    |> assign(:page_title, "New Project")
    |> assign(:project, %Project{})
    |> assign(:client_id, client_id)
    |> assign(:patch, "/clients/#{client_id}")
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Project")
    |> assign(:project, %Project{})
    |> assign(:patch, "/projects")
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Projects")
    |> assign(:project, nil)
    |> assign(:client_id, nil)
  end

  @impl true
  def handle_info({AuraWeb.ProjectsLive.FormComponent, {:saved, project}}, socket) do
    {:noreply, stream_insert(socket, :projects, project)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    project = Projects.get_project!(id)
    {:ok, _} = Projects.delete_project(socket.assigns.current_scope, project)

    {:noreply, stream_delete(socket, :projects, project)}
  end

  defp status_badge_variant(:in_quote), do: "warning"
  defp status_badge_variant(:in_development), do: "info"
  defp status_badge_variant(:maintenance), do: "success"
  defp status_badge_variant(:done), do: "success"
  defp status_badge_variant(:abandoned), do: "danger"
end
