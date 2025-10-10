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
alias Aura.Accounts.AllowlistEntry
alias Aura.Accounts.Permission

# Create permissions
permissions = Aura.Accounts.Permission.permissions()

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

# Allow list setup
domain = IO.gets("Enter a domain to allow (or press Enter to skip): ") |> String.trim()
admin_email = IO.gets("Enter an admin email to allow: ") |> String.trim()

if domain == "" and admin_email == "" do
  System.stop(1)
  raise "No allowlist entries to create, can not proceed without at least one entry."
end

allowlist_entries =
  [%{type: AllowlistEntry.email_type(), value: admin_email, enabled: true}] ++
    if domain != "",
      do: [%{type: AllowlistEntry.domain_type(), value: domain, enabled: true}],
      else: []

Enum.each(allowlist_entries, fn entry_attrs ->
  case Accounts.create_allowlist_entry(entry_attrs) do
    {:ok, entry} ->
      IO.puts("Created allowlist entry: #{entry.type} - #{entry.value}")

    {:error, changeset} ->
      IO.puts(
        "Failed to create allowlist entry #{entry_attrs.type}:#{entry_attrs.value}: #{inspect(changeset.errors)}"
      )

      System.stop(1)
  end
end)

# Create admin user
admin_attrs = %{
  email: IO.gets("Enter admin email: ") |> String.trim(),
  password: IO.gets("Enter admin password: ") |> String.trim()
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
