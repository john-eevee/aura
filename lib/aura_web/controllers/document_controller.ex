defmodule AuraWeb.DocumentController do
  use AuraWeb, :controller

  alias Aura.Documents

  def view(conn, %{"project_id" => _project_id, "id" => id}) do
    current_scope = conn.assigns.current_scope

    case Documents.get_document_with_access(current_scope, id) do
      {:ok, document} ->
        Documents.log_document_view(current_scope, document.id)

        case Documents.stream_file(document.file_path) do
          {:ok, stream} ->
            conn
            |> put_resp_header("content-type", document.mime_type)
            |> put_resp_header("content-disposition", "inline; filename=\"#{document.name}\"")
            |> send_chunked(200)
            |> stream_file_chunks(stream)

          {:error, :not_found} ->
            conn
            |> put_flash(:error, "Document file not found")
            |> redirect(to: ~p"/projects/#{document.project_id}/documents")
        end

      {:error, :unauthorized} ->
        conn
        |> put_flash(:error, "You don't have permission to view this document")
        |> redirect(to: ~p"/projects")
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_flash(:error, "Document not found")
      |> redirect(to: ~p"/projects")
  end

  defp stream_file_chunks(conn, stream) do
    Enum.reduce_while(stream, conn, fn chunk, conn ->
      case Plug.Conn.chunk(conn, chunk) do
        {:ok, conn} -> {:cont, conn}
        {:error, _reason} -> {:halt, conn}
      end
    end)
  end
end
