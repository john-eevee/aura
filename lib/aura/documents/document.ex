defmodule Aura.Documents.Document do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @visibility_values [:public, :private]

  schema "project_documents" do
    field :name, :string
    field :file_path, :string
    field :visibility, Ecto.Enum, values: @visibility_values, default: :private
    field :mime_type, :string
    field :size, :integer
    field :soft_deleted_at, :utc_datetime

    belongs_to :project, Aura.Projects.Project
    belongs_to :uploader, Aura.Accounts.User

    has_many :viewers, Aura.Documents.DocumentViewer
    has_many :audit_logs, Aura.Documents.DocumentAuditLog

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [:name, :file_path, :visibility, :mime_type, :size, :project_id, :uploader_id])
    |> validate_required([:name, :file_path, :visibility, :mime_type, :size, :project_id, :uploader_id])
    |> validate_inclusion(:visibility, @visibility_values)
    |> validate_number(:size, greater_than: 0)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:uploader_id)
  end

  @doc """
  Changeset for soft deleting a document.
  """
  def soft_delete_changeset(document) do
    document
    |> change(soft_deleted_at: DateTime.utc_now())
  end

  @doc """
  Returns the list of valid visibility values.
  """
  def visibility_values, do: @visibility_values
end
