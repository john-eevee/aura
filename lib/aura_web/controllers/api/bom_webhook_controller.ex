defmodule AuraWeb.Api.BOMWebhookController do
  use AuraWeb, :controller

  alias Aura.Projects

  @moduledoc """
  API controller for webhook integration with build tools.
  
  This allows external build systems to push dependency updates
  automatically when dependencies change.
  
  ## Example webhook request:
  
      POST /api/webhooks/bom/:project_id
      Content-Type: application/json
      Authorization: Bearer <token>
      
      {
        "manifest": {
          "filename": "mix.lock",
          "content": "%{\"phoenix\" => {:hex, :phoenix, \"1.7.0\", ...}}"
        }
      }
  
  """

  @doc """
  Webhook endpoint for importing dependencies from a manifest.
  
  Expects a JSON payload with manifest filename and content.
  """
  def import(conn, %{"project_id" => project_id, "manifest" => manifest_params}) do
    current_scope = conn.assigns[:current_scope]

    with :ok <- Aura.Accounts.authorize(current_scope, "update_projects"),
         {:ok, _project} <- validate_project_exists(project_id),
         {:ok, filename} <- Map.fetch(manifest_params, "filename"),
         {:ok, content} <- Map.fetch(manifest_params, "content"),
         {:ok, result} <- Projects.import_bom_from_manifest(project_id, content, filename) do
      conn
      |> put_status(:created)
      |> json(%{
        success: true,
        created: result.created,
        failed: result.failed,
        skipped: result.skipped,
        message: "Successfully imported #{result.created} dependencies",
        errors: format_errors(result.errors)
      })
    else
      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{success: false, error: "You don't have permission to update this project"})

      {:error, :project_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: "Project not found"})

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: "Missing required fields: filename or content"})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  defp validate_project_exists(project_id) do
    case Projects.get_project(project_id) do
      nil -> {:error, :project_not_found}
      project -> {:ok, project}
    end
  end

  defp format_errors([]), do: []

  defp format_errors(errors) do
    Enum.map(errors, fn {:error, changeset_or_reason} ->
      case changeset_or_reason do
        %Ecto.Changeset{} = changeset ->
          Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)

        reason ->
          inspect(reason)
      end
    end)
  end

  def import(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{success: false, error: "Invalid request parameters"})
  end
end
