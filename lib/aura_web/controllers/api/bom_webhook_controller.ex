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
    with {:ok, filename} <- Map.fetch(manifest_params, "filename"),
         {:ok, content} <- Map.fetch(manifest_params, "content"),
         {:ok, result} <- Projects.import_bom_from_manifest(project_id, content, filename) do
      conn
      |> put_status(:created)
      |> json(%{
        success: true,
        created: result.created,
        failed: result.failed,
        message: "Successfully imported #{result.created} dependencies"
      })
    else
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

  def import(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{success: false, error: "Invalid request parameters"})
  end
end
