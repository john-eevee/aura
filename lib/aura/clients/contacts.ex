defmodule Aura.Clients.Contacts do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "contacts" do
    field :name, :string
    field :phone, :string
    field :email, :string
    field :role, :string
    field :client_id, :binary_id
    field :user_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(contacts, attrs, user_scope) do
    contacts
    |> cast(attrs, [:name, :phone, :email, :role])
    |> validate_required([:name, :phone, :email, :role])
    |> put_change(:user_id, user_scope.user.id)
  end
end
