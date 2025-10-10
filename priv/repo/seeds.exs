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

defmodule Seeds do
  require Logger
  alias Aura.Accounts
  alias Aura.Accounts.AllowlistEntry
  alias Aura.Accounts.Permission

  def run do
    is_dev = Mix.env() == :dev

    Logger.info("Running seeds in #{if is_dev, do: "development", else: "production"} mode...")

    create_permissions()
    create_allowlist(is_dev)
    create_admin_user(is_dev)
  end

  defp create_permissions do
    Logger.info("Creating permissions...")

    Permission.permissions()
    |> Enum.each(fn attrs ->
      case Accounts.create_permission(attrs) do
        {:ok, permission} ->
          Logger.info("✓ Created permission: #{permission.name}")

        {:error, changeset} ->
          Logger.error(
            "✗ Failed to create permission #{attrs.name}: #{inspect(changeset.errors)}"
          )
      end
    end)
  end

  defp create_allowlist(is_dev) do
    Logger.info("Setting up allowlist...")

    {domain, admin_email} =
      if is_dev do
        {"example.com", "admin@example.com"}
      else
        domain = IO.gets("Enter a domain to allow (or press Enter to skip): ") |> String.trim()
        admin_email = IO.gets("Enter an admin email to allow: ") |> String.trim()
        {domain, admin_email}
      end

    if domain == "" and admin_email == "" do
      Logger.error("No allowlist entries to create, cannot proceed without at least one entry.")
      raise "No allowlist entries to create, cannot proceed without at least one entry."
    end

    entries =
      [
        %{type: AllowlistEntry.email_type(), value: admin_email, enabled: true}
      ] ++
        if(domain != "",
          do: [%{type: AllowlistEntry.domain_type(), value: domain, enabled: true}],
          else: []
        )

    entries
    |> Enum.each(fn attrs ->
      case Accounts.create_allowlist_entry(attrs) do
        {:ok, entry} ->
          Logger.info("✓ Created allowlist entry: #{entry.type} - #{entry.value}")

        {:error, changeset} ->
          Logger.error(
            "✗ Failed to create allowlist entry #{attrs.type}:#{attrs.value}: #{inspect(changeset.errors)}"
          )

          System.stop(1)
      end
    end)
  end

  defp create_admin_user(is_dev) do
    Logger.info("Setting up admin user...")

    {email, password} =
      if is_dev do
        {"admin@example.com", "password"}
      else
        email = IO.gets("Enter admin email: ") |> String.trim()
        IO.write("Enter admin password: ")
        password = :io.get_password() |> to_string() |> String.trim()
        # Add a newline after password input for better formatting
        IO.puts("")
        {email, password}
      end

    admin_user =
      case Accounts.get_user_by_email(email) do
        nil ->
          case Accounts.register_user(%{email: email, password: password}) do
            {:ok, user} ->
              Logger.info("✓ Created admin user: #{user.email}")
              user

            {:error, changeset} ->
              Logger.error("✗ Failed to create admin user: #{inspect(changeset.errors)}")
              nil
          end

        user ->
          Logger.info("✓ Admin user already exists: #{user.email}")
          user
      end

    confirmed_user =
      if admin_user && is_nil(admin_user.confirmed_at) do
        changeset = Ecto.Changeset.change(admin_user, confirmed_at: DateTime.utc_now(:second))
        {:ok, user} = Aura.Repo.update(changeset)
        Logger.info("✓ Confirmed admin user: #{user.email}")
        user
      else
        admin_user
      end

    if confirmed_user do
      Accounts.list_permissions()
      |> Enum.each(fn permission ->
        case Accounts.assign_permission_to_user(confirmed_user, permission) do
          {:ok, _} ->
            Logger.info("✓ Assigned permission #{permission.name} to admin")

          {:error, changeset} ->
            Logger.error(
              "✗ Failed to assign permission #{permission.name}: #{inspect(changeset.errors)}"
            )
        end
      end)
    end
  end
end

Seeds.run()
