defmodule AuraWeb.ContactLiveTest do
  use AuraWeb.ConnCase

  import Phoenix.LiveViewTest
  import Aura.ClientsFixtures

  @create_attrs %{name: "some name", role: "some role", phone: "some phone", email: "some email"}
  @update_attrs %{
    name: "some updated name",
    role: "some updated role",
    phone: "some updated phone",
    email: "some updated email"
  }
  @invalid_attrs %{name: nil, role: nil, phone: nil, email: nil}

  setup :register_and_log_in_user

  defp create_contact(%{scope: scope}) do
    contact = contact_fixture(scope)

    %{contact: contact}
  end

  describe "Index" do
    setup [:create_contact]

    test "lists all contacts", %{conn: conn, contact: contact} do
      {:ok, _index_live, html} = live(conn, ~p"/contacts")

      assert html =~ "Listing Contacts"
      assert html =~ contact.name
    end

    test "saves new contact", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/contacts")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Contact")
               |> render_click()
               |> follow_redirect(conn, ~p"/contacts/new")

      assert render(form_live) =~ "New Contact"

      assert form_live
             |> form("#contact-form", contact: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#contact-form", contact: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/contacts")

      html = render(index_live)
      assert html =~ "Contact created successfully"
      assert html =~ "some name"
    end

    test "updates contact in listing", %{conn: conn, contact: contact} do
      {:ok, index_live, _html} = live(conn, ~p"/contacts")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#contacts-#{contact.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/contacts/#{contact}/edit")

      assert render(form_live) =~ "Edit Contact"

      assert form_live
             |> form("#contact-form", contact: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#contact-form", contact: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/contacts")

      html = render(index_live)
      assert html =~ "Contact updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes contact in listing", %{conn: conn, contact: contact} do
      {:ok, index_live, _html} = live(conn, ~p"/contacts")

      assert index_live |> element("#contacts-#{contact.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#contacts-#{contact.id}")
    end
  end

  describe "Show" do
    setup [:create_contact]

    test "displays contact", %{conn: conn, contact: contact} do
      {:ok, _show_live, html} = live(conn, ~p"/contacts/#{contact}")

      assert html =~ "Show Contact"
      assert html =~ contact.name
    end

    test "updates contact and returns to show", %{conn: conn, contact: contact} do
      {:ok, show_live, _html} = live(conn, ~p"/contacts/#{contact}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/contacts/#{contact}/edit?return_to=show")

      assert render(form_live) =~ "Edit Contact"

      assert form_live
             |> form("#contact-form", contact: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#contact-form", contact: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/contacts/#{contact}")

      html = render(show_live)
      assert html =~ "Contact updated successfully"
      assert html =~ "some updated name"
    end
  end
end
