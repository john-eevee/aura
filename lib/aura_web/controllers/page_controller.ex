defmodule AuraWeb.PageController do
  use AuraWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
