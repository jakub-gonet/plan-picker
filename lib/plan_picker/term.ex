defmodule PlanPicker.Term do
  use PlanPicker.Schema
  import Ecto.Changeset

  schema "terms" do
    field :interval, Timestamp.Range
    field :interval_time_start, :time, virtual: true
    field :interval_time_end, :time, virtual: true
    field :interval_day_offset, :integer, virtual: true

    field :location, :string
    field :week_type, :string
    belongs_to :class, PlanPicker.Class

    timestamps()
  end

  def add_term(term_attrs, class) do
    %PlanPicker.Term{}
    |> changeset(term_attrs)
    |> Ecto.Changeset.put_assoc(:class, class)
    |> PlanPicker.Repo.insert!()
  end

  @doc false
  def changeset(term, attrs) do
    term
    |> cast(attrs, [
      :location,
      :week_type,
      :interval_time_start,
      :interval_time_end,
      :interval_day_offset
    ])
    |> set_interval()
    |> validate_required([:interval, :location, :week_type])
  end

  defp set_interval(changeset) do
    from = get_field(changeset, :interval_time_start)
    to = get_field(changeset, :interval_time_end)
    offset = get_field(changeset, :interval_day_offset)

    if from && to && offset do
      interval_start =
        DateTime.new!(
          Date.new!(1996, 1, 1 + offset),
          from
        )

      interval_end =
        DateTime.new!(
          Date.new!(1996, 1, 1 + offset),
          to
        )

      put_change(changeset, :interval, Timestamp.Range.new(interval_start, interval_end))
    else
      changeset
    end
  end
end
