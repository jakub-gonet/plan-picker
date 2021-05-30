defmodule PlanPicker.Term do
  use PlanPicker.Schema
  import Ecto.Changeset

  schema "terms" do
    field :interval, Timestamp.Range
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
      :interval,
    ])
    |> set_interval()
    |> validate_required([:interval, :location, :week_type])
  end

  defp set_interval(changeset) do
    {start: start_t, end: end_t, weekday: weekday} = get_field(changeset, :interval)
    if start_t && end_t && weekday do
      put_change(changeset, :interval, Timestamp.Range.from_time(start_t, end_t, weekday))
    else
      changeset
    end
  end
end
