defmodule Aura.Accounts.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "permissions" do
    field :name, :string
    field :description, :string

    many_to_many :users, Aura.Accounts.User, join_through: Aura.Accounts.UserPermission

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> validate_format(:name, ~r/^[a-z_]+$/, message: "must be lowercase with underscores only")
    |> unique_constraint(:name)
  end

  @doc """
  The application permissions available for assignment to users.
  """
  @spec permissions() :: list(map())
  def permissions() do
    [
      # User permissions
      %{name: "create_user", description: "Can create new users"},
      %{name: "view_user", description: "Can view user details"},
      %{name: "update_user", description: "Can update user information"},
      %{name: "delete_user", description: "Can delete users"},
      %{name: "list_users", description: "Can list all users"},

      # Client permissions
      %{name: "create_client", description: "Can create new clients"},
      %{name: "view_client", description: "Can view client details"},
      %{name: "update_client", description: "Can update client information"},
      %{name: "delete_client", description: "Can delete clients"},
      %{name: "list_clients", description: "Can list all clients"},

      # Contact permissions
      %{name: "create_contact", description: "Can create new contacts"},
      %{name: "view_contact", description: "Can view contact details"},
      %{name: "update_contact", description: "Can update contact information"},
      %{name: "delete_contact", description: "Can delete contacts"},
      %{name: "list_contacts", description: "Can list all contacts"},

      # Admin permissions
      %{name: "manage_permissions", description: "Can manage user permissions"},
      %{name: "view_audit_logs", description: "Can view system audit logs"},
      %{name: "system_admin", description: "Full system administration access"},

      # Allowlist permissions
      %{name: "manage_allowlist", description: "Can manage the user registration allowlist"},
      %{name: "view_allowlist", description: "Can view the user registration allowlist"},

      # Document permissions
      %{name: "upload_document", description: "Can upload documents to projects"},
      %{name: "view_document", description: "Can view project documents"},
      %{name: "update_document", description: "Can update document information"},
      %{name: "delete_document", description: "Can delete documents"},
      %{name: "manage_document_viewers", description: "Can manage who can view private documents"}
    ]
  end
end
