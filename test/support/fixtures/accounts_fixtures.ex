defmodule Aura.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Aura.Accounts` context.
  """

  import Ecto.Query

  alias Aura.Accounts
  alias Aura.Accounts.Scope

  def unique_user_email(allowed \\ true) do
    if (allowed) do
      ensure_allowlist_entries()
    end
     "admin#{System.unique_integer([:positive])}@example.com"
  end
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email()
    })
  end

  defp ensure_allowlist_entries do
    # Create allowlist entries if they don't exist
    allowlist_entries = [
      %{type: "domain", value: "example.com", description: "Test domain", enabled: true},
      %{type: "email", value: "admin@example.com", description: "Admin user", enabled: true}
    ]

    Enum.each(allowlist_entries, fn entry_attrs ->
      case Accounts.get_allowlist_entry_by_value_and_type(entry_attrs.value, entry_attrs.type) do
        nil ->
          {:ok, _} = Accounts.create_allowlist_entry(entry_attrs)
        _ ->
          :ok
      end
    end)
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    # Ensure allowlist entries exist for testing
    ensure_allowlist_entries()

    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)

    token =
      extract_user_token(fn url ->
        Accounts.deliver_login_instructions(user, url)
      end)

    {:ok, {user, _expired_tokens}} =
      Accounts.login_user_by_magic_link(token)

    user
  end

  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    Aura.Repo.update_all(
      from(t in Accounts.UserToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Accounts.UserToken.build_email_token(user, "login")
    Aura.Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    Aura.Repo.update_all(
      from(ut in Accounts.UserToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end

  def unique_permission_name do
    letters = Enum.take_random(?a..?z, 5) |> List.to_string()
    "test_#{letters}"
  end

  def valid_permission_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_permission_name(),
      description: "Test permission description"
    })
  end

  def permission_fixture(attrs \\ %{}) do
    {:ok, permission} =
      attrs
      |> valid_permission_attributes()
      |> Accounts.create_permission()

    permission
  end

  def user_with_permissions_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)

    permissions = [
      permission_fixture(%{name: "create_user", description: "Can create users"}),
      permission_fixture(%{name: "view_user", description: "Can view users"})
    ]

    Enum.each(permissions, fn permission ->
      Accounts.assign_permission_to_user(user, permission)
    end)

    Accounts.get_user_with_permissions(user.id)
  end
end
