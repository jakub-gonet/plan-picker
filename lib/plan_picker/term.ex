defmodule PlanPicker.Term do
  use PlanPicker.Schema
  import Ecto.Changeset
  alias PlanPicker.Repo

  schema "terms" do
    field :interval, Timestamp.Range
    field :interval_time_start, :time, virtual: true
    field :interval_time_end, :time, virtual: true
    field :interval_weekday, Ecto.Enum, virtual: true, values: Timestamp.Day.allowed_days()

    field :location, :string
    field :week_type, :string
    belongs_to :class, PlanPicker.Class

    timestamps()
  end

  def create_term!(term_attrs, class) do
    %PlanPicker.Term{}
    |> changeset(term_attrs)
    |> put_assoc(:class, class)
    |> Repo.insert!()
  end

  @doc false
  def changeset(term, attrs) do
    term
    |> cast(attrs, [
      :location,
      :week_type,
      :interval_time_start,
      :interval_time_end,
      :interval_weekday
    ])
    |> set_interval()
    |> validate_required([:interval, :location, :week_type])
  end

  defp set_interval(changeset) do
    from = get_field(changeset, :interval_time_start)
    to = get_field(changeset, :interval_time_end)
    weekday = get_field(changeset, :interval_weekday)

    if from && to && weekday do
      put_change(changeset, :interval, Timestamp.Range.from_time(from, to, weekday))
    else
      changeset
    end
  end
end
