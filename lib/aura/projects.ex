defmodule Aura.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias Aura.Repo

  alias Aura.Projects.{Project, Subproject, ProjectBOM}
  alias Aura.Accounts.Scope

  ## Database getters

  @doc """
  Gets a single project.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get_project!("123")
      %Project{}

      iex> get_project!("456")
      ** (Ecto.NoResultsError)

  """
  def get_project!(id),
    do: Repo.get!(Project, id) |> Repo.preload([:client])

  @doc """
  Gets a project with preloaded associations.

  ## Examples

      iex> get_project("123")
      %Project{}

      iex> get_project("456")
      nil

  """
  def get_project(id),
    do: Repo.get(Project, id) |> Repo.preload([:client])

  ## Project CRUD

  @doc """
  Returns the list of projects.

  ## Examples

      iex> list_projects(scope)
      [%Project{}, ...]

  """
  def list_projects(%Scope{} = scope) do
    with :ok <- Aura.Accounts.authorize(scope, "list_projects") do
      Repo.all(from(p in Project, preload: [:client]))
    end
  end

  @doc """
  Returns the list of projects for a specific client.

  ## Examples

      iex> list_projects_for_client("client-id")
      [%Project{}, ...]

  """
  def list_projects_for_client(client_id) do
    Repo.all(from p in Project, where: p.client_id == ^client_id, preload: [:client])
  end

  @doc """
  Gets a single project by client and project id.

  ## Examples

      iex> get_project_for_client("client-id", "project-id")
      %Project{}

      iex> get_project_for_client("client-id", "invalid-id")
      nil

  """
  def get_project_for_client(client_id, project_id) do
    Repo.one(
      from p in Project,
        where: p.id == ^project_id and p.client_id == ^client_id,
        preload: [:client, :subprojects, :project_bom]
    )
  end

  @doc """
  Creates a project.

  ## Examples

      iex> create_project(scope, %{field: value})
      {:ok, %Project{}}

      iex> create_project(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(%Scope{} = scope, attrs \\ %{}) do
    with :ok <- Aura.Accounts.authorize(scope, "create_projects") do
      %Project{}
      |> Project.changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc """
  Updates a project.

  ## Examples

      iex> update_project(scope, project, %{field: new_value})
      {:ok, %Project{}}

      iex> update_project(scope, project, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_project(%Scope{} = scope, %Project{} = project, attrs) do
    with :ok <- Aura.Accounts.authorize(scope, "update_projects") do
      project
      |> Project.changeset(attrs)
      |> Repo.update()
    end
  end

  @doc """
  Deletes a project.

  ## Examples

      iex> delete_project(scope, project)
      {:ok, %Project{}}

      iex> delete_project(scope, project)
      {:error, %Ecto.Changeset{}}

  """
  def delete_project(%Scope{} = scope, %Project{} = project) do
    with :ok <- Aura.Accounts.authorize(scope, "delete_projects") do
      Repo.delete(project)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.

  ## Examples

      iex> change_project(project)
      %Ecto.Changeset{data: %Project{}}

  """
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  ## Subproject CRUD

  @doc """
  Returns the list of subprojects for a project.

  ## Examples

      iex> list_subprojects("project-id")
      [%Subproject{}, ...]

  """
  def list_subprojects(project_id) do
    Repo.all(from s in Subproject, where: s.project_id == ^project_id, order_by: s.inserted_at)
  end

  @doc """
  Gets a single subproject.

  Raises `Ecto.NoResultsError` if the Subproject does not exist.

  ## Examples

      iex> get_subproject!("123")
      %Subproject{}

      iex> get_subproject!("456")
      ** (Ecto.NoResultsError)

  """
  def get_subproject!(id), do: Repo.get!(Subproject, id) |> Repo.preload(:project)

  @doc """
  Creates a subproject.

  ## Examples

      iex> create_subproject(%{field: value})
      {:ok, %Subproject{}}

      iex> create_subproject(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subproject(attrs \\ %{}) do
    %Subproject{}
    |> Subproject.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a subproject.

  ## Examples

      iex> update_subproject(subproject, %{field: new_value})
      {:ok, %Subproject{}}

      iex> update_subproject(subproject, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subproject(%Subproject{} = subproject, attrs) do
    subproject
    |> Subproject.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a subproject.

  ## Examples

      iex> delete_subproject(subproject)
      {:ok, %Subproject{}}

      iex> delete_subproject(subproject)
      {:error, %Ecto.Changeset{}}

  """
  def delete_subproject(%Subproject{} = subproject) do
    Repo.delete(subproject)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking subproject changes.

  ## Examples

      iex> change_subproject(subproject)
      %Ecto.Changeset{data: %Subproject{}}

  """
  def change_subproject(%Subproject{} = subproject, attrs \\ %{}) do
    Subproject.changeset(subproject, attrs)
  end

  ## Project BOM CRUD

  @doc """
  Returns the list of BOM entries for a project.

  ## Examples

      iex> list_project_bom("project-id")
      [%ProjectBOM{}, ...]

  """
  def list_project_bom(project_id) do
    Repo.all(from b in ProjectBOM, where: b.project_id == ^project_id, order_by: b.tool_name)
  end

  @doc """
  Gets a single project BOM entry.

  Raises `Ecto.NoResultsError` if the ProjectBOM does not exist.

  ## Examples

      iex> get_project_bom!("123")
      %ProjectBOM{}

      iex> get_project_bom!("456")
      ** (Ecto.NoResultsError)

  """
  def get_project_bom!(id), do: Repo.get!(ProjectBOM, id) |> Repo.preload(:project)

  @doc """
  Creates a project BOM entry.

  ## Examples

      iex> create_project_bom(%{field: value})
      {:ok, %ProjectBOM{}}

      iex> create_project_bom(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project_bom(attrs \\ %{}) do
    %ProjectBOM{}
    |> ProjectBOM.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project BOM entry.

  ## Examples

      iex> update_project_bom(project_bom, %{field: new_value})
      {:ok, %ProjectBOM{}}

      iex> update_project_bom(project_bom, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_project_bom(%ProjectBOM{} = project_bom, attrs) do
    project_bom
    |> ProjectBOM.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project BOM entry.

  ## Examples

      iex> delete_project_bom(project_bom)
      {:ok, %ProjectBOM{}}

      iex> delete_project_bom(project_bom)
      {:error, %Ecto.Changeset{}}

  """
  def delete_project_bom(%ProjectBOM{} = project_bom) do
    Repo.delete(project_bom)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project BOM changes.

  ## Examples

      iex> change_project_bom(project_bom)
      %Ecto.Changeset{data: %ProjectBOM{}}

  """
  def change_project_bom(%ProjectBOM{} = project_bom, attrs \\ %{}) do
    ProjectBOM.changeset(project_bom, attrs)
  end

  def statuses() do
    [
      {"In Quote", :in_quote},
      {"In Development", :in_development},
      {"Maintenance", :maintenance},
      {"Done", :done},
      {"Abandoned", :abandoned}
    ]
  end
end
