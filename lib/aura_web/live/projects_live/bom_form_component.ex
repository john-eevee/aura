defmodule AuraWeb.ProjectsLive.BOMFormComponent do
  use AuraWeb, :live_component

  alias Aura.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage bill of materials entries in your database.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="bom-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:tool_name]} type="text" label="Tool Name" />
        <.input field={@form[:version]} type="text" label="Version" />
        <.input
          field={@form[:architecture]}
          type="select"
          label="Architecture"
          options={[
            {"x64", :x64},
            {"ARM64", :arm64},
            {"x86", :x86},
            {"ARM32", :arm32}
          ]}
        /> <.input field={@form[:purpose]} type="textarea" label="Purpose" /> />
        <div class="flex justify-end">
          <.button phx-disable-with="Saving...">Save BOM Entry</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{bom_entry: bom_entry, project: project} = assigns, socket) do
    changeset = Projects.change_project_bom(bom_entry, %{project_id: project.id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"project_bom" => bom_params}, socket) do
    changeset =
      socket.assigns.bom_entry
      |> Projects.change_project_bom(bom_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"project_bom" => bom_params}, socket) do
    save_bom_entry(socket, socket.assigns.action, bom_params)
  end

  defp save_bom_entry(socket, :edit_bom, bom_params) do
    case Projects.update_project_bom(socket.assigns.bom_entry, bom_params) do
      {:ok, bom_entry} ->
        notify_parent({:saved, bom_entry})

        {:noreply,
         socket
         |> put_flash(:info, "BOM entry updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_bom_entry(socket, :new_bom, bom_params) do
    case Projects.create_project_bom(bom_params) do
      {:ok, bom_entry} ->
        notify_parent({:saved, bom_entry})

        {:noreply,
         socket
         |> put_flash(:info, "BOM entry created successfully")
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
