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
  %{name: "system_admin", description: "Full system administration access"},

  # Allowlist permissions
  %{name: "manage_allowlist", description: "Can manage the user registration allowlist"},
  %{name: "view_allowlist", description: "Can view the user registration allowlist"}
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

# Create default allowlist entries
allowlist_entries = [
  %{type: "domain", value: "example.com", description: "Example company domain", enabled: true},
  %{type: "email", value: "admin@example.com", description: "Admin user", enabled: true}
]

Enum.each(allowlist_entries, fn entry_attrs ->
  case Accounts.create_allowlist_entry(entry_attrs) do
    {:ok, entry} ->
      IO.puts("Created allowlist entry: #{entry.type} - #{entry.value}")

    {:error, changeset} ->
      IO.puts(
        "Failed to create allowlist entry #{entry_attrs.type}:#{entry_attrs.value}: #{inspect(changeset.errors)}"
      )
  end
end)

# Create admin user
admin_attrs = %{
  email: "admin@example.com",
  password: "admin123456789"
}

admin_user =
  case Accounts.get_user_by_email("admin@example.com") do
    nil ->
      # User doesn't exist, create it
      case Accounts.register_user(admin_attrs) do
        {:ok, user} ->
          IO.puts("Created admin user: #{user.email}")
          user

        {:error, changeset} ->
          IO.puts("Failed to create admin user: #{inspect(changeset.errors)}")
          nil
      end

    user ->
      IO.puts("Admin user already exists: #{user.email}")
      user
  end

confirmed_user =
  if admin_user && is_nil(admin_user.confirmed_at) do
    changeset = Ecto.Changeset.change(admin_user, confirmed_at: DateTime.utc_now(:second))
    {:ok, user} = Aura.Repo.update(changeset)
    IO.puts("Confirmed admin user: #{user.email}")
    user
  else
    admin_user
  end

# Assign all permissions to admin if user exists
if confirmed_user do
  all_permissions = Accounts.list_permissions()

  Enum.each(all_permissions, fn permission ->
    case Accounts.assign_permission_to_user(confirmed_user, permission) do
      {:ok, _} ->
        IO.puts("Assigned permission #{permission.name} to admin")

      {:error, changeset} ->
        IO.puts("Failed to assign permission #{permission.name}: #{inspect(changeset.errors)}")
    end
  end)
end
