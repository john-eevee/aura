defmodule Aura.ClientsTest do
  use Aura.DataCase

  alias Aura.Clients

  describe "clients" do
    alias Aura.Clients.Client

    import Aura.AccountsFixtures, only: [user_scope_fixture: 0]
    import Aura.ClientsFixtures

    @invalid_attrs %{name: nil, status: nil, since: nil, industry_type: nil}

    test "clients_topic/1 returns the correct PubSub topic" do
      scope = user_scope_fixture()
      topic = Clients.clients_topic(scope)
      assert topic =~ ~r/^user:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:clients$/
      assert topic == "user:#{scope.user.id}:clients"
    end

    test "subscribe_clients/1 subscribes to the correct topic" do
      scope = user_scope_fixture()
      Clients.subscribe_clients(scope)
      # Verify subscription by broadcasting and receiving
      Phoenix.PubSub.broadcast(Aura.PubSub, Clients.clients_topic(scope), {:test, :message})
      assert_receive {:test, :message}
    end

    test "list_clients/1 returns all scoped clients" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      client = client_fixture(scope)
      other_client = client_fixture(other_scope)
      assert Clients.list_clients(scope) == [client]
      assert Clients.list_clients(other_scope) == [other_client]
    end

    test "get_client/2 returns the client with given id" do
      scope = user_scope_fixture()
      client = client_fixture(scope)
      other_scope = user_scope_fixture()
      assert Clients.get_client(scope, client.id) == {:ok, client}
      assert Clients.get_client(other_scope, client.id) == {:error, :not_found}
    end

    test "create_client/2 with valid data creates a client" do
      valid_attrs = %{
        name: "some name",
        status: :active,
        since: ~D[2025-09-19],
        industry_type: "some industry_type"
      }

      scope = user_scope_fixture()

      assert {:ok, %Client{} = client} = Clients.create_client(scope, valid_attrs)
      assert client.name == "Some name"
      assert client.status == :active
      assert client.since == ~D[2025-09-19]
      assert client.industry_type == "Some Industry_type"
      assert client.user_id == scope.user.id
    end

    test "create_client/2 broadcasts created message" do
      scope = user_scope_fixture()
      Clients.subscribe_clients(scope)

      valid_attrs = %{
        name: "test client",
        status: :active,
        since: ~D[2025-09-19],
        industry_type: "tech"
      }

      assert {:ok, %Client{} = client} = Clients.create_client(scope, valid_attrs)
      assert_receive {:created, ^client}
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
        since: ~D[2025-09-20],
        industry_type: "some updated industry_type"
      }

      assert {:ok, %Client{} = client} = Clients.update_client(scope, client, update_attrs)
      assert client.name == "Some updated name"
      assert client.status == :inactive
      assert client.since == ~D[2025-09-20]
      assert client.industry_type == "Some Updated Industry_type"
    end

    test "update_client/3 broadcasts updated message" do
      scope = user_scope_fixture()
      client = client_fixture(scope)
      Clients.subscribe_clients(scope)

      update_attrs = %{name: "updated name"}

      assert {:ok, %Client{} = updated_client} = Clients.update_client(scope, client, update_attrs)
      assert_receive {:updated, ^updated_client}
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
      assert {:ok, ^client} = Clients.get_client(scope, client.id)
    end

    test "delete_client/2 deletes the client" do
      scope = user_scope_fixture()
      client = client_fixture(scope)
      assert {:ok, %Client{}} = Clients.delete_client(scope, client)
      assert Clients.get_client(scope, client.id) == {:error, :not_found}
    end

    test "delete_client/2 broadcasts deleted message" do
      scope = user_scope_fixture()
      client = client_fixture(scope)
      Clients.subscribe_clients(scope)

      assert {:ok, %Client{} = deleted_client} = Clients.delete_client(scope, client)
      assert_receive {:deleted, ^deleted_client}
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

    test "contacts_topic/1 returns the correct PubSub topic" do
      scope = user_scope_fixture()
      topic = Clients.contacts_topic(scope)
      assert topic =~ ~r/^user:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:contacts$/
      assert topic == "user:#{scope.user.id}:contacts"
    end

    test "subscribe_contacts/1 subscribes to the correct topic" do
      scope = user_scope_fixture()
      Clients.subscribe_contacts(scope)
      # Verify subscription by broadcasting and receiving
      Phoenix.PubSub.broadcast(Aura.PubSub, Clients.contacts_topic(scope), {:test, :message})
      assert_receive {:test, :message}
    end

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

    test "create_contact/2 broadcasts created message" do
      scope = user_scope_fixture()
      Clients.subscribe_contacts(scope)

      valid_attrs = %{
        name: "test contact",
        role: "tester",
        phone: "123-456",
        email: "test@example.com"
      }

      assert {:ok, %Contact{} = contact} = Clients.create_contact(scope, valid_attrs)
      assert_receive {:created, ^contact}
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

    test "update_contact/3 broadcasts updated message" do
      scope = user_scope_fixture()
      contact = contact_fixture(scope)
      Clients.subscribe_contacts(scope)

      update_attrs = %{name: "updated name"}

      assert {:ok, %Contact{} = updated_contact} = Clients.update_contact(scope, contact, update_attrs)
      assert_receive {:updated, ^updated_contact}
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

    test "delete_contact/2 broadcasts deleted message" do
      scope = user_scope_fixture()
      contact = contact_fixture(scope)
      Clients.subscribe_contacts(scope)

      assert {:ok, %Contact{} = deleted_contact} = Clients.delete_contact(scope, contact)
      assert_receive {:deleted, ^deleted_contact}
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
