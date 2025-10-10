defmodule Aura.Accounts.AllowlistEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "allowlist_entries" do
    # "email" or "domain"
    field :type, :string
    # email address or domain name
    field :value, :string
    field :description, :string
    field :enabled, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(allowlist_entry, attrs) do
    allowlist_entry
    |> cast(attrs, [:type, :value, :description, :enabled])
    |> validate_required([:type, :value])
    |> validate_inclusion(:type, [email_type(), domain_type()])
    |> validate_format(:value, ~r/^[^\s]+$/, message: "cannot contain spaces")
    |> validate_domain_format()
    |> validate_email_format()
    |> unique_constraint([:type, :value])
  end

  defp validate_domain_format(changeset) do
    type = get_field(changeset, :type)
    value = get_field(changeset, :value)

    if type == domain_type() && value do
      if String.starts_with?(value, "@") do
        # Domain should not start with @
        add_error(changeset, :value, "domain should not start with @")
      else
        changeset
      end
    else
      changeset
    end
  end

  defp validate_email_format(changeset) do
    type = get_field(changeset, :type)
    value = get_field(changeset, :value)

    if type == email_type() && value do
      if String.contains?(value, "@") do
        changeset
      else
        add_error(changeset, :value, "email must contain @")
      end
    else
      changeset
    end
  end

  def domain_type(), do: "domain"
  def email_type(), do: "email"
end
