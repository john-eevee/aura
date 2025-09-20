defmodule AuraWeb.ContactsLiveTest do
  use AuraWeb.ConnCase

  import Phoenix.LiveViewTest
  import Aura.ClientsFixtures

  @create_attrs %{name: "some name", role: "some role", phone: "some phone", email: "some email"}
  @update_attrs %{name: "some updated name", role: "some updated role", phone: "some updated phone", email: "some updated email"}
  @invalid_attrs %{name: nil, role: nil, phone: nil, email: nil}

  setup :register_and_log_in_user

  defp create_contacts(%{scope: scope}) do
    contacts = contacts_fixture(scope)

    %{contacts: contacts}
  end

  describe "Index" do
    setup [:create_contacts]

    test "lists all contacts", %{conn: conn, contacts: contacts} do
      {:ok, _index_live, html} = live(conn, ~p"/contacts")

      assert html =~ "Listing Contacts"
      assert html =~ contacts.name
    end

    test "saves new contacts", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/contacts")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Contacts")
               |> render_click()
               |> follow_redirect(conn, ~p"/contacts/new")

      assert render(form_live) =~ "New Contacts"

      assert form_live
             |> form("#contacts-form", contacts: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#contacts-form", contacts: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/contacts")

      html = render(index_live)
      assert html =~ "Contacts created successfully"
      assert html =~ "some name"
    end

    test "updates contacts in listing", %{conn: conn, contacts: contacts} do
      {:ok, index_live, _html} = live(conn, ~p"/contacts")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#contacts-#{contacts.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/contacts/#{contacts}/edit")

      assert render(form_live) =~ "Edit Contacts"

      assert form_live
             |> form("#contacts-form", contacts: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#contacts-form", contacts: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/contacts")

      html = render(index_live)
      assert html =~ "Contacts updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes contacts in listing", %{conn: conn, contacts: contacts} do
      {:ok, index_live, _html} = live(conn, ~p"/contacts")

      assert index_live |> element("#contacts-#{contacts.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#contacts-#{contacts.id}")
    end
  end

  describe "Show" do
    setup [:create_contacts]

    test "displays contacts", %{conn: conn, contacts: contacts} do
      {:ok, _show_live, html} = live(conn, ~p"/contacts/#{contacts}")

      assert html =~ "Show Contacts"
      assert html =~ contacts.name
    end

    test "updates contacts and returns to show", %{conn: conn, contacts: contacts} do
      {:ok, show_live, _html} = live(conn, ~p"/contacts/#{contacts}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/contacts/#{contacts}/edit?return_to=show")

      assert render(form_live) =~ "Edit Contacts"

      assert form_live
             |> form("#contacts-form", contacts: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#contacts-form", contacts: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/contacts/#{contacts}")

      html = render(show_live)
      assert html =~ "Contacts updated successfully"
      assert html =~ "some updated name"
    end
  end
end
