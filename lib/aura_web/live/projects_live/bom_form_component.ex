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

      <%= if @action == :new_bom do %>
        <div class="mb-6 p-4 border border-base-300 rounded-lg bg-base-200/50">
          <h3 class="text-lg font-semibold mb-3">Import from Dependency Manifest</h3>
          <p class="text-sm text-base-content/70 mb-4">
            Upload a dependency manifest file (mix.lock, package.json) to automatically import dependencies.
          </p>
          
          <form id="manifest-upload-form" phx-target={@myself} phx-change="validate_manifest" phx-submit="import_manifest">
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium mb-2">
                  Dependency File
                </label>
                <.live_file_input upload={@uploads.manifest} class="file-input file-input-bordered w-full" />
              </div>
              
              <%= for entry <- @uploads.manifest.entries do %>
                <div class="alert alert-info">
                  <.icon name="hero-document-text" class="w-5 h-5" />
                  <span>File ready: {entry.client_name}</span>
                </div>
              <% end %>
              
              <%= if @import_error do %>
                <div class="alert alert-error">
                  <.icon name="hero-exclamation-triangle" class="w-5 h-5" />
                  <span>{@import_error}</span>
                </div>
              <% end %>
              
              <%= if @import_result do %>
                <div class="alert alert-success">
                  <.icon name="hero-check-circle" class="w-5 h-5" />
                  <span>Successfully imported {@import_result.created} dependencies</span>
                  <%= if @import_result.failed > 0 do %>
                    <span class="text-sm"> ({@import_result.failed} failed)</span>
                  <% end %>
                </div>
              <% end %>
              
              <div class="flex gap-2">
                <.button
                  type="submit"
                  class="btn btn-primary"
                  disabled={@uploads.manifest.entries == []}
                >
                  <.icon name="hero-arrow-down-tray" class="w-4 h-4 mr-2" />
                  Import Dependencies
                </.button>
              </div>
            </div>
          </form>
        </div>

        <div class="divider">OR</div>
      <% end %>

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
     |> assign(:import_error, nil)
     |> assign(:import_result, nil)
     |> allow_upload(:manifest, accept: ~w(.lock .json), max_entries: 1)
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

  @impl true
  def handle_event("validate_manifest", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("import_manifest", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :manifest, fn %{path: path}, entry ->
        content = File.read!(path)
        {:ok, %{content: content, filename: entry.client_name}}
      end)

    case uploaded_files do
      [%{content: content, filename: filename}] ->
        project_id = socket.assigns.project.id

        case Projects.import_bom_from_manifest(project_id, content, filename) do
          {:ok, result} ->
            notify_parent({:imported, result})

            {:noreply,
             socket
             |> assign(:import_result, result)
             |> assign(:import_error, nil)
             |> put_flash(:info, "Successfully imported #{result.created} dependencies")}

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:import_error, "Failed to import: #{inspect(reason)}")
             |> assign(:import_result, nil)}
        end

      [] ->
        {:noreply,
         socket
         |> assign(:import_error, "Please select a file first")
         |> assign(:import_result, nil)}
    end
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
