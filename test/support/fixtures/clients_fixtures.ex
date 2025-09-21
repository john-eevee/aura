defmodule Aura.ClientsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Aura.Clients` context.
  """

  @doc """
  Generate a unique client name.
  """
  def unique_client_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a client.
  """
  def client_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        industry_type: "some industry_type",
        name: unique_client_name(),
        since: ~N[2025-09-19 23:13:00],
        status: :active
      })

    {:ok, client} = Aura.Clients.create_client(scope, attrs)
    client
  end

  @doc """
  Generate a contact.
  """
  def contact_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        email: "some email",
        name: "some name",
        phone: "some phone",
        role: "some role"
      })

    {:ok, contact} = Aura.Clients.create_contact(scope, attrs)
    contact
  end
end
