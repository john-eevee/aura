defmodule AuraWeb.ProjectsLive.FormComponent do
  use AuraWeb, :live_component

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
        <!-- TODO: Add client selection when scope is available -->
        <!-- <.input
          field={@form[:client_id]}
          type="select"
          label="Client"
          options={Enum.map(@clients, &{&1.name, &1.id})}
        /> -->
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          options={[
            {"In Quote", :in_quote},
            {"In Development", :in_development},
            {"Maintenance", :maintenance},
            {"Done", :done},
            {"Abandoned", :abandoned}
          ]}
        />

        <div class="flex justify-end">
          <.button phx-disable-with="Saving...">Save Project</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{project: project} = assigns, socket) do
    changeset = Projects.change_project(project)

    {:ok,
     socket
     |> assign(assigns)
     # TODO: Add client selection when scope is available
     |> assign(:clients, [])
     |> assign_form(changeset)}
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
    case Projects.update_project(socket.assigns.project, project_params) do
      {:ok, project} ->
        notify_parent({:saved, project})

        {:noreply,
         socket
         |> put_flash(:info, "Project updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_project(socket, :new, project_params) do
    case Projects.create_project(project_params) do
      {:ok, project} ->
        notify_parent({:saved, project})

        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
