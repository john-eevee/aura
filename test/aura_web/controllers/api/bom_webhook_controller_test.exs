defmodule AuraWeb.Api.BOMWebhookControllerTest do
  use AuraWeb.ConnCase, async: true

  import Aura.ProjectsFixtures

  setup context do
    permissions = [
      "view_projects",
      "create_projects",
      "update_projects",
      "delete_projects"
    ]

    register_and_log_in_user_with_permissions(context, permissions)
  end

  describe "POST /api/webhooks/bom/:project_id" do
    setup %{scope: scope} do
      project = project_fixture(scope)
      %{project: project}
    end

    test "imports dependencies from valid mix.lock", %{conn: conn, project: project} do
      manifest_content = """
      %{
        "phoenix" => {:hex, :phoenix, "1.7.0", "abc123", [:mix], [], "hexpm", "optional"},
        "ecto" => {:hex, :ecto, "3.10.0", "def456", [:mix], [], "hexpm"}
      }
      """

      conn =
        post(conn, ~p"/api/webhooks/bom/#{project.id}", %{
          "manifest" => %{
            "filename" => "mix.lock",
            "content" => manifest_content
          }
        })

      assert %{
               "success" => true,
               "created" => 2,
               "failed" => 0,
               "skipped" => 0,
               "message" => message
             } = json_response(conn, 201)

      assert message =~ "Successfully imported 2 dependencies"
    end

    test "imports dependencies from valid package.json", %{conn: conn, project: project} do
      manifest_content = """
      {
        "dependencies": {
          "express": "^4.18.0",
          "lodash": "~4.17.21"
        }
      }
      """

      conn =
        post(conn, ~p"/api/webhooks/bom/#{project.id}", %{
          "manifest" => %{
            "filename" => "package.json",
            "content" => manifest_content
          }
        })

      assert %{
               "success" => true,
               "created" => 2,
               "failed" => 0,
               "skipped" => 0
             } = json_response(conn, 201)
    end

    test "handles duplicate dependencies", %{conn: conn, project: project} do
      manifest_content = """
      %{
        "phoenix" => {:hex, :phoenix, "1.7.0", "abc123", [:mix], [], "hexpm"}
      }
      """

      # First import
      post(conn, ~p"/api/webhooks/bom/#{project.id}", %{
        "manifest" => %{
          "filename" => "mix.lock",
          "content" => manifest_content
        }
      })

      # Second import with same dependency
      conn =
        post(conn, ~p"/api/webhooks/bom/#{project.id}", %{
          "manifest" => %{
            "filename" => "mix.lock",
            "content" => manifest_content
          }
        })

      assert %{
               "success" => true,
               "created" => 0,
               "failed" => 0,
               "skipped" => 1
             } = json_response(conn, 201)
    end

    test "returns error for missing filename", %{conn: conn, project: project} do
      conn =
        post(conn, ~p"/api/webhooks/bom/#{project.id}", %{
          "manifest" => %{
            "content" => "some content"
          }
        })

      assert %{
               "success" => false,
               "error" => error
             } = json_response(conn, 400)

      assert error =~ "Missing required fields"
    end

    test "returns error for missing content", %{conn: conn, project: project} do
      conn =
        post(conn, ~p"/api/webhooks/bom/#{project.id}", %{
          "manifest" => %{
            "filename" => "mix.lock"
          }
        })

      assert %{
               "success" => false,
               "error" => error
             } = json_response(conn, 400)

      assert error =~ "Missing required fields"
    end

    test "returns error for non-existent project", %{conn: conn} do
      fake_project_id = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/webhooks/bom/#{fake_project_id}", %{
          "manifest" => %{
            "filename" => "mix.lock",
            "content" => "%{}"
          }
        })

      assert %{
               "success" => false,
               "error" => "Project not found"
             } = json_response(conn, 404)
    end

    test "returns error for unsupported file format", %{conn: conn, project: project} do
      conn =
        post(conn, ~p"/api/webhooks/bom/#{project.id}", %{
          "manifest" => %{
            "filename" => "unsupported.txt",
            "content" => "some content"
          }
        })

      assert %{
               "success" => false,
               "error" => error
             } = json_response(conn, 422)

      assert error =~ "unsupported_format"
    end

    test "returns error for invalid manifest content", %{conn: conn, project: project} do
      conn =
        post(conn, ~p"/api/webhooks/bom/#{project.id}", %{
          "manifest" => %{
            "filename" => "mix.lock",
            "content" => "not valid elixir"
          }
        })

      assert %{
               "success" => false,
               "error" => error
             } = json_response(conn, 422)

      assert error =~ "Failed to parse"
    end
  end

  describe "POST /api/webhooks/bom/:project_id without authentication" do
    test "requires authentication", %{conn: conn} do
      # Create a new connection without authentication
      conn = build_conn()
      project_id = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/webhooks/bom/#{project_id}", %{
          "manifest" => %{
            "filename" => "mix.lock",
            "content" => "%{}"
          }
        })

      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end

  describe "POST /api/webhooks/bom/:project_id without permissions" do
    setup context do
      # Create a user without update_projects permission
      register_and_log_in_user(context)
    end

    test "requires update_projects permission", %{conn: conn} do
      # Create a project with a different user who has permissions
      admin_conn =
        register_and_log_in_user_with_permissions(%{conn: build_conn()}, [
          "view_projects",
          "create_projects",
          "update_projects"
        ])

      admin_scope = admin_conn.assigns[:scope]
      project = project_fixture(admin_scope)

      # Try to update with unprivileged user
      conn =
        post(conn, ~p"/api/webhooks/bom/#{project.id}", %{
          "manifest" => %{
            "filename" => "mix.lock",
            "content" => "%{}"
          }
        })

      assert %{
               "success" => false,
               "error" => error
             } = json_response(conn, 403)

      assert error =~ "permission"
    end
  end
end
