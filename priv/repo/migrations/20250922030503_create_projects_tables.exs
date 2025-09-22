defmodule Aura.Repo.Migrations.CreateProjectsTables do
  use Ecto.Migration

  def change do
    # Projects table
    create table(:projects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :status, :string, default: "in_quote"
      add :description, :text
      add :goal, :text
      add :start_date, :date
      add :end_date, :date
      add :client_id, references(:clients, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:projects, [:client_id])
    create index(:projects, [:status])

    # Subprojects table
    create table(:subprojects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :platform, :string, null: false

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:subprojects, [:project_id])

    # Project BOM table
    create table(:project_bom, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tool_name, :string, null: false
      add :version, :string, null: false
      add :architecture, :string

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:project_bom, [:project_id])
  end
end
