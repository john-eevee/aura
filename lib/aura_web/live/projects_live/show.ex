defmodule AuraWeb.ProjectsLive.Show do
  use AuraWeb, :live_view

  alias Aura.Projects
  alias Aura.Documents

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_user, socket.assigns.current_scope.user)
     |> assign(:current_scope, socket.assigns.current_scope)
     |> assign(:documents, [])
     |> assign(:subprojects, [])
     |> assign(:bom_entries, [])}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    with :ok <- Aura.Accounts.authorize(socket.assigns.current_scope, "view_projects") do
      active_tab =
        case params do
          %{"tab" => "subprojects-tab"} -> :subprojects
          %{"tab" => "bom-tab"} -> :bom
          %{"tab" => "documents-tab"} -> :documents
          _ -> :overview
        end

      project = Projects.get_project!(id)

      socket =
        socket
        |> assign(:page_title, page_title(socket.assigns.live_action))
        |> assign(:project, project)
        |> assign(:active_tab, active_tab)

      socket =
        case socket.assigns.live_action do
          :new_subproject ->
            socket
            |> assign(:subproject, %Aura.Projects.Subproject{})
            |> assign(:active_tab, :subprojects)

          :edit_subproject ->
            subproject = Aura.Projects.get_subproject!(params["subproject_id"])

            socket
            |> assign(:subproject, subproject)
            |> assign(:active_tab, :subprojects)

          :new_bom ->
            socket
            |> assign(:bom_entry, %Aura.Projects.ProjectBOM{})
            |> assign(:active_tab, :bom)

          :edit_bom ->
            socket
            |> assign(:active_tab, :bom)

          _ ->
            socket
        end

      {:noreply, socket}
    else
      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to view this project.")
         |> redirect(to: ~p"/projects")}
    end
  end

  @impl true
  def handle_params(%{"id" => id, "subproject_id" => subproject_id}, _, socket) do
    with :ok <- Aura.Accounts.authorize(socket.assigns.current_scope, "view_projects") do
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:project, Projects.get_project!(id))
       |> assign(:subproject, Projects.get_subproject!(subproject_id))
       |> assign(:active_tab, :subprojects)}
    else
      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to view this project.")
         |> redirect(to: ~p"/projects")}
    end
  end

  @impl true
  def handle_params(%{"id" => id, "bom_id" => bom_id}, _, socket) do
    with :ok <- Aura.Accounts.authorize(socket.assigns.current_scope, "view_projects") do
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:project, Projects.get_project!(id))
       |> assign(:bom_entry, Projects.get_project_bom!(bom_id))
       |> assign(:active_tab, :bom)}
    else
      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to view this project.")
         |> redirect(to: ~p"/projects")}
    end
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    # extract data from params
    active_tab = String.to_existing_atom(tab)
    current_scope = socket.assigns.current_scope
    project = socket.assigns.project

    # setup assign with initial data
    socket = assign(socket, :active_tab, active_tab)

    case active_tab do
      :documents ->
        documents = Documents.list_project_documents(current_scope, project.id)
        assign(socket, :documents, documents)

      :subprojects ->
        subprojects = Projects.list_subprojects(project.id)
        assign(socket, :subprojects, subprojects)

      :bom ->
        bom_entries = Projects.list_project_bom(project.id)
        assign(socket, :bom_entries, bom_entries)

      _else ->
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

  @impl true
  def handle_event("delete_document", %{"id" => id}, socket) do
    document = Documents.get_document!(id)

    case Documents.soft_delete_document(socket.assigns.current_scope, document) do
      {:ok, _} ->
        documents =
          Documents.list_project_documents(
            socket.assigns.current_scope,
            socket.assigns.project.id
          )

        {:noreply,
         socket
         |> assign(:documents, documents)
         |> put_flash(:info, "Document deleted successfully")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to delete this document")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete document")}
    end
  end

  @impl true
  def handle_info({AuraWeb.DocumentsLive.UploadComponent, {:saved, _document}}, socket) do
    documents =
      Documents.list_project_documents(socket.assigns.current_scope, socket.assigns.project.id)

    {:noreply, assign(socket, documents: documents)}
  end

  @impl true
  def handle_info({AuraWeb.ProjectsLive.SubprojectFormComponent, {:saved, _subproject}}, socket) do
    {:noreply, assign(socket, :project, Projects.get_project!(socket.assigns.project.id))}
  end

  @impl true
  def handle_info({AuraWeb.ProjectsLive.BOMFormComponent, {:saved, _bom_entry}}, socket) do
    {:noreply, assign(socket, :project, Projects.get_project!(socket.assigns.project.id))}
  end

  defp page_title(:show), do: "Show Project"
  defp page_title(:edit), do: "Edit Project"
  defp page_title(:new_subproject), do: "New Subproject"
  defp page_title(:edit_subproject), do: "Edit Subproject"
  defp page_title(:new_bom), do: "New BOM Entry"
  defp page_title(:edit_bom), do: "Edit BOM Entry"
  defp page_title(:upload_document), do: "Upload Document"

  defp status_badge_variant(:in_quote), do: "warning"
  defp status_badge_variant(:in_development), do: "info"
  defp status_badge_variant(:maintenance), do: "success"
  defp status_badge_variant(:done), do: "success"
  defp status_badge_variant(:abandoned), do: "danger"
end
