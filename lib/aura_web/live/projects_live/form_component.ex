defmodule AuraWeb.ProjectsLive.FormComponent do
  use AuraWeb, :live_component

  import Ecto.Changeset

  alias Aura.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage project records in your database.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="project-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />

        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          prompt="Select status"
          options={Projects.statuses()}
        />
        <.input field={@form[:goal]} type="textarea" label="Goal" />
        <.input field={@form[:start_date]} type="date" label="Start Date" />
        <.input field={@form[:end_date]} type="date" label="End Date" />

        <div class="flex justify-end gap-4">
          <.button variant="primary" phx-click={JS.patch(@cancel_path)}>Cancel</.button>
          <.button phx-disable-with="Saving...">Save Project</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{project: project, action: action} = assigns, socket) do
    changeset = Projects.change_project(project)

    changeset =
      if action == :new do
        client_id = assigns[:client_id]
        put_change(changeset, :client_id, client_id)
      else
        changeset
      end

    cancel_path =
      if action == :new do
        "/clients/#{assigns[:client_id]}"
      else
        assigns[:patch] || "/projects"
      end

    # Determine if navigation should be a patch (same view) or navigate (different view)
    # If the cancel_path (and patch) starts with /projects/ (project show page), use navigate
    navigate_on_save =
      case cancel_path do
        # Returning to project show page - different view
        "/projects/" <> _ -> true
        # Returning to index or client page - same view
        _ -> false
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:cancel_path, cancel_path)
      |> assign(:navigate_on_save, navigate_on_save)

    {:ok, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset =
      socket.assigns.project
      |> Projects.change_project(project_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"project" => project_params}, socket) do
    save_project(socket, socket.assigns.action, project_params)
  end

  defp save_project(socket, :edit, project_params) do
    case Projects.update_project(
           socket.assigns.current_scope,
           socket.assigns.project,
           project_params
         ) do
      {:ok, project} ->
        notify_parent({:saved, project})

        # Use push_navigate for different LiveViews, push_patch for same view
        result =
          if socket.assigns.navigate_on_save do
            socket
            |> put_flash(:info, "Project updated successfully")
            |> push_navigate(to: socket.assigns.patch)
          else
            socket
            |> put_flash(:info, "Project updated successfully")
            |> push_patch(to: socket.assigns.patch)
          end

        {:noreply, result}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_project(socket, :new, project_params) do
    # merge client id from assigns into project_params
    project_params = Map.put(project_params, "client_id", socket.assigns.client_id)

    case Projects.create_project(socket.assigns.current_scope, project_params) do
      {:ok, project} ->
        notify_parent({:saved, project})

        # Use push_navigate for different LiveViews, push_patch for same view
        result =
          if socket.assigns.navigate_on_save do
            socket
            |> put_flash(:info, "Project created successfully")
            |> push_navigate(to: socket.assigns.patch)
          else
            socket
            |> put_flash(:info, "Project created successfully")
            |> push_patch(to: socket.assigns.patch)
          end

        {:noreply, result}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
