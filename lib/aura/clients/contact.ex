defmodule Aura.Clients.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "contacts" do
    field :name, :string
    field :phone, :string
    field :email, :string
    field :role, :string
    field :user_id, :binary_id
    belongs_to :client, Aura.Clients.Client, type: :binary_id
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(contact, attrs, user_scope) do
    contact
    |> cast(attrs, [:name, :phone, :email, :role, :client_id])
    |> validate_required([:name, :phone, :email, :role])
    |> put_change(:user_id, user_scope.user.id)
  end
end
