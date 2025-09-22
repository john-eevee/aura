defmodule Aura.Projects.ProjectBOM do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @architecture_values [:x64, :arm64, :x86, :arm32]

  schema "project_bom" do
    field :tool_name, :string
    field :version, :string
    field :architecture, Ecto.Enum, values: @architecture_values

    belongs_to :project, Aura.Projects.Project

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project_bom, attrs) do
    project_bom
    |> cast(attrs, [:tool_name, :version, :architecture, :project_id])
    |> validate_required([:tool_name, :version, :project_id])
    |> validate_inclusion(:architecture, @architecture_values,
      message: "must be one of: #{Enum.join(@architecture_values, ", ")}"
    )
    |> foreign_key_constraint(:project_id)
  end

  @doc """
  Returns the list of valid architecture values.
  """
  def architecture_values, do: @architecture_values
end
