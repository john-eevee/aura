defmodule AuraWeb.ProjectsLive.Show do
  use AuraWeb, :live_view

  alias Aura.Projects

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    active_tab =
      case params do
        %{"tab" => "subprojects"} -> :subprojects
        %{"tab" => "bom"} -> :bom
        _ -> :overview
      end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:project, Projects.get_project!(id))
     |> assign(:active_tab, active_tab)}
  end

  @impl true
  def handle_params(%{"id" => id, "subproject_id" => subproject_id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:project, Projects.get_project!(id))
     |> assign(:subproject, Projects.get_subproject!(subproject_id))
     |> assign(:active_tab, :subprojects)}
  end

  @impl true
  def handle_params(%{"id" => id, "bom_id" => bom_id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:project, Projects.get_project!(id))
     |> assign(:bom_entry, Projects.get_project_bom!(bom_id))
     |> assign(:active_tab, :bom)}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    active_tab = String.to_atom(tab)
    socket = assign(socket, :active_tab, active_tab)

    # Only push patch for tabs that have dedicated routes
    socket =
      case active_tab do
        :subprojects ->
          push_patch(socket, to: ~p"/projects/#{socket.assigns.project}/subprojects")

        :bom ->
          push_patch(socket, to: ~p"/projects/#{socket.assigns.project}/bom")

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_subproject", %{"id" => id}, socket) do
    subproject = Projects.get_subproject!(id)
    {:ok, _} = Projects.delete_subproject(subproject)

    {:noreply,
     socket
     |> assign(:project, Projects.get_project!(socket.assigns.project.id))
     |> put_flash(:info, "Subproject deleted successfully")}
  end

  @impl true
  def handle_event("delete_bom", %{"id" => id}, socket) do
    bom_entry = Projects.get_project_bom!(id)
    {:ok, _} = Projects.delete_project_bom(bom_entry)

    {:noreply,
     socket
     |> assign(:project, Projects.get_project!(socket.assigns.project.id))
     |> put_flash(:info, "BOM entry deleted successfully")}
  end

  defp page_title(:show), do: "Show Project"
  defp page_title(:edit), do: "Edit Project"
  defp page_title(:new_subproject), do: "New Subproject"
  defp page_title(:edit_subproject), do: "Edit Subproject"
  defp page_title(:new_bom), do: "New BOM Entry"
  defp page_title(:edit_bom), do: "Edit BOM Entry"

  defp status_badge_variant(:in_quote), do: "warning"
  defp status_badge_variant(:in_development), do: "info"
  defp status_badge_variant(:maintenance), do: "success"
  defp status_badge_variant(:done), do: "success"
  defp status_badge_variant(:abandoned), do: "danger"
end
