defmodule AuraWeb.ProjectsLiveTest do
  use AuraWeb.ConnCase

  import Phoenix.LiveViewTest
  import Aura.ProjectsFixtures

  @create_attrs %{
    name: "some project",
    status: :in_quote,
    description: "some description",
    goal: "some goal",
    start_date: "2025-01-01",
    end_date: "2025-12-31"
  }
  @update_attrs %{
    name: "some updated project",
    status: :in_development,
    description: "some updated description",
    goal: "some updated goal",
    start_date: "2025-01-01",
    end_date: "2025-12-31"
  }
  @invalid_attrs %{
    name: nil,
    status: nil,
    description: nil,
    goal: nil,
    start_date: nil,
    end_date: nil
  }

  defp create_project(%{scope: scope}) do
    project = project_fixture(scope)

    %{project: project}
  end

  describe "Index" do
    setup context do
      permissions = [
        "list_projects",
        "view_projects",
        "create_projects",
        "update_projects",
        "delete_projects",
        "list_clients",
        "create_client"
      ]

      register_and_log_in_user_with_permissions(context, permissions)
    end

    setup [:create_project]

    test "lists all projects", %{conn: conn, project: project} do
      {:ok, _index_live, html} = live(conn, ~p"/projects")

      assert html =~ "Projects"
      assert html =~ project.name
    end

    test "there is no save action", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/projects")

      refute index_live |> element(~s|a[href="/projects/new"]|, "New Project") |> render()
    end

    test "updates project in listing", %{conn: conn, project: project} do
      {:ok, index_live, _html} = live(conn, ~p"/projects")

      assert index_live
             |> element("#projects-#{project.id} a", "Edit")
             |> render_click() =~ "Edit"

      assert_patch(index_live, ~p"/projects/#{project}/edit")

      assert index_live
             |> form("#project-form", project: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#project-form", project: @update_attrs)
             |> render_submit()

      flash = assert_redirect(index_live, ~p"/projects/#{project.id}")
      assert flash["info"] == "Project updated successfully"
    end

    test "deletes project in listing", %{conn: conn, project: project} do
      {:ok, index_live, _html} = live(conn, ~p"/projects")

      assert index_live |> element("#projects-#{project.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#projects-#{project.id}")
    end
  end

  describe "Show" do
    setup context do
      permissions = [
        "list_projects",
        "view_projects",
        "create_projects",
        "update_projects",
        "delete_projects",
        "list_clients",
        "create_client"
      ]

      register_and_log_in_user_with_permissions(context, permissions)
    end

    setup [:create_project]

    test "displays project", %{conn: conn, project: project} do
      {:ok, _show_live, html} = live(conn, ~p"/projects/#{project}")

      assert html =~ project.name
      assert html =~ project.description
    end

    test "updates project and returns to show", %{conn: conn, project: project} do
      {:ok, edit_live, _html} = live(conn, ~p"/projects/#{project}/edit")

      assert edit_live
             |> form("#project-form", project: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert edit_live
             |> form("#project-form", project: @update_attrs)
             |> render_submit()

      assert_patch(edit_live, ~p"/projects/#{project}")

      html = render(edit_live)
      assert html =~ "some updated project"
    end
  end

  describe "Unauthorized access - no permissions" do
    setup :register_and_log_in_user

    test "redirects when accessing projects index without permissions", %{conn: conn} do
      assert {:error, {:redirect, %{to: redirected_to}}} = live(conn, ~p"/projects")
      assert redirected_to == ~p"/"
    end

    test "redirects when accessing project show without permissions", %{conn: conn} do
      # Create a project with permissions first
      admin_conn =
        register_and_log_in_user_with_permissions(%{conn: Phoenix.ConnTest.build_conn()}, [
          "list_projects",
          "view_projects",
          "create_projects",
          "update_projects",
          "delete_projects",
          "list_clients",
          "create_client"
        ])

      admin_scope = admin_conn.scope
      project = project_fixture(admin_scope)

      # Now try to access with unauthorized user (the user from setup has no permissions)
      assert {:error, {:redirect, %{to: redirected_to}}} = live(conn, ~p"/projects/#{project}")
      assert redirected_to == ~p"/projects"
    end
  end

  describe "Unauthorized access - not authenticated" do
    test "redirects when accessing projects index without authentication", %{conn: conn} do
      assert {:error, {:redirect, %{to: redirected_to}}} = live(conn, ~p"/projects")
      assert redirected_to == ~p"/users/log-in"
    end

    test "redirects when accessing project show without authentication", %{conn: conn} do
      # Create a project with permissions first
      admin_conn =
        register_and_log_in_user_with_permissions(%{conn: Phoenix.ConnTest.build_conn()}, [
          "list_projects",
          "view_projects",
          "create_projects",
          "update_projects",
          "delete_projects",
          "list_clients",
          "create_client"
        ])

      admin_scope = admin_conn.scope
      project = project_fixture(admin_scope)

      # Try to access without authentication (using the original conn without user)
      assert {:error, {:redirect, %{to: redirected_to}}} = live(conn, ~p"/projects/#{project}")
      assert redirected_to == ~p"/users/log-in"
    end
  end

  describe "Subprojects" do
    setup context do
      permissions = [
        "list_projects",
        "view_projects",
        "create_projects",
        "update_projects",
        "delete_projects",
        "list_clients",
        "create_client"
      ]

      register_and_log_in_user_with_permissions(context, permissions)
    end

    setup [:create_project]

    test "displays subprojects tab", %{conn: conn, project: project} do
      {:ok, show_live, _html} = live(conn, ~p"/projects/#{project}")

      # Click on subprojects tab
      assert show_live |> element("#subprojects") |> render_click() =~ "Subprojects"
    end

    test "displays empty state when no subprojects exist", %{conn: conn, project: project} do
      {:ok, show_live, _html} = live(conn, ~p"/projects/#{project}?tab=subprojects")

      html = render(show_live)
      assert html =~ "No subprojects"
      assert html =~ "Get started by creating a new subproject"
    end

    test "displays subprojects in table when they exist", %{conn: conn, project: project} do
      _subproject1 = subproject_fixture(project, %{name: "API Service", platform: :server})
      _subproject2 = subproject_fixture(project, %{name: "Mobile App", platform: :android})

      {:ok, show_live, _html} = live(conn, ~p"/projects/#{project}?tab=subprojects")

      html = render(show_live)
      assert html =~ "API Service"
      assert html =~ "Mobile App"
      assert html =~ "Server"
      assert html =~ "Android"
    end

    test "creates new subproject", %{conn: conn, project: project} do
      {:ok, show_live, _html} = live(conn, ~p"/projects/#{project}?tab=subprojects")

      # Click "Add Subproject" button
      assert show_live
             |> element(
               "header a[href='/projects/#{project.id}/subprojects/new']",
               "Add Subproject"
             )
             |> render_click() =~ "New Subproject"

      assert_patch(show_live, ~p"/projects/#{project}/subprojects/new")

      # Submit form with valid data
      assert show_live
             |> form("#subproject-form",
               subproject: %{name: "New API", platform: :web, project_id: project.id}
             )
             |> render_submit()

      assert_patch(show_live, ~p"/projects/#{project}/subprojects")

      html = render(show_live)
      assert html =~ "Subproject created successfully"
      assert html =~ "New API"
    end

    test "validates required fields when creating subproject", %{conn: conn, project: project} do
      {:ok, show_live, _html} = live(conn, ~p"/projects/#{project}?tab=subprojects")

      assert show_live
             |> element(
               "header a[href='/projects/#{project.id}/subprojects/new']",
               "Add Subproject"
             )
             |> render_click()

      # Try to submit with invalid data
      assert show_live
             |> form("#subproject-form", subproject: %{name: "", platform: :web})
             |> render_submit() =~ "can&#39;t be blank"
    end

    test "edits existing subproject", %{conn: conn, project: project} do
      subproject = subproject_fixture(project, %{name: "Original Name", platform: :web})

      {:ok, show_live, _html} = live(conn, ~p"/projects/#{project}?tab=subprojects")

      # Click edit icon
      show_live
      |> element("a[href='/projects/#{project.id}/subprojects/#{subproject.id}/edit']")
      |> render_click()

      assert_patch(show_live, ~p"/projects/#{project}/subprojects/#{subproject}/edit")

      # Update the subproject
      assert show_live
             |> form("#subproject-form",
               subproject: %{name: "Updated Name", platform: :android}
             )
             |> render_submit()

      assert_patch(show_live, ~p"/projects/#{project}/subprojects")

      html = render(show_live)
      assert html =~ "Subproject updated successfully"
      assert html =~ "Updated Name"
      assert html =~ "Android"
      refute html =~ "Original Name"
    end

    test "deletes subproject with confirmation", %{conn: conn, project: project} do
      subproject = subproject_fixture(project, %{name: "To Delete", platform: :ios})

      {:ok, show_live, _html} = live(conn, ~p"/projects/#{project}?tab=subprojects")

      # Verify subproject is displayed
      assert render(show_live) =~ "To Delete"

      # Delete the subproject
      assert show_live
             |> element(
               "a[data-phx-click='delete_subproject'][data-phx-value-id='#{subproject.id}']"
             )
             |> render_click()

      html = render(show_live)
      assert html =~ "Subproject deleted successfully"
      refute html =~ "To Delete"
    end

    test "displays personalized delete confirmation", %{conn: conn, project: project} do
      subproject = subproject_fixture(project, %{name: "Customer API", platform: :web})

      {:ok, show_live, _html} = live(conn, ~p"/projects/#{project}?tab=subprojects")

      # Check that the delete link has the personalized confirmation message
      html = render(show_live)
      assert html =~ "Are you sure you want to delete &#39;Customer API&#39;?"
    end

    test "displays platform badges correctly", %{conn: conn, project: project} do
      subproject_fixture(project, %{name: "Web App", platform: :web})
      subproject_fixture(project, %{name: "Android App", platform: :android})
      subproject_fixture(project, %{name: "iOS App", platform: :ios})
      subproject_fixture(project, %{name: "Server App", platform: :server})
      subproject_fixture(project, %{name: "Desktop App", platform: :desktop})

      {:ok, show_live, _html} = live(conn, ~p"/projects/#{project}?tab=subprojects")

      html = render(show_live)
      assert html =~ "Web"
      assert html =~ "Android"
      assert html =~ "Ios"
      assert html =~ "Server"
      assert html =~ "Desktop"
    end
  end
end
