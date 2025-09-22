defmodule Aura.Repo.Migrations.CreateAllowlistEntries do
  use Ecto.Migration

  def change do
    create table(:allowlist_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      # "email" or "domain"
      add :type, :string, null: false
      # email address or domain name
      add :value, :string, null: false
      add :description, :text
      add :enabled, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:allowlist_entries, [:type, :value])
    create index(:allowlist_entries, [:enabled])
  end
end
