defmodule Aura.Projects.Subproject do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @platform_values [:web, :android, :ios, :server, :desktop, :other]

  schema "subprojects" do
    field :name, :string
    field :platform, Ecto.Enum, values: @platform_values

    belongs_to :project, Aura.Projects.Project

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(subproject, attrs) do
    subproject
    |> cast(attrs, [:name, :platform, :project_id])
    |> validate_required([:name, :platform, :project_id])
    |> validate_inclusion(:platform, @platform_values)
    |> foreign_key_constraint(:project_id)
  end

  @doc """
  Returns the list of valid platform values.
  """
  def platform_values, do: @platform_values
end
