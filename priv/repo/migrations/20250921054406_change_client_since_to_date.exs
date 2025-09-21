defmodule Aura.Repo.Migrations.ChangeClientSinceToDate do
  use Ecto.Migration

  def change do
    alter table(:clients) do
      modify :since, :date
    end
  end
end
