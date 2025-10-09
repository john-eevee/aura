defmodule Aura.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @status_values [:in_quote, :in_development, :maintenance, :done, :abandoned]

  schema "projects" do
    field(:name, :string)
    field(:status, Ecto.Enum, values: @status_values, default: :in_quote)
    field(:description, :string)
    field(:goal, :string)
    field(:start_date, :date)
    field(:end_date, :date)

    belongs_to(:client, Aura.Clients.Client)

    has_many(:subprojects, Aura.Projects.Subproject)
    has_many(:project_bom, Aura.Projects.ProjectBOM)
    has_many(:documents, Aura.Documents.Document)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :status, :description, :goal, :start_date, :end_date, :client_id])
    # TODO: Add client_id back when scope is available
    |> validate_required([:name])
    |> validate_inclusion(:status, @status_values)
    |> foreign_key_constraint(:client_id)
  end

  @doc """
  Returns the list of valid status values.
  """
  def status_values, do: @status_values
end
