defmodule AuraWeb.PageController do
  use AuraWeb, :controller
  alias AuraWeb.UserAuth

  def home(conn, _params) do
    if UserAuth.get_user(conn.assigns) do
      redirect(conn, to: ~p"/dashboard")
    else
      render(conn, :home)
    end
  end
end
