defmodule PlanPickerWeb.EnrollmentManagementLive do
  use PlanPickerWeb, :live_view

  def render(assigns) do
    Phoenix.View.render(PlanPickerWeb.EnrollmentManagementView, "edit.html", assigns)
  end

  def mount(%{"id" => enrollment_id}, _opts, socket) do
    enrollment = PlanPicker.Enrollment.get_enrollment!(enrollment_id)
    changeset = Ecto.Changeset.change(enrollment)

    socket =
      socket
      |> assign(:enrollment, enrollment)
      |> assign(:changeset, changeset)
      |> assign(:state_options, PlanPicker.Enrollment.state_options())

    {:ok, socket}
  end

  def handle_event("validate", %{"enrollment" => _enrollment_params}, socket) do
    # TODO: validation
    {:noreply, socket}
  end

  def handle_event("submit", %{"enrollment" => enrollment_params}, socket) do
    new_enrollment =
      PlanPicker.Enrollment.update_enrollment(
        socket.assigns[:enrollment].id,
        enrollment_params
      )

    changeset = Ecto.Changeset.change(new_enrollment)

    socket =
      socket
      |> assign(:enrollment, new_enrollment)
      |> assign(:changeset, changeset)
      |> put_flash(:info, "Enrollment updated.")

    {:noreply, socket}
  end
end
