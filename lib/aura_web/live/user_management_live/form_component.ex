defmodule AuraWeb.UserManagementLive.FormComponent do
  use AuraWeb, :live_component

  alias Aura.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between items-center mb-6">
        <h3 class="text-lg font-bold">{@title}</h3>

        <button
          type="button"
          class="btn btn-sm btn-circle btn-ghost"
          phx-click="close_modal"
          phx-target={@myself}
        >
          <.icon name="hero-x-mark" class="w-5 h-5" />
        </button>
      </div>

      <.form
        for={@form}
        id="user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-4"
      >
        <.input
          field={@form[:email]}
          type="email"
          label="Email"
          placeholder="user@example.com"
          required
        />
        <.input
          field={@form[:password]}
          type="password"
          label="Password"
          placeholder="Enter password"
          required={@action == :new}
        />
        <.input
          field={@form[:password_confirmation]}
          type="password"
          label="Confirm Password"
          placeholder="Confirm password"
          required={@action == :new}
        />
        <div class="flex justify-end gap-3 pt-4">
          <.button
            type="button"
            class="btn btn-ghost"
            phx-click="close_modal"
            phx-target={@myself}
          >
            Cancel
          </.button>
          <.button
            type="submit"
            class="btn btn-primary"
            disabled={!@form.source.valid?}
          >
            {if @action == :new, do: "Create User", else: "Update User"}
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    changeset = Accounts.change_user_registration(user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, user_params)
  end

  def handle_event("close_modal", _params, socket) do
    send(self(), {:close_modal})
    {:noreply, socket}
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        notify_parent({:user_updated, user})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        notify_parent({:user_created, user})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), msg)
end
