defmodule HomepagePhoenixWeb.UserSettingsLive do
  use HomepagePhoenixWeb, :live_view

  alias HomepagePhoenix.Accounts
  alias HomepagePhoenix.Accounts.Scope

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>
            Account Settings
            <:subtitle>
              Manage your account username and email address and password ...etc settings
            </:subtitle>
          </.header>
        </div>

        <.form
          for={@username_form}
          id="update_username"
          phx-change="validate_username"
          phx-submit="save_username"
        >
          <.input
            field={@username_form[:username]}
            type="text"
            label="Username"
            autocomplete="username"
            spellcheck="false"
            required
          />
          <.button phx-disable-with="Changing..." class="btn btn-primary w-full">
            Change Username
          </.button>
        </.form>
        <div class="divider" />
        <.form
          for={@email_form}
          id="update_email"
          phx-change="validate_email"
          action={~p"/users/settings"}
        >
          <input type="hidden" name="action" value="update_email" />
          <.input
            field={@email_form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
          />
          <.button phx-disable-with="Changing..." class="btn btn-primary w-full">
            Change Email
          </.button>
        </.form>
        <div class="divider" />
        <.form
          for={@password_form}
          id="update_password"
          phx-change="validate_password"
          action={~p"/users/settings"}
        >
          <input type="hidden" name="action" value="update_password" />
          <.input
            field={@password_form[:password]}
            type="password"
            label="New password"
            autocomplete="new-password"
            spellcheck="false"
            required
          />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
            autocomplete="new-password"
            spellcheck="false"
            required
          />
          <.button phx-disable-with="Changing..." class="btn btn-primary w-full">
            Save Password
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign_username_form(user)
     |> assign_email_forms(user)
     |> assign_password_forms(user)
     |> assign(page_title: "Account Settings")}
  end

  def handle_params(%{"token" => token}, _url, socket) do
    # confirm_email フロー: トークンが URL 経由で渡される
    case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Email changed successfully.")
         |> push_patch(to: ~p"/users/settings")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Email change link is invalid or it has expired.")
         |> push_patch(to: ~p"/users/settings")}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def handle_event("validate_username", %{"user" => user_params}, socket) do
    user = socket.assigns.current_scope.user

    changeset =
      user
      |> Accounts.change_user_username(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, username_form: to_form(changeset, as: :user))}
  end

  def handle_event("save_username", %{"user" => user_params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_user_username(user, user_params) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_scope, Scope.for_user(updated_user))
         |> assign_username_form(updated_user)
         |> put_flash(:info, "Username changed successfully.")
         |> push_patch(to: ~p"/users/settings")}

      {:error, changeset} ->
        {:noreply, assign(socket, username_form: to_form(changeset, as: :user))}
    end
  end

  def handle_event("validate_email", %{"user" => user_params}, socket) do
    user = socket.assigns.current_scope.user

    changeset =
      user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, email_form: to_form(changeset, as: :user))}
  end

  def handle_event("validate_password", %{"user" => user_params}, socket) do
    user = socket.assigns.current_scope.user

    changeset =
      user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, password_form: to_form(changeset, as: :user))}
  end

  defp assign_username_form(socket, user) do
    changeset = Accounts.change_user_username(user)
    assign(socket, username_form: to_form(changeset, as: :user))
  end

  defp assign_email_forms(socket, user) do
    changeset = Accounts.change_user_email(user)
    assign(socket, email_form: to_form(changeset, as: :user))
  end

  defp assign_password_forms(socket, user) do
    changeset = Accounts.change_user_password(user)
    assign(socket, password_form: to_form(changeset, as: :user))
  end
end
