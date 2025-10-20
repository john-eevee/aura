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
    create_sample_projects(is_dev)
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

  defp create_sample_projects(is_dev) do
    if is_dev do
      create_sample_projects_dev()
    else
      should_create =
        IO.gets("Would you like to create sample project data? (y/n): ")
        |> String.trim()
        |> String.downcase()

      if should_create == "y" do
        create_sample_projects_dev()
      else
        Logger.info("Skipping sample project creation.")
      end
    end
  end

  defp create_sample_projects_dev do
    require Logger
    alias Aura.Clients
    alias Aura.Projects
    alias Aura.Accounts

    Logger.info("Creating sample projects and clients...")

    # Get the first user (admin) to use as the scope
    admin_user = Accounts.get_user_by_email("admin@example.com")

    if admin_user do
      scope = %Aura.Accounts.Scope{user: admin_user}

      # Sample projects with clients
      projects_data = [
        %{
          client_name: "TechCorp Solutions",
          client_industry: "Technology",
          project_name: "E-Commerce Platform Redesign",
          description:
            "Complete redesign of the customer-facing e-commerce platform with modern UI/UX, improved performance, and mobile-first approach. Includes migration from legacy stack to modern technologies.",
          goal:
            "Deliver a fully responsive e-commerce platform with 50% faster load times, improved conversion rate by 25%, and seamless checkout experience across all devices. Target completion within Q1 2025.",
          start_date: ~D[2025-01-15],
          end_date: ~D[2025-03-31],
          subprojects: [
            "Frontend Redesign",
            "Backend API Migration",
            "Database Optimization",
            "Mobile App Integration"
          ]
        },
        %{
          client_name: "FitLife Inc",
          client_industry: "Health & Wellness",
          project_name: "Fitness Tracker Mobile App",
          description:
            "Native iOS and Android mobile application for tracking workouts, nutrition, and health metrics with real-time synchronization to cloud backend and social sharing features.",
          goal:
            "Launch on both App Store and Google Play with minimum 4.5 star rating, 10k+ downloads in first month, and full offline support for workout tracking.",
          start_date: ~D[2025-02-01],
          end_date: ~D[2025-04-30],
          subprojects: [
            "iOS Development",
            "Android Development",
            "Cloud Backend",
            "Social Features",
            "Analytics Integration"
          ]
        },
        %{
          client_name: "DataViz Analytics",
          client_industry: "Software/SaaS",
          project_name: "Dashboard Analytics Platform",
          description:
            "Build an internal analytics dashboard to consolidate metrics from multiple data sources, providing real-time insights into business KPIs and customer behavior patterns.",
          goal:
            "Enable data-driven decision making across all departments, reduce reporting time from 4 hours to 15 minutes, and provide self-service analytics capabilities to non-technical users.",
          start_date: ~D[2025-01-10],
          end_date: ~D[2025-02-28],
          subprojects: [
            "Data Pipeline",
            "Dashboard UI",
            "Real-time Updates",
            "Export Functionality",
            "User Access Control"
          ]
        }
      ]

      projects_data
      |> Enum.each(fn project_data ->
        # Create or get client
        client = create_or_get_client(scope, project_data)

        if client do
          # Create project
          project_attrs = %{
            name: project_data.project_name,
            description: project_data.description,
            goal: project_data.goal,
            start_date: project_data.start_date,
            end_date: project_data.end_date,
            status: :in_development,
            client_id: client.id
          }

          case Projects.create_project(scope, project_attrs) do
            {:ok, project} ->
              Logger.info("✓ Created project: #{project.name}")

              # Create subprojects
              project_data.subprojects
              |> Enum.each(fn subproject_name ->
                subproject_attrs = %{
                  name: subproject_name,
                  platform: Enum.random([:web, :android, :ios, :server, :desktop, :other]),
                  project_id: project.id
                }

                case Projects.create_subproject(subproject_attrs) do
                  {:ok, subproject} ->
                    Logger.info("  ✓ Created subproject: #{subproject.name}")

                  {:error, changeset} ->
                    Logger.error(
                      "  ✗ Failed to create subproject #{subproject_name}: #{inspect(changeset.errors)}"
                    )
                end
              end)

            {:error, changeset} ->
              Logger.error(
                "✗ Failed to create project #{project_data.project_name}: #{inspect(changeset.errors)}"
              )
          end
        end
      end)
    else
      Logger.error("✗ Admin user not found, cannot create sample projects.")
    end
  end

  defp create_or_get_client(scope, project_data) do
    require Logger
    alias Aura.Clients

    case Clients.list_clients(scope) do
      clients when is_list(clients) ->
        # Check if client already exists
        Enum.find(clients, fn c -> c.name == project_data.client_name end) ||
          create_client(scope, project_data)

      {:error, _} ->
        create_client(scope, project_data)
    end
  end

  defp create_client(scope, project_data) do
    require Logger
    alias Aura.Clients

    client_attrs = %{
      name: project_data.client_name,
      industry_type: project_data.client_industry,
      status: :active,
      since: Date.add(Date.utc_today(), -365)
    }

    case Clients.create_client(scope, client_attrs) do
      {:ok, client} ->
        Logger.info("✓ Created client: #{client.name}")
        client

      {:error, changeset} ->
        Logger.error(
          "✗ Failed to create client #{project_data.client_name}: #{inspect(changeset.errors)}"
        )

        nil
    end
  end
end

Seeds.run()
