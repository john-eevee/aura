defmodule Aura.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Aura.Repo

  alias Aura.Accounts.{User, UserToken, UserNotifier, Permission, UserPermission}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email) |> Repo.preload(:permissions)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: Repo.preload(user, :permissions)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id) |> Repo.preload(:permissions)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.email_changeset(attrs)
    |> Repo.insert()
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `Aura.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, Repo.preload(user, :permissions)}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `Aura.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)

    case Repo.one(query) do
      {user, token_inserted_at} -> {Repo.preload(user, :permissions), token_inserted_at}
      nil -> nil
    end
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      Repo.preload(user, :permissions)
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {Repo.preload(user, :permissions), []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Permissions

  @doc """
  Gets a permission by name.

  ## Examples

      iex> get_permission_by_name("create_user")
      %Permission{}

      iex> get_permission_by_name("unknown")
      nil
  """
  def get_permission_by_name(name) when is_binary(name) do
    Repo.get_by(Permission, name: name)
  end

  @doc """
  Gets a single permission.

  Raises `Ecto.NoResultsError` if the Permission does not exist.

  ## Examples

      iex> get_permission!("123")
      %Permission{}

      iex> get_permission!("456")
      ** (Ecto.NoResultsError)
  """
  def get_permission!(id), do: Repo.get!(Permission, id)

  @doc """
  Lists all permissions.

  ## Examples

      iex> list_permissions()
      [%Permission{}, ...]
  """
  def list_permissions do
    Repo.all(Permission)
  end

  @doc """
  Creates a permission.

  ## Examples

      iex> create_permission(%{name: "create_user", description: "Can create users"})
      {:ok, %Permission{}}

      iex> create_permission(%{name: ""})
      {:error, %Ecto.Changeset{}}
  """
  def create_permission(attrs \\ %{}) do
    %Permission{}
    |> Permission.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a permission.

  ## Examples

      iex> update_permission(permission, %{description: "New description"})
      {:ok, %Permission{}}

      iex> update_permission(permission, %{name: ""})
      {:error, %Ecto.Changeset{}}
  """
  def update_permission(%Permission{} = permission, attrs) do
    permission
    |> Permission.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a permission.

  ## Examples

      iex> delete_permission(permission)
      {:ok, %Permission{}}

      iex> delete_permission(permission)
      {:error, %Ecto.Changeset{}}
  """
  def delete_permission(%Permission{} = permission) do
    Repo.delete(permission)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking permission changes.

  ## Examples

      iex> change_permission(permission)
      %Ecto.Changeset{data: %Permission{}}
  """
  def change_permission(%Permission{} = permission, attrs \\ %{}) do
    Permission.changeset(permission, attrs)
  end

  @doc """
  Assigns a permission to a user.

  ## Examples

      iex> assign_permission_to_user(user, permission)
      {:ok, %UserPermission{}}

      iex> assign_permission_to_user(user, permission)
      {:error, %Ecto.Changeset{}} # already assigned
  """
  def assign_permission_to_user(%User{} = user, %Permission{} = permission) do
    %UserPermission{}
    |> UserPermission.changeset(%{user_id: user.id, permission_id: permission.id})
    |> Repo.insert()
  end

  @doc """
  Removes a permission from a user.

  ## Examples

      iex> remove_permission_from_user(user, permission)
      {:ok, %UserPermission{}}

      iex> remove_permission_from_user(user, permission)
      {:error, %Ecto.NoResultsError{}} # not assigned
  """
  def remove_permission_from_user(%User{} = user, %Permission{} = permission) do
    case Repo.get_by(UserPermission, user_id: user.id, permission_id: permission.id) do
      nil -> {:error, :not_found}
      user_permission -> Repo.delete(user_permission)
    end
  end

  @doc """
  Lists all permissions for a user.

  ## Examples

      iex> list_user_permissions(user)
      [%Permission{}, ...]
  """
  def list_user_permissions(%User{} = user) do
    user
    |> Repo.preload(:permissions)
    |> Map.get(:permissions)
  end

  @doc """
  Checks if a user has a specific permission.

  ## Examples

      iex> user_has_permission?(user, "create_user")
      true

      iex> user_has_permission?(user, "delete_user")
      false
  """
  def user_has_permission?(%User{} = user, permission_name) when is_binary(permission_name) do
    user
    |> Repo.preload(:permissions)
    |> Map.get(:permissions)
    |> Enum.any?(&(&1.name == permission_name))
  end

  @doc """
  Checks if a user has any of the given permissions.

  ## Examples

      iex> user_has_any_permission?(user, ["create_user", "update_user"])
      true

      iex> user_has_any_permission?(user, ["delete_user", "admin_user"])
      false
  """
  def user_has_any_permission?(%User{} = user, permission_names) when is_list(permission_names) do
    user_permissions = list_user_permissions(user)
    permission_names_set = MapSet.new(permission_names)
    user_permission_names = MapSet.new(Enum.map(user_permissions, & &1.name))

    MapSet.intersection(permission_names_set, user_permission_names)
    |> MapSet.size() > 0
  end

  @doc """
  Gets a user with preloaded permissions.

  ## Examples

      iex> get_user_with_permissions("123")
      %User{permissions: [%Permission{}, ...]}

      iex> get_user_with_permissions("456")
      nil
  """
  def get_user_with_permissions(id) do
    Repo.get(User, id) |> Repo.preload(:permissions)
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {Repo.preload(user, :permissions), tokens_to_expire}}
      end
    end)
  end
end
