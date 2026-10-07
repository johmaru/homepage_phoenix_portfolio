defmodule HomepagePhoenixWeb.UserLoginConfirmationLive do
  use HomepagePhoenixWeb, :live_view

  alias HomepagePhoenix.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header :if={@user}>Welcome {@user.email}</.header>
        </div>

        <.form
          :if={@user && !@user.confirmed_at}
          for={@form}
          id="confirmation_form"
          action={~p"/users/log-in?_action=confirmed"}
          phx-mounted={JS.focus_first()}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <.button
            name={@form[:remember_me].name}
            value="true"
            phx-disable-with="Confirming..."
            class="btn btn-primary w-full"
          >
            Confirm and stay logged in
          </.button>
          <.button phx-disable-with="Confirming..." class="btn btn-primary btn-soft w-full mt-2">
            Confirm and log in only this time
          </.button>
        </.form>

        <.form
          :if={@user && @user.confirmed_at}
          for={@form}
          id="login_form"
          action={~p"/users/log-in"}
          phx-mounted={JS.focus_first()}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <%= if @current_scope do %>
            <.button variant="primary" phx-disable-with="Logging in..." class="btn btn-primary w-full">
              Log in
            </.button>
          <% else %>
            <.button
              name={@form[:remember_me].name}
              value="true"
              phx-disable-with="Logging in..."
              class="btn btn-primary w-full"
            >
              Keep me logged in on this device
            </.button>
            <.button phx-disable-with="Logging in..." class="btn btn-primary btn-soft w-full mt-2">
              Log me in only this time
            </.button>
          <% end %>
        </.form>

        <p :if={@user && !@user.confirmed_at} class="alert alert-outline mt-8">
          Tip: If you prefer passwords, you can enable them in the user settings.
        </p>
      </div>
    </Layouts.app>
    """
  end

  def handle_params(%{"token" => token}, _url, socket) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: :user)

      {:noreply,
       socket
       |> assign(user: user, form: form, page_title: "Confirm account")}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Magic link is invalid or it has expired.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Magic link is invalid or it has expired.")
     |> push_navigate(to: ~p"/users/log-in")}
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, user: nil, form: nil, page_title: "Confirm account")}
  end
end
