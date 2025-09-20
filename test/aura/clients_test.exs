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
      valid_attrs = %{name: "some name", status: :active, since: ~N[2025-09-19 23:13:00], industry_type: "some industry_type"}
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
      update_attrs = %{name: "some updated name", status: :inactive, since: ~N[2025-09-20 23:13:00], industry_type: "some updated industry_type"}

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
    alias Aura.Clients.Contacts

    import Aura.AccountsFixtures, only: [user_scope_fixture: 0]
    import Aura.ClientsFixtures

    @invalid_attrs %{name: nil, role: nil, phone: nil, email: nil}

    test "list_contacts/1 returns all scoped contacts" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      contacts = contacts_fixture(scope)
      other_contacts = contacts_fixture(other_scope)
      assert Clients.list_contacts(scope) == [contacts]
      assert Clients.list_contacts(other_scope) == [other_contacts]
    end

    test "get_contacts!/2 returns the contacts with given id" do
      scope = user_scope_fixture()
      contacts = contacts_fixture(scope)
      other_scope = user_scope_fixture()
      assert Clients.get_contacts!(scope, contacts.id) == contacts
      assert_raise Ecto.NoResultsError, fn -> Clients.get_contacts!(other_scope, contacts.id) end
    end

    test "create_contacts/2 with valid data creates a contacts" do
      valid_attrs = %{name: "some name", role: "some role", phone: "some phone", email: "some email"}
      scope = user_scope_fixture()

      assert {:ok, %Contacts{} = contacts} = Clients.create_contacts(scope, valid_attrs)
      assert contacts.name == "some name"
      assert contacts.role == "some role"
      assert contacts.phone == "some phone"
      assert contacts.email == "some email"
      assert contacts.user_id == scope.user.id
    end

    test "create_contacts/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Clients.create_contacts(scope, @invalid_attrs)
    end

    test "update_contacts/3 with valid data updates the contacts" do
      scope = user_scope_fixture()
      contacts = contacts_fixture(scope)
      update_attrs = %{name: "some updated name", role: "some updated role", phone: "some updated phone", email: "some updated email"}

      assert {:ok, %Contacts{} = contacts} = Clients.update_contacts(scope, contacts, update_attrs)
      assert contacts.name == "some updated name"
      assert contacts.role == "some updated role"
      assert contacts.phone == "some updated phone"
      assert contacts.email == "some updated email"
    end

    test "update_contacts/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      contacts = contacts_fixture(scope)

      assert_raise MatchError, fn ->
        Clients.update_contacts(other_scope, contacts, %{})
      end
    end

    test "update_contacts/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      contacts = contacts_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Clients.update_contacts(scope, contacts, @invalid_attrs)
      assert contacts == Clients.get_contacts!(scope, contacts.id)
    end

    test "delete_contacts/2 deletes the contacts" do
      scope = user_scope_fixture()
      contacts = contacts_fixture(scope)
      assert {:ok, %Contacts{}} = Clients.delete_contacts(scope, contacts)
      assert_raise Ecto.NoResultsError, fn -> Clients.get_contacts!(scope, contacts.id) end
    end

    test "delete_contacts/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      contacts = contacts_fixture(scope)
      assert_raise MatchError, fn -> Clients.delete_contacts(other_scope, contacts) end
    end

    test "change_contacts/2 returns a contacts changeset" do
      scope = user_scope_fixture()
      contacts = contacts_fixture(scope)
      assert %Ecto.Changeset{} = Clients.change_contacts(scope, contacts)
    end
  end
end
