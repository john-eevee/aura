defmodule Aura.Projects.DependencyParserTest do
  use ExUnit.Case, async: true

  alias Aura.Projects.DependencyParser

  describe "parse_mix_lock/1" do
    test "parses a valid mix.lock file" do
      content = """
      %{
        "phoenix" => {:hex, :phoenix, "1.7.0", "abc123", [:mix], [], "hexpm", "optional"},
        "ecto" => {:hex, :ecto, "3.10.0", "def456", [:mix], [], "hexpm"}
      }
      """

      assert {:ok, dependencies} = DependencyParser.parse_mix_lock(content)
      assert length(dependencies) == 2

      assert Enum.any?(dependencies, fn dep ->
               dep.name == "phoenix" and dep.version == "1.7.0"
             end)

      assert Enum.any?(dependencies, fn dep ->
               dep.name == "ecto" and dep.version == "3.10.0"
             end)
    end

    test "handles empty mix.lock file" do
      content = "%{}"

      assert {:ok, dependencies} = DependencyParser.parse_mix_lock(content)
      assert dependencies == []
    end

    test "returns error for invalid mix.lock format" do
      content = "not a valid elixir term"

      assert {:error, message} = DependencyParser.parse_mix_lock(content)
      assert message =~ "Failed to parse"
    end
  end

  describe "parse_package_json/1" do
    test "parses a valid package.json file" do
      content = """
      {
        "dependencies": {
          "express": "^4.18.0",
          "lodash": "~4.17.21"
        },
        "devDependencies": {
          "jest": ">=29.0.0"
        }
      }
      """

      assert {:ok, dependencies} = DependencyParser.parse_package_json(content)
      assert length(dependencies) == 3

      assert Enum.any?(dependencies, fn dep ->
               dep.name == "express" and dep.version == "4.18.0"
             end)

      assert Enum.any?(dependencies, fn dep ->
               dep.name == "lodash" and dep.version == "4.17.21"
             end)

      assert Enum.any?(dependencies, fn dep ->
               dep.name == "jest" and dep.version == ">=29.0.0"
             end)
    end

    test "handles package.json without dependencies" do
      content = """
      {
        "name": "my-app",
        "version": "1.0.0"
      }
      """

      assert {:ok, dependencies} = DependencyParser.parse_package_json(content)
      assert dependencies == []
    end

    test "returns error for invalid JSON" do
      content = "{not valid json}"

      assert {:error, message} = DependencyParser.parse_package_json(content)
      assert message =~ "Failed to parse"
    end
  end

  describe "parse/2" do
    test "detects and parses mix.lock" do
      content = "%{\"phoenix\" => {:hex, :phoenix, \"1.7.0\", \"abc\", [:mix], [], \"hexpm\"}}"

      assert {:ok, dependencies} = DependencyParser.parse(content, "mix.lock")
      assert length(dependencies) == 1
      assert hd(dependencies).name == "phoenix"
    end

    test "detects and parses package.json" do
      content = "{\"dependencies\": {\"express\": \"4.18.0\"}}"

      assert {:ok, dependencies} = DependencyParser.parse(content, "package.json")
      assert length(dependencies) == 1
      assert hd(dependencies).name == "express"
    end

    test "returns error for unsupported format" do
      content = "some content"

      assert {:error, :unsupported_format} = DependencyParser.parse(content, "unsupported.txt")
    end
  end
end
