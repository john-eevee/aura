defmodule Aura.Repo.Migrations.CreateProjectDocumentsTables do
  use Ecto.Migration

  def change do
    # Project documents table
    create table(:project_documents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :file_path, :string, null: false
      add :visibility, :string, default: "private", null: false
      add :mime_type, :string, null: false
      add :size, :bigint, null: false
      add :soft_deleted_at, :utc_datetime

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      add :uploader_id, references(:users, type: :binary_id, on_delete: :nilify_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:project_documents, [:project_id])
    create index(:project_documents, [:uploader_id])
    create index(:project_documents, [:visibility])
    create index(:project_documents, [:soft_deleted_at])

    # Document viewers table (for private document access control)
    create table(:document_viewers, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :document_id, references(:project_documents, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:document_viewers, [:document_id])
    create index(:document_viewers, [:user_id])
    create unique_index(:document_viewers, [:document_id, :user_id])

    # Document audit logs table
    create table(:document_audit_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :action, :string, null: false
      add :metadata, :map, default: %{}

      add :document_id, references(:project_documents, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:document_audit_logs, [:document_id])
    create index(:document_audit_logs, [:user_id])
    create index(:document_audit_logs, [:action])
    create index(:document_audit_logs, [:inserted_at])
  end
end
