defmodule HomepagePhoenixWeb.UserSessionLive do
  use HomepagePhoenixWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            <p>Log in</p>

            <:subtitle>
              <%= if @current_scope do %>
                You need to reauthenticate to perform sensitive actions on your account.
              <% else %>
                Don't have an account?
                <.link
                  navigate={~p"/users/register"}
                  class="font-semibold text-brand hover:underline"
                >
                  Sign up
                </.link>
                for an account now.
              <% end %>
            </:subtitle>
          </.header>
        </div>

        <div :if={@local_mail_adapter?} class="alert alert-info">
          <.icon name="hero-information-circle" class="size-6 shrink-0" />
          <div>
            <p>You are running the local mail adapter.</p>

            <p>
              To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
            </p>
          </div>
        </div>

        <.form for={@form} id="login_form_magic" action={~p"/users/log-in"}>
          <.input
            readonly={!!@current_scope}
            field={@form[:email]}
            id="login_form_magic_email"
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
            phx-mounted={JS.focus()}
          />
          <.button class="btn btn-primary w-full">
            Log in with email <span aria-hidden="true">→</span>
          </.button>
        </.form>

        <div class="divider">or</div>

        <.form for={@form} id="login_form_password" action={~p"/users/log-in"}>
          <.input
            readonly={!!@current_scope}
            field={@form[:email]}
            id="login_form_password_email"
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            autocomplete="current-password"
            spellcheck="false"
          />
          <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
            Log in and stay logged in <span aria-hidden="true">→</span>
          </.button>
          <.button class="btn btn-primary btn-soft w-full mt-2">Log in only this time</.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    email =
      if socket.assigns[:current_scope] && socket.assigns.current_scope.user do
        socket.assigns.current_scope.user.email
      else
        nil
      end

    form =
      %{"email" => email}
      |> to_form(as: :user)

    local_mail_adapter? =
      Application.get_env(:homepage_phoenix, HomepagePhoenix.Mailer)[:adapter] ==
        Swoosh.Adapters.Local

    {:ok,
     socket
     |> assign(form: form, page_title: "Log in", local_mail_adapter?: local_mail_adapter?)}
  end
end
