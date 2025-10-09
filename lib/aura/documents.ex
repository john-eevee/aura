defmodule Aura.Documents do
  @moduledoc """
  The Documents context.
  """

  import Ecto.Query, warn: false
  alias Aura.Repo

  alias Aura.Documents.{Document, DocumentViewer, DocumentAuditLog}
  alias Aura.Accounts.Scope

  @doc """
  Returns the list of documents for a project.
  Only returns non-deleted documents by default.
  """
  def list_project_documents(%Scope{} = scope, project_id, opts \\ []) do
    include_deleted = Keyword.get(opts, :include_deleted, false)

    query =
      from d in Document,
        where: d.project_id == ^project_id,
        preload: [:uploader, :viewers]

    query =
      if include_deleted do
        query
      else
        from d in query, where: is_nil(d.soft_deleted_at)
      end

    query
    |> filter_by_visibility(scope)
    |> Repo.all()
  end

  @doc """
  Gets a single document.
  """
  def get_document!(id) do
    Repo.get!(Document, id) |> Repo.preload([:project, :uploader, :viewers])
  end

  @doc """
  Gets a single document if the user has access to it.
  """
  def get_document_with_access(%Scope{} = scope, id) do
    document = get_document!(id)

    if can_view_document?(scope, document) do
      {:ok, document}
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Creates a document.
  """
  def create_document(%Scope{} = scope, attrs \\ %{}) do
    with :ok <- Aura.Accounts.authorize(scope, "upload_document") do
      attrs = Map.put(attrs, :uploader_id, scope.user.id)

      %Document{}
      |> Document.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, document} ->
          log_audit(document.id, scope.user.id, :upload)
          {:ok, document}

        error ->
          error
      end
    end
  end

  @doc """
  Updates a document.
  """
  def update_document(%Scope{} = scope, %Document{} = document, attrs) do
    with :ok <- authorize_document_action(scope, document, "update_document") do
      document
      |> Document.changeset(attrs)
      |> Repo.update()
      |> case do
        {:ok, updated_document} ->
          log_audit(document.id, scope.user.id, :update)
          {:ok, updated_document}

        error ->
          error
      end
    end
  end

  @doc """
  Soft deletes a document.
  """
  def soft_delete_document(%Scope{} = scope, %Document{} = document) do
    with :ok <- authorize_document_action(scope, document, "delete_document") do
      document
      |> Document.soft_delete_changeset()
      |> Repo.update()
      |> case do
        {:ok, deleted_document} ->
          log_audit(document.id, scope.user.id, :delete)
          {:ok, deleted_document}

        error ->
          error
      end
    end
  end

  @doc """
  Permanently deletes a document and its file from storage.
  """
  def delete_document_permanently(%Document{} = document) do
    storage_adapter = storage_adapter()

    with {:ok, _} <- Repo.delete(document),
         :ok <- storage_adapter.delete(document.file_path) do
      :ok
    end
  end

  @doc """
  Changes a document.
  """
  def change_document(%Document{} = document, attrs \\ %{}) do
    Document.changeset(document, attrs)
  end

  @doc """
  Stores a file using the configured storage adapter.
  """
  def store_file(file_path, destination, opts \\ []) do
    storage_adapter = storage_adapter()
    storage_adapter.store(file_path, destination, opts)
  end

  @doc """
  Streams a file from storage.
  """
  def stream_file(path, opts \\ []) do
    storage_adapter = storage_adapter()
    storage_adapter.stream(path, opts)
  end

  @doc """
  Adds a viewer to a private document.
  """
  def add_document_viewer(%Scope{} = scope, document_id, user_id) do
    with :ok <- Aura.Accounts.authorize(scope, "manage_document_viewers"),
         document <- get_document!(document_id),
         :ok <- authorize_document_action(scope, document, "manage_document_viewers") do
      %DocumentViewer{}
      |> DocumentViewer.changeset(%{document_id: document_id, user_id: user_id})
      |> Repo.insert()
      |> case do
        {:ok, viewer} ->
          log_audit(document_id, scope.user.id, :add_viewer, %{viewer_user_id: user_id})
          {:ok, viewer}

        error ->
          error
      end
    end
  end

  @doc """
  Removes a viewer from a private document.
  """
  def remove_document_viewer(%Scope{} = scope, document_id, user_id) do
    with :ok <- Aura.Accounts.authorize(scope, "manage_document_viewers"),
         document <- get_document!(document_id),
         :ok <- authorize_document_action(scope, document, "manage_document_viewers") do
      viewer =
        Repo.get_by(DocumentViewer, document_id: document_id, user_id: user_id)

      if viewer do
        Repo.delete(viewer)
        log_audit(document_id, scope.user.id, :remove_viewer, %{viewer_user_id: user_id})
        {:ok, viewer}
      else
        {:error, :not_found}
      end
    end
  end

  @doc """
  Logs document access for audit trail.
  """
  def log_document_view(%Scope{} = scope, document_id) do
    log_audit(document_id, scope.user.id, :view)
  end

  @doc """
  Returns documents that are eligible for permanent deletion.
  """
  def list_documents_for_cleanup(days_after_deletion \\ 30) do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-days_after_deletion, :day)

    Repo.all(
      from d in Document,
        where: not is_nil(d.soft_deleted_at),
        where: d.soft_deleted_at < ^cutoff_date
    )
  end

  # Private functions

  defp filter_by_visibility(query, %Scope{user: user}) do
    from d in query,
      left_join: v in DocumentViewer,
      on: v.document_id == d.id,
      where:
        d.visibility == :public or d.uploader_id == ^user.id or v.user_id == ^user.id,
      distinct: true
  end

  defp can_view_document?(%Scope{user: user}, %Document{} = document) do
    cond do
      document.visibility == :public ->
        true

      document.uploader_id == user.id ->
        true

      true ->
        Repo.exists?(
          from v in DocumentViewer,
            where: v.document_id == ^document.id and v.user_id == ^user.id
        )
    end
  end

  defp authorize_document_action(%Scope{user: user} = scope, %Document{} = document, permission) do
    is_admin = Aura.Accounts.user_has_permission?(user, "system_admin")
    is_uploader = document.uploader_id == user.id

    cond do
      is_admin ->
        :ok

      is_uploader ->
        Aura.Accounts.authorize(scope, permission)

      true ->
        {:error, :unauthorized}
    end
  end

  defp log_audit(document_id, user_id, action, metadata \\ %{}) do
    %DocumentAuditLog{}
    |> DocumentAuditLog.changeset(%{
      document_id: document_id,
      user_id: user_id,
      action: action,
      metadata: metadata
    })
    |> Repo.insert()
  end

  defp storage_adapter do
    Application.get_env(:aura, :storage_adapter, Aura.Storage.Local)
  end
end
