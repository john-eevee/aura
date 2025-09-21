defmodule Aura.Accounts.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "permissions" do
    field :name, :string
    field :description, :string

    many_to_many :users, Aura.Accounts.User, join_through: Aura.Accounts.UserPermission

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> validate_format(:name, ~r/^[a-z_]+$/, message: "must be lowercase with underscores only")
    |> unique_constraint(:name)
  end
end
