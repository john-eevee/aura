defmodule AuraWeb.DocumentsLive.UploadComponent do
  use AuraWeb, :live_component

  alias Aura.Documents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Upload Document
        <:subtitle>Upload a new document to this project.</:subtitle>
      </.header>
      
      <.form
        for={@form}
        id="document-upload-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Document Name" required />
        <.input
          field={@form[:visibility]}
          type="select"
          label="Visibility"
          options={[
            {"Public (All project members)", :public},
            {"Private (Only specific users)", :private}
          ]}
        />
        <div>
          <label class="block text-sm font-medium text-zinc-700">File</label>
          <div
            class="mt-2 flex justify-center rounded-lg border border-dashed border-zinc-300 px-6 py-10"
            phx-drop-target={@uploads.document.ref}
          >
            <div class="text-center">
              <.icon name="hero-document-arrow-up" class="mx-auto h-12 w-12 text-zinc-400" />
              <div class="mt-4 flex text-sm leading-6 text-zinc-600">
                <label
                  for={@uploads.document.ref}
                  class="relative cursor-pointer rounded-md bg-white font-semibold text-blue-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-blue-600 focus-within:ring-offset-2 hover:text-blue-500"
                >
                  <span>Upload a file</span>
                  <.live_file_input upload={@uploads.document} class="sr-only" />
                </label>
                <p class="pl-1">or drag and drop</p>
              </div>
              
              <p class="text-xs leading-5 text-zinc-600">Any file up to 50MB</p>
            </div>
          </div>
          
          <%= for entry <- @uploads.document.entries do %>
            <div class="mt-2 flex items-center justify-between rounded-md border border-zinc-200 px-4 py-2">
              <div class="flex items-center">
                <.icon name="hero-document" class="h-5 w-5 text-zinc-500" />
                <span class="ml-2 text-sm text-zinc-900">{entry.client_name}</span>
                <span class="ml-2 text-xs text-zinc-500">
                  ({Float.round(entry.client_size / 1024 / 1024, 2)} MB)
                </span>
              </div>
              
              <button
                type="button"
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
                phx-target={@myself}
                class="text-zinc-400 hover:text-zinc-600"
              >
                <.icon name="hero-x-mark" class="h-5 w-5" />
              </button>
            </div>
            
            <%= for err <- upload_errors(@uploads.document, entry) do %>
              <p class="mt-1 text-sm text-red-600">{error_to_string(err)}</p>
            <% end %>
          <% end %>
        </div>
        
        <div class="flex justify-end gap-2 mt-4">
          <.button type="button" phx-click={JS.patch(@patch)} variant="secondary">Cancel</.button>
          <.button phx-disable-with="Uploading...">Upload Document</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset = Documents.change_document(%Aura.Documents.Document{}, %{visibility: :private})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> allow_upload(:document,
       accept: :any,
       max_entries: 1,
       max_file_size: 50_000_000
     )}
  end

  @impl true
  def handle_event("validate", %{"document" => document_params}, socket) do
    changeset =
      %Aura.Documents.Document{}
      |> Documents.change_document(document_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :document, ref)}
  end

  def handle_event("save", %{"document" => document_params}, socket) do
    save_document(socket, document_params)
  end

  defp save_document(socket, document_params) do
    uploaded_files =
      consume_uploaded_entries(socket, :document, fn %{path: path}, entry ->
        dest = Path.join(["documents", socket.assigns.project.id, entry.uuid])

        with {:ok, stored_path} <- Documents.store_file(path, dest) do
          {:ok, %{path: stored_path, name: entry.client_name, size: entry.client_size}}
        end
      end)

    case uploaded_files do
      [file_info | _] ->
        document_attrs =
          document_params
          |> Map.put("project_id", socket.assigns.project.id)
          |> Map.put("file_path", file_info.path)
          |> Map.put("mime_type", file_info[:mime_type] || "application/octet-stream")
          |> Map.put("size", file_info.size)
          |> Map.put("name", document_params["name"] || file_info.name)

        case Documents.create_document(socket.assigns.current_scope, document_attrs) do
          {:ok, document} ->
            notify_parent({:saved, document})

            {:noreply,
             socket
             |> put_flash(:info, "Document uploaded successfully")
             |> push_patch(to: socket.assigns.patch)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign_form(socket, changeset)}

          {:error, :unauthorized} ->
            {:noreply,
             socket
             |> put_flash(:error, "You don't have permission to upload documents")
             |> push_patch(to: socket.assigns.patch)}
        end

      [] ->
        {:noreply, put_flash(socket, :error, "Please select a file to upload")}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp error_to_string(:too_large), do: "File is too large (max 50MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted"
  defp error_to_string(:too_many_files), do: "Only one file allowed"
  defp error_to_string(err), do: "Upload error: #{inspect(err)}"
end
