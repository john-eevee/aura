defmodule Aura.Repo.Migrations.CreateClients do
  use Ecto.Migration

  def change do
    create table(:clients, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :since, :naive_datetime
      add :status, :string
      add :industry_type, :string
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:clients, [:user_id])

    create unique_index(:clients, [:name])
  end
end
