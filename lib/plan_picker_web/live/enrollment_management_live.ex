defmodule PlanPickerWeb.EnrollmentManagementLive do
  use PlanPickerWeb, :live_view
  import Ecto.Changeset, only: [change: 1]
  alias PlanPicker.{Accounts, Enrollment, Role}

  def render(assigns) do
    Phoenix.View.render(PlanPickerWeb.EnrollmentManagementView, "edit.html", assigns)
  end

  def mount(%{"id" => enrollment_id}, %{"user_token" => token} = _session, socket) do
    enrollment = Enrollment.get_enrollment!(enrollment_id)

    user = Accounts.get_user_by_session_token(token)

    roles = Role.get_roles_for(user)

    if Enum.member?(enrollment.users, user) || Enum.member?(roles, :admin) do
      changeset = change(enrollment)

      socket =
        socket
        |> assign(:enrollment, enrollment)
        |> assign(:changeset, changeset)
        |> assign(:state_options, PlanPicker.Enrollment.state_options())
        |> assign(:selected_users, [])
        |> assign(
          :available_users,
          Enum.filter(PlanPicker.Accounts.get_all_users(), &(!Enum.member?(enrollment.users, &1)))
        )

      {:ok, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You do not have the required permissions to edit this enrollment.")
        |> redirect(to: Routes.enrollment_management_path(socket, :index))

      {:ok, socket}
    end
  end

  def handle_event("validate", %{"enrollment" => _enrollment_params}, socket) do
    # TODO: validation
    {:noreply, socket}
  end

  def handle_event("submit", %{"enrollment" => enrollment_params}, socket) do
    new_enrollment =
      Enrollment.update_enrollment(
        socket.assigns[:enrollment].id,
        enrollment_params
      )

    changeset = change(new_enrollment)

    socket =
      socket
      |> assign(:enrollment, new_enrollment)
      |> assign(:changeset, changeset)
      |> put_flash(:info, "Enrollment updated.")

    {:noreply, socket}
  end

  def handle_event("toggle_user", %{"id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    selected_users = socket.assigns[:selected_users]

    if Enum.member?(selected_users, user) do
      {:noreply, assign(socket, :selected_users, List.delete(selected_users, user))}
    else
      {:noreply, assign(socket, :selected_users, [user | selected_users])}
    end
  end

  def handle_event("assign_users", _opts, socket) do
    new_enrollment =
      Enrollment.assign_users_to_enrollment!(
        socket.assigns[:enrollment],
        socket.assigns[:selected_users]
      )

    socket =
      socket
      |> assign(:enrollment, new_enrollment)
      |> assign(:changeset, change(new_enrollment))
      |> assign(:selected_users, [])
      |> assign(
        :available_users,
        Enum.filter(
          Accounts.get_all_users(),
          &(!Enum.member?(new_enrollment.users, &1))
        )
      )

    {:noreply, socket}
  end

  def handle_event("unassign_users", _opts, socket) do
    new_enrollment =
      Enrollment.unassign_users_from_enrollment!(
        socket.assigns[:enrollment],
        socket.assigns[:selected_users]
      )

    socket =
      socket
      |> assign(:enrollment, new_enrollment)
      |> assign(:changeset, change(new_enrollment))
      |> assign(:selected_users, [])
      |> assign(
        :available_users,
        Enum.filter(
          Accounts.get_all_users(),
          &(!Enum.member?(new_enrollment.users, &1))
        )
      )

    {:noreply, socket}
  end
end
