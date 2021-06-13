defmodule PlanPickerWeb.ClassManagementLive do
  use PlanPickerWeb, :live_view
  alias PlanPicker.{Accounts, Class, Enrollment, Subject}

  def selected?(selected, el) when is_list(selected) do
    Enum.member?(selected, el)
  end

  def selected?(nil, _) do
    false
  end

  def selected?(selected, el) do
    selected == el
  end

  def mount(%{"id" => enrollment_id}, _session, socket) do
    enrollment = Enrollment.get_enrollment!(enrollment_id)
    subject = get_first_subject(enrollment)

    socket =
      socket
      |> assign(:enrollment, enrollment)
      |> assign(:selected_subject, subject)
      |> assign(:selected_class, nil)
      |> assign(:selected_users, [])

    {:ok, socket}
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
            Enum.filter(socket.assigns[:selected_users], &(!Enum.member?(new_class.users, &1)))

          socket =
            socket
            |> assign(:selected_class, new_class)
            |> assign(:selected_users, selected_users)

          {:noreply, socket}
      end
    else
      new_class = Class.get_class!(class_id)

      selected_users =
        Enum.filter(socket.assigns[:selected_users], &(!Enum.member?(new_class.users, &1)))

      socket =
        socket
        |> assign(:selected_class, new_class)
        |> assign(:selected_users, selected_users)

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
