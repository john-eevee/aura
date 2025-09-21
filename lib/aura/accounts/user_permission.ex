defmodule Aura.Accounts.UserPermission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_permissions" do
    belongs_to :user, Aura.Accounts.User
    belongs_to :permission, Aura.Accounts.Permission

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_permission, attrs) do
    user_permission
    |> cast(attrs, [:user_id, :permission_id])
    |> validate_required([:user_id, :permission_id])
    |> unique_constraint([:user_id, :permission_id])
  end
end
