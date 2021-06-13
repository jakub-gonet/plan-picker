defmodule PlanPickerWeb.PointAssignmentLive do
  use PlanPickerWeb, :live_component
  alias PlanPicker.{Accounts, Class, Term}
  alias PlanPickerWeb.EnrollmentView

  # TODO: move that
  @max_points 20
  @min_points 0

  def max_points, do: @max_points

  def render(assigns) do
    render(EnrollmentView, "points_assignments.html", assigns)
  end

  def mount(_params, %{"term_id" => term_id, "user_token" => token}, socket) do
    term = Term.get_term!(term_id)
    current_user = Accounts.get_user_by_session_token(token)

    socket =
      socket
      |> assign(:user, current_user)
      |> assign(:term_id, term_id)
      |> assign(:assigned_points, Class.get_points(term.class, current_user) || 0)

    {:ok, socket}
  end


end
