# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Aura.Repo.insert!(%Aura.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Aura.Accounts

# Create permissions
permissions = [
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
  %{name: "system_admin", description: "Full system administration access"}
]

Enum.each(permissions, fn permission_attrs ->
  case Accounts.create_permission(permission_attrs) do
    {:ok, permission} ->
      IO.puts("Created permission: #{permission.name}")

    {:error, changeset} ->
      IO.puts(
        "Failed to create permission #{permission_attrs.name}: #{inspect(changeset.errors)}"
      )
  end
end)
