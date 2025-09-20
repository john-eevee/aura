defmodule Aura.Clients do
  @moduledoc """
  The Clients context.
  """

  import Ecto.Query, warn: false
  alias Aura.Repo

  alias Aura.Clients.Client
  alias Aura.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any client changes.

  The broadcasted messages match the pattern:

    * {:created, %Client{}}
    * {:updated, %Client{}}
    * {:deleted, %Client{}}

  """
  def subscribe_clients(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Aura.PubSub, "user:#{key}:clients")
  end

  defp broadcast_client(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Aura.PubSub, "user:#{key}:clients", message)
  end

  @doc """
  Returns the list of clients.

  ## Examples

      iex> list_clients(scope)
      [%Client{}, ...]

  """
  def list_clients(%Scope{} = scope) do
    Repo.all_by(Client, user_id: scope.user.id)
  end

  @doc """
  Gets a single client.

  Raises `Ecto.NoResultsError` if the Client does not exist.

  ## Examples

      iex> get_client!(scope, 123)
      %Client{}

      iex> get_client!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_client!(%Scope{} = scope, id) do
    Repo.get_by!(Client, id: id, user_id: scope.user.id)
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
    with {:ok, client = %Client{}} <-
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

    with {:ok, client = %Client{}} <-
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

    with {:ok, client = %Client{}} <-
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

  alias Aura.Clients.Contacts
  alias Aura.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any contacts changes.

  The broadcasted messages match the pattern:

    * {:created, %Contacts{}}
    * {:updated, %Contacts{}}
    * {:deleted, %Contacts{}}

  """
  def subscribe_contacts(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Aura.PubSub, "user:#{key}:contacts")
  end

  defp broadcast_contacts(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Aura.PubSub, "user:#{key}:contacts", message)
  end

  @doc """
  Returns the list of contacts.

  ## Examples

      iex> list_contacts(scope)
      [%Contacts{}, ...]

  """
  def list_contacts(%Scope{} = scope) do
    Repo.all_by(Contacts, user_id: scope.user.id)
  end

  @doc """
  Gets a single contacts.

  Raises `Ecto.NoResultsError` if the Contacts does not exist.

  ## Examples

      iex> get_contacts!(scope, 123)
      %Contacts{}

      iex> get_contacts!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_contacts!(%Scope{} = scope, id) do
    Repo.get_by!(Contacts, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a contacts.

  ## Examples

      iex> create_contacts(scope, %{field: value})
      {:ok, %Contacts{}}

      iex> create_contacts(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_contacts(%Scope{} = scope, attrs) do
    with {:ok, contacts = %Contacts{}} <-
           %Contacts{}
           |> Contacts.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_contacts(scope, {:created, contacts})
      {:ok, contacts}
    end
  end

  @doc """
  Updates a contacts.

  ## Examples

      iex> update_contacts(scope, contacts, %{field: new_value})
      {:ok, %Contacts{}}

      iex> update_contacts(scope, contacts, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_contacts(%Scope{} = scope, %Contacts{} = contacts, attrs) do
    true = contacts.user_id == scope.user.id

    with {:ok, contacts = %Contacts{}} <-
           contacts
           |> Contacts.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_contacts(scope, {:updated, contacts})
      {:ok, contacts}
    end
  end

  @doc """
  Deletes a contacts.

  ## Examples

      iex> delete_contacts(scope, contacts)
      {:ok, %Contacts{}}

      iex> delete_contacts(scope, contacts)
      {:error, %Ecto.Changeset{}}

  """
  def delete_contacts(%Scope{} = scope, %Contacts{} = contacts) do
    true = contacts.user_id == scope.user.id

    with {:ok, contacts = %Contacts{}} <-
           Repo.delete(contacts) do
      broadcast_contacts(scope, {:deleted, contacts})
      {:ok, contacts}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking contacts changes.

  ## Examples

      iex> change_contacts(scope, contacts)
      %Ecto.Changeset{data: %Contacts{}}

  """
  def change_contacts(%Scope{} = scope, %Contacts{} = contacts, attrs \\ %{}) do
    true = contacts.user_id == scope.user.id

    Contacts.changeset(contacts, attrs, scope)
  end
end
