defmodule Aura.ProjectsTest do
  use Aura.DataCase, async: true

  alias Aura.Projects

  import Aura.ProjectsFixtures

  setup do
    permissions = [
      "view_projects",
      "create_projects",
      "update_projects",
      "delete_projects"
    ]

    {:ok, scope} = register_scope_with_permissions(permissions)
    project = project_fixture(scope)

    %{scope: scope, project: project}
  end

  describe "create_bom_entries_from_dependencies/2" do
    test "creates BOM entries from list of dependencies", %{project: project} do
      dependencies = [
        %{name: "phoenix", version: "1.7.0"},
        %{name: "ecto", version: "3.10.0"}
      ]

      assert {:ok, result} = Projects.create_bom_entries_from_dependencies(project.id, dependencies)
      assert result.created == 2
      assert result.failed == 0
      assert result.skipped == 0
      assert result.errors == []

      # Verify entries were created
      bom_entries = Projects.list_project_bom(project.id)
      assert length(bom_entries) == 2
      assert Enum.any?(bom_entries, fn e -> e.tool_name == "phoenix" and e.version == "1.7.0" end)
      assert Enum.any?(bom_entries, fn e -> e.tool_name == "ecto" and e.version == "3.10.0" end)
    end

    test "skips duplicate dependencies", %{project: project} do
      dependencies = [
        %{name: "phoenix", version: "1.7.0"}
      ]

      # Create first time
      {:ok, result1} = Projects.create_bom_entries_from_dependencies(project.id, dependencies)
      assert result1.created == 1
      assert result1.skipped == 0

      # Create second time (should skip)
      {:ok, result2} = Projects.create_bom_entries_from_dependencies(project.id, dependencies)
      assert result2.created == 0
      assert result2.skipped == 1

      # Verify only one entry exists
      bom_entries = Projects.list_project_bom(project.id)
      assert length(bom_entries) == 1
    end

    test "handles partial failures gracefully", %{project: project} do
      dependencies = [
        %{name: "valid", version: "1.0.0"},
        %{name: "", version: ""},
        # Empty name should fail validation
        %{name: "another_valid", version: "2.0.0"}
      ]

      {:ok, result} = Projects.create_bom_entries_from_dependencies(project.id, dependencies)

      # Should create the valid ones and report failures
      assert result.created >= 2
      assert result.failed <= 1
    end

    test "returns empty result for empty list", %{project: project} do
      {:ok, result} = Projects.create_bom_entries_from_dependencies(project.id, [])
      assert result.created == 0
      assert result.failed == 0
      assert result.skipped == 0
    end
  end

  describe "import_bom_from_manifest/3" do
    test "imports from valid mix.lock", %{project: project} do
      content = """
      %{
        "phoenix" => {:hex, :phoenix, "1.7.0", "abc", [:mix], [], "hexpm"},
        "ecto" => {:hex, :ecto, "3.10.0", "def", [:mix], [], "hexpm"}
      }
      """

      assert {:ok, result} = Projects.import_bom_from_manifest(project.id, content, "mix.lock")
      assert result.created == 2
      assert result.failed == 0

      bom_entries = Projects.list_project_bom(project.id)
      assert length(bom_entries) == 2
    end

    test "imports from valid package.json", %{project: project} do
      content = """
      {
        "dependencies": {
          "express": "^4.18.0",
          "lodash": "~4.17.21"
        }
      }
      """

      assert {:ok, result} = Projects.import_bom_from_manifest(project.id, content, "package.json")
      assert result.created == 2
      assert result.failed == 0

      bom_entries = Projects.list_project_bom(project.id)
      assert length(bom_entries) == 2
      assert Enum.any?(bom_entries, fn e -> e.tool_name == "express" and e.version == "4.18.0" end)
      assert Enum.any?(bom_entries, fn e -> e.tool_name == "lodash" and e.version == "4.17.21" end)
    end

    test "returns error for unsupported format", %{project: project} do
      content = "some content"

      assert {:error, :unsupported_format} =
               Projects.import_bom_from_manifest(project.id, content, "unsupported.txt")
    end

    test "returns error for invalid mix.lock", %{project: project} do
      content = "not valid elixir"

      assert {:error, message} = Projects.import_bom_from_manifest(project.id, content, "mix.lock")
      assert message =~ "Failed to parse"
    end

    test "returns error for invalid package.json", %{project: project} do
      content = "{not valid json}"

      assert {:error, message} =
               Projects.import_bom_from_manifest(project.id, content, "package.json")

      assert message =~ "Failed to parse"
    end

    test "handles empty manifest", %{project: project} do
      content = "%{}"

      assert {:ok, result} = Projects.import_bom_from_manifest(project.id, content, "mix.lock")
      assert result.created == 0
      assert result.failed == 0
    end
  end

  # Helper function to create a scope with permissions
  defp register_scope_with_permissions(permissions) do
    user = Aura.AccountsFixtures.user_fixture()

    Enum.each(permissions, fn permission ->
      Aura.Accounts.create_permission(%{
        name: permission,
        description: "Test permission"
      })
    end)

    scope = %Aura.Accounts.Scope{
      user: user,
      permissions: permissions
    }

    {:ok, scope}
  end
end
