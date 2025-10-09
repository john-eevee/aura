defmodule Aura.Documents.DocumentAuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @action_values [:view, :upload, :update, :delete, :restore, :add_viewer, :remove_viewer]

  schema "document_audit_logs" do
    field(:action, Ecto.Enum, values: @action_values)
    field(:metadata, :map, default: %{})

    belongs_to(:document, Aura.Documents.Document)
    belongs_to(:user, Aura.Accounts.User)

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:action, :metadata, :document_id, :user_id])
    |> validate_required([:action, :document_id, :user_id])
    |> validate_inclusion(:action, @action_values)
    |> foreign_key_constraint(:document_id)
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Returns the list of valid action values.
  """
  def action_values, do: @action_values
end
