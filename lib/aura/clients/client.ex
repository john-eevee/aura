defmodule Aura.Clients.Client do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "clients" do
    field :name, :string
    field :since, :date
    field :status, Ecto.Enum, values: [:active, :inactive, :terminated]
    field :industry_type, :string
    field :user_id, :binary_id
    has_many :contacts, Aura.Clients.Contact, on_delete: :delete_all
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(client, attrs, user_scope) do
    client
    |> cast(attrs, [:name, :since, :status, :industry_type])
    |> validate_required([:name, :since, :status, :industry_type])
    |> unique_constraint(:name)
    |> capitalize_name()
    |> capitalize_industry_type()
    |> put_change(:user_id, user_scope.user.id)
  end

  # Capitalize name field (Title Case - good for proper names)
  defp capitalize_name(changeset) do
    case get_change(changeset, :name) do
      nil -> changeset
      name -> put_change(changeset, :name, String.capitalize(name))
    end
  end

  # Capitalize industry type field (Title Case)
  defp capitalize_industry_type(changeset) do
    case get_change(changeset, :industry_type) do
      nil -> changeset
      industry_type -> put_change(changeset, :industry_type, title_case(industry_type))
    end
  end

  # Custom title case function
  defp title_case(string) do
    string
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
