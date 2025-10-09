defmodule Aura.Clients do
  @moduledoc """
  The Clients context.
  """

  import Ecto.Query, warn: false
  alias Aura.Repo

  alias Aura.Clients.Client
  alias Aura.Clients.Contact
  alias Aura.Accounts.Scope

  @doc """
  Returns the PubSub topic for client changes for the given scope.

  ## Examples

      iex> clients_topic(scope)
      "user:123e4567-e89b-12d3-a456-426614174000:clients"

  """
  def clients_topic(%Scope{} = scope) do
    "user:#{scope.user.id}:clients"
  end

  @doc """
  Subscribes to scoped notifications about any client changes.

  The broadcasted messages match the pattern:

    * {:created, %Client{}}
    * {:updated, %Client{}}
    * {:deleted, %Client{}}

  """
  def subscribe_clients(%Scope{} = scope) do
    Phoenix.PubSub.subscribe(Aura.PubSub, clients_topic(scope))
  end

  defp broadcast_client(%Scope{} = scope, message) do
    Phoenix.PubSub.broadcast(Aura.PubSub, clients_topic(scope), message)
  end

  @doc """
  Returns the list of clients.

  ## Examples

      iex> list_clients(scope)
      [%Client{}, ...]

  """
  def list_clients(%Scope{} = scope) do
    with :ok <- Aura.Accounts.authorize(scope, "list_clients") do
      Repo.all_by(Client, user_id: scope.user.id)
    end
  end

  @doc """
  Gets a single client.

  ## Examples

      iex> get_client(scope, 123)
      {:ok, %Client{}}

      iex> get_client(scope, 456)
      {:error, :not_found}

  """
  def get_client(%Scope{} = scope, id) do
    with :ok <- Aura.Accounts.authorize(scope, "list_clients") do
      case Repo.get_by(Client, id: id, user_id: scope.user.id) do
        nil -> {:error, :not_found}
        client -> {:ok, client}
      end
    end
  end

  @doc """
  Creates a client.

  ## Examples

      iex> create_client(scope, %{field: value})
      {:ok, %Client{}}

      iex> create_client(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_client(%Scope{} = scope, attrs) do
    with :ok <- Aura.Accounts.authorize(scope, "create_client"),
         {:ok, client = %Client{}} <-
           %Client{}
           |> Client.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_client(scope, {:created, client})
      {:ok, client}
    end
  end

  @doc """
  Updates a client.

  ## Examples

      iex> update_client(scope, client, %{field: new_value})
      {:ok, %Client{}}

      iex> update_client(scope, client, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_client(%Scope{} = scope, %Client{} = client, attrs) do
    true = client.user_id == scope.user.id

    with :ok <- Aura.Accounts.authorize(scope, "update_client"),
         {:ok, client = %Client{}} <-
           client
           |> Client.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_client(scope, {:updated, client})
      {:ok, client}
    end
  end

  @doc """
  Deletes a client.

  ## Examples

      iex> delete_client(scope, client)
      {:ok, %Client{}}

      iex> delete_client(scope, client)
      {:error, %Ecto.Changeset{}}

  """
  def delete_client(%Scope{} = scope, %Client{} = client) do
    true = client.user_id == scope.user.id

    with :ok <- Aura.Accounts.authorize(scope, "delete_client"),
         {:ok, client = %Client{}} <-
           Repo.delete(client) do
      broadcast_client(scope, {:deleted, client})
      {:ok, client}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking client changes.

  ## Examples

      iex> change_client(scope, client)
      %Ecto.Changeset{data: %Client{}}

  """
  def change_client(%Scope{} = scope, %Client{} = client, attrs \\ %{}) do
    true = client.user_id == scope.user.id

    Client.changeset(client, attrs, scope)
  end

  @doc """
  Returns the PubSub topic for contact changes for the given scope.

  ## Examples

      iex> contacts_topic(scope)
      "user:123e4567-e89b-12d3-a456-426614174000:contacts"

  """
  def contacts_topic(%Scope{} = scope) do
    "user:#{scope.user.id}:contacts"
  end

  @doc """
  Subscribes to scoped notifications about any contact changes.

  The broadcasted messages match the pattern:

    * {:created, %Contact{}}
    * {:updated, %Contact{}}
    * {:deleted, %Contact{}}

  """
  def subscribe_contacts(%Scope{} = scope) do
    Phoenix.PubSub.subscribe(Aura.PubSub, contacts_topic(scope))
  end

  defp broadcast_contact(%Scope{} = scope, message) do
    Phoenix.PubSub.broadcast(Aura.PubSub, contacts_topic(scope), message)
  end

  @doc """
  Returns the list of contacts.

  ## Examples

      iex> list_contacts(scope)
      [%Contact{}, ...]

  """
  def list_contacts(%Scope{} = scope) do
    Repo.all_by(Contact, user_id: scope.user.id)
  end

  @doc """
  Gets a single contact.

  Raises `Ecto.NoResultsError` if the Contact does not exist.

  ## Examples

      iex> get_contact!(scope, 123)
      %Contact{}

      iex> get_contact!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_contact!(%Scope{} = scope, id) do
    Repo.get_by!(Contact, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a contact.

  ## Examples

      iex> create_contact(scope, %{field: value})
      {:ok, %Contact{}}

      iex> create_contact(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_contact(%Scope{} = scope, attrs) do
    with {:ok, contact = %Contact{}} <-
           %Contact{}
           |> Contact.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_contact(scope, {:created, contact})
      {:ok, contact}
    end
  end

  @doc """
  Updates a contact.

  ## Examples

      iex> update_contact(scope, contact, %{field: new_value})
      {:ok, %Contact{}}

      iex> update_contact(scope, contact, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_contact(%Scope{} = scope, %Contact{} = contact, attrs) do
    true = contact.user_id == scope.user.id

    with {:ok, contact = %Contact{}} <-
           contact
           |> Contact.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_contact(scope, {:updated, contact})
      {:ok, contact}
    end
  end

  @doc """
  Deletes a contact.

  ## Examples

      iex> delete_contact(scope, contact)
      {:ok, %Contact{}}

      iex> delete_contact(scope, contact)
      {:error, %Ecto.Changeset{}}

  """
  def delete_contact(%Scope{} = scope, %Contact{} = contact) do
    true = contact.user_id == scope.user.id

    with {:ok, contact = %Contact{}} <-
           Repo.delete(contact) do
      broadcast_contact(scope, {:deleted, contact})
      {:ok, contact}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking contact changes.

  ## Examples

      iex> change_contact(scope, contact)
      %Ecto.Changeset{data: %Contact{}}

  """
  def change_contact(%Scope{} = scope, %Contact{} = contact, attrs \\ %{}) do
    true = contact.user_id == scope.user.id

    Contact.changeset(contact, attrs, scope)
  end

  @doc """
  Returns the count of clients for the given scope.

  ## Examples

      iex> count_clients(scope)
      5

  """
  def count_clients(%Scope{} = scope) do
    Client
    |> where([c], c.user_id == ^scope.user.id)
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns the count of contacts for the given scope.

  ## Examples

      iex> count_contacts(scope)
      12

  """
  def count_contacts(%Scope{} = scope) do
    Contact
    |> where([c], c.user_id == ^scope.user.id)
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns a list of recent clients for the given scope.

  ## Examples

      iex> list_recent_clients(scope, limit: 5)
      [%Client{}, ...]

  """
  def list_recent_clients(%Scope{} = scope, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    Client
    |> where([c], c.user_id == ^scope.user.id)
    |> order_by([c], desc: c.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end
end
