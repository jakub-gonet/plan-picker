defmodule PlanPickerWeb.ClassManagementLive do
  use PlanPickerWeb, :live_view
  alias PlanPicker.{Accounts, Class, Enrollment, Role, Subject}

  def selected?(nil, _), do: false

  def selected?(selected, el) when is_list(selected),
    do: Enum.any?(selected, &(el.id == &1.id))

  def selected?(selected, el), do: selected.id == el.id

  def get_points(selected_class, points_assignments, user_id) do
    if selected_class == nil do
      ""
    else
      case Map.get(points_assignments, user_id) do
        nil -> "Assigned 0 points"
        num -> ~E"Assigned <%= num %> points"
      end
    end
  end

  def sort_by_points(users, points_assignments) do
    Enum.sort(users, fn a, b ->
      points_assignments[b.id] == nil || points_assignments[a.id] >= points_assignments[b.id]
    end)
  end

  def mount(%{"id" => enrollment_id}, %{"user_token" => token} = _session, socket) do
    enrollment = Enrollment.get_enrollment!(enrollment_id)

    user = Accounts.get_user_by_session_token(token)

    roles = Role.get_roles_for(user)

    socket =
      if user in enrollment.users || :admin in roles do
        subject = get_first_subject(enrollment)

        socket
        |> assign(:enrollment, enrollment)
        |> assign(:selected_subject, subject)
        |> assign(:selected_class, nil)
        |> assign(:selected_users, [])
        |> assign(:points_assignments, %{})
      else
        socket
        |> put_flash(:error, "You do not have required permissions to view this enrollment.")
        |> redirect(to: Routes.enrollment_management_path(socket, :index))
      end

    {:ok, socket}
  end

  def handle_event("toggle_user", %{"id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    selected_users = socket.assigns[:selected_users]

    if user in selected_users do
      {:noreply, assign(socket, :selected_users, List.delete(selected_users, user))}
    else
      {:noreply, assign(socket, :selected_users, [user | selected_users])}
    end
  end

  def handle_event("select_subject", %{"id" => subject_id}, socket) do
    case socket.assigns[:selected_subject].id do
      ^subject_id ->
        {:noreply, socket}

      _ ->
        new_subject = Subject.get_subject!(subject_id)
        {:noreply, assign(socket, :selected_subject, new_subject)}
    end
  end

  def handle_event("select_class", %{"id" => class_id}, socket) do
    selected_class = socket.assigns[:selected_class]

    if selected_class do
      case socket.assigns[:selected_class].id do
        ^class_id ->
          {:noreply, socket}

        _ ->
          new_class = Class.get_class!(class_id)

          selected_users =
            Enum.filter(socket.assigns[:selected_users], &(&1 not in new_class.users))

          points_assignments =
            socket.assigns[:enrollment].users
            |> Enum.map(fn user -> {user.id, Class.get_points(new_class, user)} end)
            |> Map.new()

          socket =
            socket
            |> assign(:selected_class, new_class)
            |> assign(:selected_users, selected_users)
            |> assign(:points_assignments, points_assignments)

          {:noreply, socket}
      end
    else
      new_class = Class.get_class!(class_id)

      selected_users = Enum.filter(socket.assigns[:selected_users], &(&1 not in new_class.users))

      points_assignments =
        socket.assigns[:enrollment].users
        |> Enum.map(fn user -> {user.id, Class.get_points(new_class, user)} end)
        |> Map.new()

      socket =
        socket
        |> assign(:selected_class, new_class)
        |> assign(:selected_users, selected_users)
        |> assign(:points_assignments, points_assignments)

      {:noreply, socket}
    end
  end

  def handle_event("add_users_to_class", _opts, socket) do
    new_class =
      Class.assign_users_to_class!(
        socket.assigns[:selected_class],
        socket.assigns[:selected_users]
      )

    subject = socket.assigns[:selected_subject]

    socket =
      socket
      |> assign(:selected_class, new_class)
      |> assign(:selected_users, [])
      |> assign(:selected_subject, Subject.get_subject!(subject.id))

    {:noreply, socket}
  end

  def handle_event("remove_user_from_class", %{"id" => user_id}, socket) do
    user = PlanPicker.Accounts.get_user!(user_id)
    new_class = Class.remove_user_from_class!(socket.assigns[:selected_class], user)

    subject = socket.assigns[:selected_subject]

    socket =
      socket
      |> assign(:selected_class, new_class)
      |> assign(:selected_subject, Subject.get_subject!(subject.id))

    {:noreply, socket}
  end

  defp get_first_subject(enrollment) do
    case enrollment.subjects do
      [subject | _] -> Subject.get_subject!(subject.id)
      nil -> nil
    end
  end
end
