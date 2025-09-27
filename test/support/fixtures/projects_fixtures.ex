defmodule Aura.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Aura.Projects` context.
  """

  @doc """
  Generate a unique project name.
  """
  def unique_project_name, do: "some project#{System.unique_integer([:positive])}"

  @doc """
  Generate a project.
  """
  def project_fixture(scope, attrs \\ %{}) do
    # Create a client first since projects require a client_id
    client = Aura.ClientsFixtures.client_fixture(scope)

    attrs =
      Enum.into(attrs, %{
        name: unique_project_name(),
        status: :in_quote,
        description: "some description",
        goal: "some goal",
        start_date: ~D[2025-01-01],
        end_date: ~D[2025-12-31],
        client_id: client.id
      })

    {:ok, project} = Aura.Projects.create_project(scope, attrs)
    project
  end

  @doc """
  Generate a subproject.
  """
  def subproject_fixture(project, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "some subproject#{System.unique_integer([:positive])}",
        platform: :web,
        project_id: project.id
      })

    {:ok, subproject} = Aura.Projects.create_subproject(attrs)
    subproject
  end

  @doc """
  Generate a project BOM entry.
  """
  def project_bom_fixture(project, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        tool_name: "some tool#{System.unique_integer([:positive])}",
        version: "1.0.0",
        architecture: :x64,
        project_id: project.id
      })

    {:ok, bom_entry} = Aura.Projects.create_project_bom(attrs)
    bom_entry
  end
end
