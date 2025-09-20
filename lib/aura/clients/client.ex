defmodule Aura.Clients.Client do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "clients" do
    field :name, :string
    field :since, :naive_datetime
    field :status, Ecto.Enum, values: [:active, :inactive, :terminated]
    field :industry_type, :string
    field :user_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(client, attrs, user_scope) do
    client
    |> cast(attrs, [:name, :since, :status, :industry_type])
    |> validate_required([:name, :since, :status, :industry_type])
    |> unique_constraint(:name)
    |> put_change(:user_id, user_scope.user.id)
  end
end
