defmodule AuraWeb.UserLive.Login do
  use AuraWeb, :live_view

  alias Aura.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-md">
        <div class="card bg-base-100 shadow-xl border border-base-300">
          <div class="card-body space-y-6">
            <div class="text-center space-y-2">
              <.header>
                <p class="text-3xl font-bold bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
                  Welcome Back
                </p>
                <:subtitle>
                  <%= if @current_scope do %>
                    You need to reauthenticate to perform sensitive actions on your account.
                  <% else %>
                    Don't have an account? <.link
                      navigate={~p"/users/register"}
                      class="font-semibold text-primary hover:text-primary-focus transition-colors"
                      phx-no-format
                    >Sign up</.link> for an account now.
                  <% end %>
                </:subtitle>
              </.header>
            </div>

            <div :if={local_mail_adapter?()} class="alert alert-info bg-info/10 border-info/20">
              <.icon name="hero-information-circle" class="size-5 shrink-0 text-info" />
              <div class="text-sm">
                <p class="font-medium">Development Mode</p>
                <p>
                  To see sent emails, visit <.link
                    href="/dev/mailbox"
                    class="underline hover:text-info-focus"
                  >the mailbox page</.link>.
                </p>
              </div>
            </div>

            <.form
              :let={f}
              for={@form}
              id="login_form_magic"
              action={~p"/users/log-in"}
              phx-submit="submit_magic"
              class="space-y-4"
            >
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                required
                phx-mounted={JS.focus()}
                class="input input-bordered focus:input-primary"
              />
              <.button class="btn btn-primary w-full btn-lg">
                Log in with email <span aria-hidden="true">→</span>
              </.button>
            </.form>

            <div class="divider text-base-content/40">or</div>

            <.form
              :let={f}
              for={@form}
              id="login_form_password"
              action={~p"/users/log-in"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
              class="space-y-4"
            >
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                required
                class="input input-bordered focus:input-primary"
              />
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                autocomplete="current-password"
                class="input input-bordered focus:input-primary"
              />
              <div class="space-y-3">
                <.button
                  class="btn btn-primary w-full btn-lg"
                  name={@form[:remember_me].name}
                  value="true"
                >
                  Log in and stay logged in <span aria-hidden="true">→</span>
                </.button>
                <.button
                  class="btn btn-outline btn-primary w-full"
                  name={@form[:remember_me].name}
                  value="false"
                >
                  Log in only this time
                </.button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:aura, Aura.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
