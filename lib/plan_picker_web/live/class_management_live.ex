defmodule PlanPickerWeb.ClassManagementLive do
  use PlanPickerWeb, :live_view

  def mount(%{"id" => enrollment_id}, _session, socket) do
    {:ok, assign(socket, :enrollment_id, enrollment_id)}
  end
end
