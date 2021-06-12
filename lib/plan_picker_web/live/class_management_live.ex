defmodule PlanPickerWeb.ClassManagementLive do
  use PlanPickerWeb, :live_view

  def mount(%{"id" => enrollment_id}, _session, socket) do
    enrollment = PlanPicker.Enrollment.get_enrollment!(enrollment_id)
    subject = get_subject(enrollment)

    socket =
      socket
      |> assign(:enrollment, enrollment)
      |> assign(:selected_subject, subject)
      |> assign(:selected_class, nil)
      |> assign(:selected_users, [])

    {:ok, socket}
  end

  def handle_event("toggle_user", %{"id" => user_id}, socket) do
    user = PlanPicker.Accounts.get_user!(user_id)

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
        new_subject = PlanPicker.Subject.get_subject!(subject_id)
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
          new_class = PlanPicker.Class.get_class!(class_id)
          {:noreply, assign(socket, :selected_class, new_class)}
      end
    else
      new_class = PlanPicker.Class.get_class!(class_id)
      {:noreply, assign(socket, :selected_class, new_class)}
    end
  end

  defp get_subject(enrollment) do
    case enrollment.subjects do
      [subject | _] -> PlanPicker.Subject.get_subject!(subject.id)
      nil -> nil
    end
  end
end
