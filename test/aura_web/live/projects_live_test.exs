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

    test "saves new project", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/projects")

      assert index_live |> element("a", "New Project") |> render_click() =~ "New Project"

      assert_patch(index_live, ~p"/projects/new")

      assert index_live
             |> form("#project-form", project: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#project-form", project: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/projects")

      html = render(index_live)
      assert html =~ "some project"
    end

    test "updates project in listing", %{conn: conn, project: project} do
      {:ok, index_live, _html} = live(conn, ~p"/projects")

      assert index_live |> element("#projects-#{project.id} a", "Edit") |> render_click() =~
               "Edit Project"

      assert_patch(index_live, ~p"/projects/#{project}/edit")

      assert index_live
             |> form("#project-form", project: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#project-form", project: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/projects")

      html = render(index_live)
      assert html =~ "some updated project"
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
end
