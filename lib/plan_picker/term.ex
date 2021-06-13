defmodule PlanPicker.Term do
  use PlanPicker.Schema
  import Ecto.Changeset
  alias PlanPicker.{Class, Repo, Term}

  schema "terms" do
    field :raw_interval, :map, virtual: true
    field :interval, Timestamp.Range
    field :location, :string
    field :week_type, :string
    belongs_to :class, Class

    timestamps()
  end

  def create_term!(term_attrs, class) do
    %Term{}
    |> changeset(term_attrs)
    |> put_assoc(:class, class)
    |> Repo.insert!()
  end

  def get_term!(term_id, opts \\ [preload: [class: [:points_assignments]]]) do
    Term
    |> Repo.get!(term_id)
    |> Repo.preload(opts[:preload])
  end

  @doc false
  def changeset(term, attrs) do
    term
    |> cast(attrs, [
      :location,
      :week_type,
      :raw_interval
    ])
    |> set_interval()
    |> validate_required([:interval, :location])
  end

  defp set_interval(changeset) do
    %{start: start_t, end: end_t, weekday: weekday} = get_field(changeset, :raw_interval)

    if start_t && end_t && weekday do
      put_change(changeset, :interval, Timestamp.Range.from_time(start_t, end_t, weekday))
    else
      changeset
    end
  end
end
