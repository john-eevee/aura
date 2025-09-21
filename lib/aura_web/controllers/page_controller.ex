defmodule AuraWeb.PageController do
  use AuraWeb, :controller
  alias AuraWeb.UserAuth

  def home(conn, _params) do
    if UserAuth.fetch_current_scope_for_user(conn, []) do
      redirect(conn, to: ~p"/dashboard")
    else
      render(conn, :home)
    end
  end
end
