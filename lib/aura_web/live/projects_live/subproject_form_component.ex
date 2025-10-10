defmodule AuraWeb.ProjectsLive.SubprojectFormComponent do
  use AuraWeb, :live_component

  alias Aura.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage subproject records in your database.</:subtitle>
      </.header>
      
      <.form
        for={@form}
        id="subproject-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input
          field={@form[:platform]}
          type="select"
          label="Platform"
          options={[
            {"Web", :web},
            {"Android", :android},
            {"iOS", :ios},
            {"Server", :server},
            {"Desktop", :desktop},
            {"Other", :other}
          ]}
        />
        <div class="flex justify-end">
          <.button phx-disable-with="Saving...">Save Subproject</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{subproject: subproject, project: project} = assigns, socket) do
    changeset = Projects.change_subproject(subproject, %{project_id: project.id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"subproject" => subproject_params}, socket) do
    changeset =
      socket.assigns.subproject
      |> Projects.change_subproject(subproject_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"subproject" => subproject_params}, socket) do
    save_subproject(socket, socket.assigns.action, subproject_params)
  end

  defp save_subproject(socket, :edit_subproject, subproject_params) do
    case Projects.update_subproject(socket.assigns.subproject, subproject_params) do
      {:ok, subproject} ->
        notify_parent({:saved, subproject})

        {:noreply,
         socket
         |> put_flash(:info, "Subproject updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_subproject(socket, :new_subproject, subproject_params) do
    case Projects.create_subproject(subproject_params) do
      {:ok, subproject} ->
        notify_parent({:saved, subproject})

        {:noreply,
         socket
         |> put_flash(:info, "Subproject created successfully")
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
