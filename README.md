# Projekt z baz danych 2 – Karol Wilk, Jakub Gonet

# Opis

Projekt zakłada stworzenie systemu do rejestracji na zajęcia na uczelni.
Studenci zostają przypisani do odpowiedniej grupy rocznikowej oraz są w stanie przydzielić punkty na poszczególne terminy zajęć z przedmiotów.

Po zamknięciu zapisów moderatorzy roku przypisują studentów do grup uwzględniając ich preferencje.
Po zakończeniu przydziału do grup studenci mogą zobaczyć wybrany plan.

# Technologie

Do stworzenia aplikacji wykorzystano język [Elixir](http://elixir-lang.org/) i framework [Phoenix](https://phoenixframework.org/).
Silnikiem bazodanowym jest [PostgreSQL](https://www.postgresql.org/), używamy biblioteki [Ecto](https://hexdocs.pm/ecto/Ecto.html) ułatwiającej operacje na bazie danych.

# Instalacja

## Docker

```bash
docker-compose up
```

## Lokalna instalacja

```bash
mix deps.get
mix ecto.setup
(cd assets && npm install)

# Włączenie serwera
mix phx.server
```

Serwer działa pod adresem [http://localhost:4000/](http://localhost:4000/).

# Struktura projektu

Phoenix generuje parę folderów przy tworzeniu nowego projektu.

```
tree -d -L 3 -I 'node_modules|deps' .

.
├── assets               # zasoby potrzebne do zbudowania strony - js, css, obrazki i fonty
│   ├── css
│   ├── js
│   └── static
|       ├── fonts
│       └── images
├── config               # konfiguracja bibliotek - serwera http, drivera bazy danych, etc
├── lib                  # kod aplikacji
│   ├── plan_picker      # kod biznesowy, zawiera modele
│   │   ├── accounts
│   │   └── timestamp
│   └── plan_picker_web  # część webowa, oparta o MVC
│       ├── channels
│       ├── controllers
│       ├── templates    # w Phoenixie katalog views/ to głównie helpery, w templates znajduje się renderowany html
│       └── views
├── priv                 # zasoby, które nie są kodem źródłowym - migracje baz danych, translacje, pliki statyczne (kopiowane automatycznie z assets/)
│   ├── gettext
│   │   └── en
│   ├── repo
│   │   └── migrations   # migracje, które definiują schemat bazy przy uruchomieniu mix ecto.setup
│   └── static
│       ├── css
│       ├── fonts
│       ├── images
│       └── js
└── test                 # testy
    ├── plan_picker
    ├── plan_picker_web
    │   ├── controllers
    │   └── views
    └── support
        └── fixtures
```

Więcej o budowie projektu pod [tym linkiem](https://hexdocs.pm/phoenix/directory_structure.html).

Ważniejsze pliki:

- `priv/repo/migrations/20210417133131_add_initial_schema.exs` - schemat bazy danych opisany przy pomocy DSL podbiblioteki Ecto służącej do migracji
- `priv/repo/seeds.exs` - początkowe dane wczytane przy mix ecto.setup
- `lib/plan_picker_web/router.ex` - definicje ścieżek dostępnych z przeglądarki
- `lib/plan_picker_web/controllers/<nazwa>_controller` - kontroler modelu o nazwie `<nazwa>`
- `config/config.exs` - konfiguracja bibliotek, w plikach `dev.exs` i `prod.exs` znajdują się nadpisania dla środowiska deweloperskiego i produkcyjnego

# Aktorzy

## Student

- Ma dostęp do swoich danych (dane; rocznik; zapisy, do których jest dodany)
- Może wybrać przedmioty w ramach zapisów
- Może przydzielić ograniczoną liczbę punktów w ramach zapisu na dany termin
- Może zobaczyć przydzielony termin
- Może zobaczyć skład grup zajęciowych, których jest częścią

## Moderator

- Te same uprawnienia co [Student](#Student)
- Może tworzyć, edytować i usuwać zapisy w obrębie swojego rocznika
- Może przenosić studentów pomiędzy grupami, gdy zapisy są zamknięte
- Może wyświetlać skład wszystkich grup zajęciowych w ramach zapisu

## Administrator

- Te same uprawnienia co [Moderator](#Moderator)
- Ma dostęp do wszystkich zapisów
- Może przydzielać role
- Może dodawać, usuwać i edytować konta studentów

# Schemat bazy

![](plan_picker_schema.png)

## Znaczenie poszczególnych tabel

- `users`, `teachers` - studenci i nauczyciele
- `roles` - role użytkowników ze szczególnymi uprawnieniami
- `users_tokens` - tokeny sesji użytkowników
- `enrollments` - zapisy, na które studenci mogą się rejestrować
- `subjects` - przedmioty w ramach zapisu
- `classes` - grupy dziekańskie w ramach przedmiotu
- `terms` - posczególne terminy (jedna grupa może mieć czasami zajęcia w wielu terminach)
- `enrollments_users` - w zapisie brać udział mogą tylko studenci do niego przypisani, jeden student może przypisany do wielu zapisów
- `classes_users` - do grupy dziekańskiej przypisywani są studenci, jeden student może przypisany do wielu grup dziekańskich
- `points_assignments` - studenci mogą przyznawać grupom dziekańskim punkty priorytetu

# Opis poszczególnych części projektu

## Elixir

Elixir jest językiem funkcyjnym, stworzonym na podstawie języka Erlang oraz inspirowany syntaxem Rubiego.
Przyświeca mu idea "let it crash" - w przypadku nieprawidłowych danych proces obsługujący dane żądanie powinien zakończyć swoje działanie. W Erlangu zazwyczaj zapytania obsługuje wiele procesów (procesy w VM erlanga są bardzo lekkie i nie są procesami systemowymi), dlatego obsługa w ramach jednego procesu skutecznie izoluje je od siebie - crash jednego procesu nie ma wpływu na inne procesy.

### Typy danych

Głównymi typami wartości są stringi (przechowywane binarnie w UTF-8) `" ą alamakota"`, liczby i atomy `:nazwa`. Atomy służą jako unikalne symbole (jest górna liczba liczby symboli dostępnych w VM erlanga), często w kluczach map i struktur, ale też w opcjach przesyłanych do funkcji. Elixir nie ma typu boolean, realizują go atomy `:true` i `:false`.
Głównymi typami kolekcji w Elixirze są listy `[1,2,3]`, krotki `{1,2,3}`, mapy `%{}` i struktury `%NazwaStruktury{}`.

### Pattern matching

Przypisanie wartość do zmiennej to strukturalne związanie wartości z nazwą. Nie widać tego przy zwykłych przypisaniach:

```elixir
x = 5
```

ale widać, gdy przypisujemy liczbę czy krotkę:

```elixir
{x, y} = {1, 2}
# x == 1
# y == 2
%{a: 1, b: {t, s}} = %{a: 1, b: { [1,3],  5}}
# t == [1,3]
# s == 5
```

W drugim przykładzie próbujemy związać mapę, która w Elixirze ma syntax `%{klucz: wartość}`.
Najpierw upewniamy się, że klucz `:a` ma wartość 1, potem destrukturyzujemy klucz `:b`, z którego wyciągamy krotkę dwóch zmiennych.

#### Przykład z kodu

```elixir
  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end
```

Funkcja `create/2` w `user_session_controller.ex` drugi argument dopasowuje do mapy z kluczem "user", a następnie dopasowaną wartość dopasowuje do mapy z emailem i hasłem. Warto zauważyć, że kluczami są tutaj stringi, ponieważ argument jest kontrolowany przez klientów. Użycie atomu byłoby błędem, ponieważ klient mógłby generować argumenty, które tworzyłyby nowe atomy i w którymś momencie przekroczylibyśmy maksymalną liczbę atomów oraz scrashowalibyśmy VM erlanga.

```elixir
  defp parse_weekday_lower("pn"), do: :monday
  defp parse_weekday_lower("wt"), do: :tuesday
  defp parse_weekday_lower("sr"), do: :wednesday
  defp parse_weekday_lower("cz"), do: :thursday
  defp parse_weekday_lower("pt"), do: :friday
```

Funkcja `parse_weekday_lower/1` w pliku `csv.ex` mapuje stringi, reprezentujące dni tygodnia na atomy. Pattern matching w funkcjach działa z góry do dołu, więc bardzo często się korzysta z tego mechanizmu do zastępowania ifów:

```elixir
  defp parse_group("", :lecture), do: nil
  defp parse_group(group, _) when group != "", do: String.to_integer(group)
```

`parse_group/2` najpierw próbuje dopasować wzorzec do pustego stringa i atomu reprezentującego wykład, jezeli mu to się uda to zwraca specjalny atom `nil`, jeżeli nie, to próbuje dopasować każdy niepusty string i sparsować numer grupy. Wysokopoziomowo ta funkcja mapuje grupy wykładowe (które nie mają numeru) na nil, a w reszcie zamienia numer grupy ze stringu na liczbę. Warto zauważyć, że jeśli podalibyśmy jako argument np. `parse_group("", :laboratory)` to żadna z klauzul funkcji nie jest w stanie się dopasować i dostaniemy błąd dopasowania.

### Pipe operator

Kolejnym ważnym elementem Elixira jest operator `|>`. Pozwala na przekazanie wartości jako pierwszego argumentu funkcji, więc zapis `f(g(x))` zamienia się na `x |> g() |> f()`.

#### Przykład z kodu

```elixir
  def show(conn, %{"id" => enrollment_id}) do
    terms =
      enrollment_id
      |> Enrollment.get_enrollment!()
      |> Enrollment.get_terms_for_enrollment()

    render(conn, "show.html", terms: terms)
  end
```

Funkcja `show/2` z `enrollment_controller.ex` po wyciągnięciu `enrollment_id` przekazuje ją do funkcji `get_enrollment/1` z modułu `Enrollment`, który robi zapytanie do bazy danych, a następnie drugi wywołuje funkcję `get_terms_for_enrollment/1`, która robi zapytanie o terminy związane z zapisem i strukturyzuje dane w listę terminów z dodatkowymi informacjami nt nauczycieli czy grup.

## Ecto

Ecto jest biblioteką dostępu i generowania zapytań do danych. Nie jest ORMem - jest całkowicie agnostyczna co do tego gdzie przechowujemy dane czy w jaki sposób do nich się odwołujemy (oraz nie jest obiektowa :>).

Bardzo często korzysta się z podbibliotek Ecto, które stanowią pomost pomiędzy DBMS, a Ecto (np Postgrex).

Ecto w naszej aplikacji składa się z dwóch elementów:

- modelowania fizycznej struktury bazy danych
- dostępu do danych i zaprojektowania modelu logicznego

### Struktura bazy danych i migracje

Wszystkie migracje znajdują się w folderze `priv/repo/migrations`, szczególnie istotne są dwie pierwsze: `setup_db_extensions` oraz `add_initial_schema`. W pierwszym inicjalizujemy wtyczki do postgresa, citext oraz btree_gist, odpowiednio do typu `citext`, który dostarcza funkcjonalności varcharów, ale bez uwzględniania wielkości liter (używane do przechowywania maili) i do stworzenia indeksów na przedziały czasowe.

`add_initial_schema` z kolei tworzy podstawową strukturę danych. Skupmy się na jednej migracji:

```elixir
defp add_terms do
    create_query = "CREATE TYPE week_type AS ENUM ('A', 'B')"
    drop_query = "DROP TYPE week_type"
    execute(create_query, drop_query)

    create table(:terms) do
        add :interval, :tstzrange, null: false
        add :location, :string
        add :week_type, :week_type
        add :class_id, references(:classes, on_delete: :delete_all)

        timestamps()
    end

    create constraint("terms", :in_two_week_range,
                check: "interval <@ '[1996-01-01 00:00, 1996-01-14 00:00]'"
            )

    create constraint("terms", :no_overlap_in_group,
                exclude: "gist (class_id WITH =, interval WITH &&)"
            )

    create index(:terms, [:class_id])
end
```

Po kolei:

1. Dodanie enuma `week_type`

   Definiujemy dwie komendy z PG, które tworzą i niszczą typ użytkownika, który jest zdefiniowany jako enum. W ten sposób ograniczamy wartość pola week_type do `"A", "B", null` co przekłada się na rodzaj tygodnia bądź oba tygodnie (null).

   Potrzebujemy zdefinować tworzenie i niszczenie, by móc używać komendy `mix ecto.rollback`, która nie jest obowiązkowa, ale pozwala na cofanie się z aplikacją migracji.

   ```elixir
   create_query = "CREATE TYPE week_type AS ENUM ('A', 'B')"
   drop_query = "DROP TYPE week_type"
   execute(create_query, drop_query)
   ```

2. Stworzenie tabeli o nazwie `"terms"`, atom mapowany jest na string

   ```elixir
   create table(:terms) do
   ```

3. Dodanie interwału, który jest [typem interwałowym ze strefą czasową.](https://www.postgresql.org/docs/current/rangetypes.html).

   W ten sposób modelujemy przedziały godzin, które są dokładniej opisane w kolejnej sekcji.

   ```elixir
   add :interval, :tstzrange, null: false
   ```

4. Dodanie asocjacji przez klucz obcy z klasą i użycie typu kaskady `DELETE ALL`

   ```elixir
   add :class_id, references(:classes, on_delete: :delete_all)
   ```

5. Dodanie pól `created_at`, `updated_at` przez makro `timestamps()`

   Przydatne w sortowaniu po dacie stworzenia i podobnych zapytaniach.

   ```elixir
   timestamps()
   ```

6. Ograniczenia na interwały

   Musimy zamodelować terminy, które zamykają się w dwóch tygodniach, dlatego użycie dat nie jest optymalnym rozwiązaniem. Interwały z PG pozwalają na zamknięcie dat w określonym przedziale (tutaj przyjęliśmy początek jako 1996-01-01, a koniec 1996-01-14 - pierwszy stycznia 1996 to był poniedziałek, więc łatwo mapuje się na dni tygodni) oraz na zabronienie przecinania się z innym przedziałem w obrębie tej samej grupy. **Jest to dość istotne ograniczenie, ponieważ zapobiega sytuacji, w której jedna grupa ma zajęcia jednocześnie albo się pokrywają, co jest niemożliwe do zrealizowania w rzeczywistości.** Tutaj używamy indeksu drzewiastego gist, który był omówiony wcześniej.

   ```elixir
   create constraint("terms", :in_two_week_range,
               check: "interval <@ '[1996-01-01 00:00, 1996-01-14 00:00]'"
           )

   create constraint("terms", :no_overlap_in_group,
               exclude: "gist (class_id WITH =, interval WITH &&)"
           )
   ```

   Domyślnie każda tabela ma klucz `id`, który ma typ int. My zmieniliśmy to ustawienie używając UUID, ponieważ jest nieco bezpieczniejsze, zapobiegając atakom enumeracyjnym (iteracja po endpoincie REST: `/user/1`, `/user/2`, `/user/n`) oraz umożliwia używanie shardingu, dzieląc bazę na niezależne podczęści (UUID jest globalnie unikalnie, więc nie musimy synchronizować sekwencji).

### Model logiczny

Ecto składa się z trzech głównych części:

- repozytorium
- modeli
- changesetów i dostępu do danych

#### Repozytorium

Repozytorium jest miejscem, które definiujemy jako źródło danych. U nas jest to Postgres, definicja znajduje się w pliku `repo.ex`

#### Modele

Modele reprezentują struktury, jakich używamy w aplikacji. Przykładowo w pliku `term.ex` widzimy taką definicję:

```elixir
schema "terms" do
    field :raw_interval, :map, virtual: true
    field :interval, Timestamp.Range
    field :location, :string
    field :week_type, :string
    belongs_to :class, Class

    timestamps()
end
```

Widać wymienione wyżej pola, asocjację z klasą oraz dodatkowo pole wirtualne `:raw_interval`. Jest ono wykorzystywane do stworzenia pola interval i jest mapą `%{start: start_t, end: end_t, weekday: weekday}` reprezentującą czas rozpoczęcia i skończenia terminu oraz dzień tygodnia, w którym dany termin się odbywa. Plik `range.ex` zajmuje się mapowaniem tych informacji na typ w bazie danych w funkcji `from_time`, która wykorzystuje `new` i `dump` do serializacji i deserializacji interwałów.

#### Changesety

Changesety to struktury przechowujące zmiany, które chcemy zaaplikować na danym wierszu. Przykładowo w `term.ex` widzimy funkcję `changeset`:

```elixir
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
```

Funkcja ta najpierw używa funkcji `cast` do odfiltrowania interesujących nas pól - do `changeset` przekazujemy dowolną mapę, więc chcemy uniemożliwić przypadkową zmianę pola, którego nie chcemy zmienić w danym changesecie.
Następnie używamy metody `set_interval`, która próbuje stworzyć nową strukturę `interval`. To, że udało się jej ją stworzyć sprawdzane jest w kolejnym kroku `validate_required`. Jeżeli changeset jest prawidłowy to ma pole `valid?` ustawione na `true`, jeżeli nie jest to ma `valid? == false` oraz listę błędów w `errors`.

W pliku `user.ex` można zauważyć podział odpowiedzialności changesetów, istnieje tam `password_changeset`, `email_changeset` czy `registration_changeset`.

#### Dostęp do danych

Przykładem dostępu do danych i używania repozytorium jest plik `role.ex`.

```elixir
def has_role?(user, role_name) do
    query =
        from u in Accounts.User,
        join: r in assoc(u, :role),
        where: r.name == ^role_name and u.id == ^user.id

    Repo.exists?(query)
end
```

W `has_role?` definiujemy funkcję sprawdzającą czy dana struktura reprezentująca usera ma daną rolę.
Najpierw tworzymy zapytanie w DSL Ecto, które wygląda bardzo analogicznie do zapytań SQL, a następnie używamy funkcji `Repo.exists?`, która zwraca prawdę jeżeli z wygenerowanego zapytania zostanie zwrócony co najmniej jeden wiersz.

Jednym z elementów zapytania jest znak `^`: w zwykłym Elixirze gdy chcemy sprawdzić strukturalnie wartość zmiennej używamy go do zapobiegnięcia dowiązania zmiennej do nazwy:

```elixir
x = 5
# 5
x = 4 # zmienna x jest dopasowana do 4 przez zmianę dowiązania
# 4

^x = 3 # zmienna nie może się dopasować, ponieważ zabroniliśmy jej zmienić dowiązanie
# ** (MatchError) no match of right hand side value: 3
```

W Ecto znak jest przeładowany i służy do poprawnego escape'owania wartości w zapytaniu by uniknąć ataków SQL injection. Brak użycia `^` kończy się błędem.

Drugi przykład:

```elixir
def assign_role(user, role_name) do
    if not has_role?(user, role_name) do
        %Role{name: role_name}
        |> Repo.preload(:user)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Repo.insert!()
    end
end
```

`assign_role` przypisuje daną rolę do użytkownika.
Najpierw sprawdzamy czy użytkownik nie posiada już danej roli, jeżeli nie, to tworzymy strukturę, która ją reprezentuje, tworzymy z niej changeset, tworzymy asocjację z podanym userem i próbujemy ją dodać do bazy.

Elixir ma konwencję, w której funkcje zakończone wykrzyknikiem rzucają wyjątek przy niepoprawnym użyciu (tutaj gdy INSERT sie nie powiedzie), a funkcje bez wykrzyknika zwracają krotkę `{:ok, value}` bądź `{:error, reason}` pozwalając użyć dopasowania wzorca i wykonania innych funkcji. Widać to w `verify_change_email_token_query` w pliku `user_token.ex`

## Phoenix

## Phoenix Liveview
