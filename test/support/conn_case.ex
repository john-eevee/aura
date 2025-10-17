defmodule AuraWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use AuraWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint AuraWeb.Endpoint

      use AuraWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import AuraWeb.ConnCase
    end
  end

  setup tags do
    Aura.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn} = context) do
    # Ensure permissions exist for tests that check authorization
    Aura.AccountsFixtures.ensure_permissions_exist()

    user = Aura.AccountsFixtures.user_fixture()
    scope = Aura.Accounts.Scope.for_user(user)

    opts =
      context
      |> Map.take([:token_authenticated_at])
      |> Enum.into([])

    %{conn: log_in_user(conn, user, opts), user: user, scope: scope}
  end

  @doc """
  Setup helper that registers and logs in users with client permissions.

      setup context do
        permissions = ["list_clients", "create_client", "update_client", "delete_client"]
        register_and_log_in_user_with_permissions(context, permissions)
      end

  It stores an updated connection and a registered user with client permissions in the
  test context.
  """
  def register_and_log_in_user_with_permissions(%{conn: conn}, permissions) do
    user = Aura.AccountsFixtures.user_fixture()
    # Ensure permissions exist and assign them to the user
    loaded_permissions =
      permissions
      |> Enum.map(&Aura.Accounts.get_permission_by_name/1)
      |> Enum.reject(&is_nil/1)

    loaded_permissions =
      if loaded_permissions == [] do
        # Create permissions if they don't exist
        permission_names = permissions

        Enum.each(permission_names, fn name ->
          case Aura.Accounts.get_permission_by_name(name) do
            nil ->
              {:ok, _} =
                Aura.Accounts.create_permission(%{name: name, description: "Test permission"})

            _ ->
              :ok
          end
        end)

        # Re-fetch permissions after creation
        Enum.map(permission_names, &Aura.Accounts.get_permission_by_name/1)
      else
        loaded_permissions
      end

    Enum.each(loaded_permissions, fn permission ->
      Aura.Accounts.assign_permission_to_user(user, permission)
    end)

    scope = Aura.Accounts.Scope.for_user(user)

    %{conn: log_in_user(conn, user), user: user, scope: scope}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user, opts \\ []) do
    token = Aura.Accounts.generate_user_session_token(user)

    maybe_set_token_authenticated_at(token, opts[:token_authenticated_at])

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  defp maybe_set_token_authenticated_at(_token, nil), do: nil

  defp maybe_set_token_authenticated_at(token, authenticated_at) do
    Aura.AccountsFixtures.override_token_authenticated_at(token, authenticated_at)
  end
end
