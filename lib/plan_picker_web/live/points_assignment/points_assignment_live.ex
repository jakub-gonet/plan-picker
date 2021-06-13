defmodule PlanPicker.PointAssignmentLive do
  use PlanPickerWeb, :live_view
  alias PlanPicker.Term
  alias PlanPickerWeb.EnrollmentView

  # TODO: move that
  @max_points 20
  @min_points 0

  def max_points, do: @max_points

  def render(assigns) do
    render(EnrollmentView, "points_assignments.html", assigns)
  end

  def mount(_params, %{"term_id" => term_id}, socket) do
    socket =
      socket
      |> assign(:term_id, term_id)
      |> assign(:assigned_points, 0)

    {:ok, socket}
  end

  def handle_event("add_points", _value, %{assigns: %{assigned_points: points}} = socket) do
    {:noreply, assign(socket, :assigned_points, clamp_assigned_points(points, points + 1))}
  end

  def handle_event("remove_points", _value, %{assigns: %{assigned_points: points}} = socket) do
    {:noreply, assign(socket, :assigned_points, clamp_assigned_points(points, points - 1))}
  end

  defp clamp_assigned_points(_, new_points)
       when @min_points <= new_points and new_points <= @max_points,
       do: new_points

  defp clamp_assigned_points(current_points, _), do: current_points
end
