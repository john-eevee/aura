defmodule Aura.Documents.DocumentViewer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "document_viewers" do
    belongs_to(:document, Aura.Documents.Document)
    belongs_to(:user, Aura.Accounts.User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(document_viewer, attrs) do
    document_viewer
    |> cast(attrs, [:document_id, :user_id])
    |> validate_required([:document_id, :user_id])
    |> foreign_key_constraint(:document_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:document_id, :user_id])
  end
end
