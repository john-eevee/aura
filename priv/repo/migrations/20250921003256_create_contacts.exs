defmodule Aura.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :phone, :string
      add :email, :string
      add :role, :string
      add :client_id, references(:clients, on_delete: :nothing, type: :binary_id)
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:contacts, [:user_id])

    create index(:contacts, [:client_id])
  end
end
