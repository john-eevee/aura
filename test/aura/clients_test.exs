defmodule Aura.ClientsTest do
  use Aura.DataCase

  alias Aura.Clients

  describe "clients" do
    alias Aura.Clients.Client

    import Aura.AccountsFixtures, only: [user_scope_fixture: 0]
    import Aura.ClientsFixtures

    @invalid_attrs %{name: nil, status: nil, since: nil, industry_type: nil}

    test "list_clients/1 returns all scoped clients" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      client = client_fixture(scope)
      other_client = client_fixture(other_scope)
      assert Clients.list_clients(scope) == [client]
      assert Clients.list_clients(other_scope) == [other_client]
    end

    test "get_client!/2 returns the client with given id" do
      scope = user_scope_fixture()
      client = client_fixture(scope)
      other_scope = user_scope_fixture()
      assert Clients.get_client!(scope, client.id) == client
      assert_raise Ecto.NoResultsError, fn -> Clients.get_client!(other_scope, client.id) end
    end

    test "create_client/2 with valid data creates a client" do
      valid_attrs = %{
        name: "some name",
        status: :active,
        since: ~N[2025-09-19 23:13:00],
        industry_type: "some industry_type"
      }

      scope = user_scope_fixture()

      assert {:ok, %Client{} = client} = Clients.create_client(scope, valid_attrs)
      assert client.name == "some name"
      assert client.status == :active
      assert client.since == ~N[2025-09-19 23:13:00]
      assert client.industry_type == "some industry_type"
      assert client.user_id == scope.user.id
    end

    test "create_client/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Clients.create_client(scope, @invalid_attrs)
    end

    test "update_client/3 with valid data updates the client" do
      scope = user_scope_fixture()
      client = client_fixture(scope)

      update_attrs = %{
        name: "some updated name",
        status: :inactive,
        since: ~N[2025-09-20 23:13:00],
        industry_type: "some updated industry_type"
      }

      assert {:ok, %Client{} = client} = Clients.update_client(scope, client, update_attrs)
      assert client.name == "some updated name"
      assert client.status == :inactive
      assert client.since == ~N[2025-09-20 23:13:00]
      assert client.industry_type == "some updated industry_type"
    end

    test "update_client/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      client = client_fixture(scope)

      assert_raise MatchError, fn ->
        Clients.update_client(other_scope, client, %{})
      end
    end

    test "update_client/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      client = client_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Clients.update_client(scope, client, @invalid_attrs)
      assert client == Clients.get_client!(scope, client.id)
    end

    test "delete_client/2 deletes the client" do
      scope = user_scope_fixture()
      client = client_fixture(scope)
      assert {:ok, %Client{}} = Clients.delete_client(scope, client)
      assert_raise Ecto.NoResultsError, fn -> Clients.get_client!(scope, client.id) end
    end

    test "delete_client/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      client = client_fixture(scope)
      assert_raise MatchError, fn -> Clients.delete_client(other_scope, client) end
    end

    test "change_client/2 returns a client changeset" do
      scope = user_scope_fixture()
      client = client_fixture(scope)
      assert %Ecto.Changeset{} = Clients.change_client(scope, client)
    end
  end

  describe "contacts" do
    alias Aura.Clients.Contact

    import Aura.AccountsFixtures, only: [user_scope_fixture: 0]
    import Aura.ClientsFixtures

    @invalid_attrs %{name: nil, role: nil, phone: nil, email: nil}

    test "list_contacts/1 returns all scoped contacts" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      contact = contact_fixture(scope)
      other_contact = contact_fixture(other_scope)
      assert Clients.list_contacts(scope) == [contact]
      assert Clients.list_contacts(other_scope) == [other_contact]
    end

    test "get_contact!/2 returns the contact with given id" do
      scope = user_scope_fixture()
      contact = contact_fixture(scope)
      other_scope = user_scope_fixture()
      assert Clients.get_contact!(scope, contact.id) == contact
      assert_raise Ecto.NoResultsError, fn -> Clients.get_contact!(other_scope, contact.id) end
    end

    test "create_contact/2 with valid data creates a contact" do
      valid_attrs = %{
        name: "some name",
        role: "some role",
        phone: "some phone",
        email: "some email"
      }

      scope = user_scope_fixture()

      assert {:ok, %Contact{} = contact} = Clients.create_contact(scope, valid_attrs)
      assert contact.name == "some name"
      assert contact.role == "some role"
      assert contact.phone == "some phone"
      assert contact.email == "some email"
      assert contact.user_id == scope.user.id
    end

    test "create_contact/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Clients.create_contact(scope, @invalid_attrs)
    end

    test "update_contact/3 with valid data updates the contact" do
      scope = user_scope_fixture()
      contact = contact_fixture(scope)

      update_attrs = %{
        name: "some updated name",
        role: "some updated role",
        phone: "some updated phone",
        email: "some updated email"
      }

      assert {:ok, %Contact{} = contact} = Clients.update_contact(scope, contact, update_attrs)
      assert contact.name == "some updated name"
      assert contact.role == "some updated role"
      assert contact.phone == "some updated phone"
      assert contact.email == "some updated email"
    end

    test "update_contact/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      contact = contact_fixture(scope)

      assert_raise MatchError, fn ->
        Clients.update_contact(other_scope, contact, %{})
      end
    end

    test "update_contact/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      contact = contact_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Clients.update_contact(scope, contact, @invalid_attrs)
      assert contact == Clients.get_contact!(scope, contact.id)
    end

    test "delete_contact/2 deletes the contact" do
      scope = user_scope_fixture()
      contact = contact_fixture(scope)
      assert {:ok, %Contact{}} = Clients.delete_contact(scope, contact)
      assert_raise Ecto.NoResultsError, fn -> Clients.get_contact!(scope, contact.id) end
    end

    test "delete_contact/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      contact = contact_fixture(scope)
      assert_raise MatchError, fn -> Clients.delete_contact(other_scope, contact) end
    end

    test "change_contact/2 returns a contact changeset" do
      scope = user_scope_fixture()
      contact = contact_fixture(scope)
      assert %Ecto.Changeset{} = Clients.change_contact(scope, contact)
    end
  end
end
