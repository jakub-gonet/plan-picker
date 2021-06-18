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

Phoenix jest frameworkiem do budowy aplikacji webowych realizującym model MVC, został stworzony o doświadczenia z frameworkiem Rails.

### Plugs

Fundamentalnym elementem Phoenixa są plugi. Są to moduły lub funkcje, które realizują wspólny interfejs, dzięki czemu są łatwo komponowalne.
Używa się ich głównie w routerze, tworząc pewną analogię do pipe'ów (`|>`). By funkcja działała jako plug, musi jako pierwszy argument przyjmować argument połączenia `conn` oraz opcje.

W pliku `user_auth.ex` znajduje się parę plugów, które zajmują się autoryzacją ról:

```elixir
def require_role(conn, role) do
    if Role.has_role?(current_user(conn), role) do
        conn
    else
        conn
        |> put_flash(:error, "You do not have required permissions to view this page.")
        |> redirect(to: Routes.user_session_path(conn, :new))
        |> halt()
    end
end
```

Sprawdzamy czy aktualny użytkownik ma wymaganą rolę. Jeżeli tak, zwracamy `conn` bez zmian, jeżeli nie to przekierowujemy do strony umożliwiającej zalogowanie i zatrzymujemy cały pipeline. Aktualny użytkownik jest wybierany z `conn.assigns`, pozwalając na dzielonie stanu pomiędzy plugami.

### Router

`router.ex`

Router używa paru podstawowych pipeline'ów składających się z listy plugów:

```elixir
pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :put_root_layout, {PlanPickerWeb.LayoutView, :root}
end

pipeline :require_authenticated_user_having_data do
    plug :require_authenticated_user
    plug :put_roles_if_authenticated
end

pipeline :require_moderator_role do
    plug :require_authenticated_user_having_data
    plug :require_role, :moderator
end

pipeline :require_admin_role do
    plug :require_authenticated_user_having_data
    plug :require_role, :admin
end
```

`browser` zapewnia, że akceptujemy wyłącznie połączenia z nagłówkiem `Accept: text/html` (`plug accepts, ["html"]`), dostajemy dostęp do sesji, dodajemy obsługę liveview czy zabezpieczamy się przed różnymi typami ataków.

`require_moderator_role` i `require_admin_role` sprawdzają czy zalogowany użytkownik posiada odpowiednią rolę, jest to wykorzystywane w routingu.

Niżej znajdują się opisy ścieżek, które mapowane są do kontrolerów i kontrolerów liveView

```elixir
scope "/manage/", PlanPickerWeb do
    pipe_through [:browser, :require_moderator_role]

    get "/enrollments/", EnrollmentManagementController, :index
    get "/enrollments/:id/show", EnrollmentManagementController, :show
    live "/enrollments/:id/edit", EnrollmentManagementLive, :edit
    live "/enrollments/:id/classes", ClassManagementLive, :classes
end
```

`scope` to prefix ścieżki, a nazwa modułu jest prefiksem modułów wymienionych w ścieżkach. np. `get "/enrollments/", EnrollmentManagementController, :index` mapuje się na ścieżkę `/manage/enrollments` udostępnianej pod metodą GET i uruchamia funkcję `index/2` w module `PlanPickerWeb.EnrollmentManagementController`. W ścieżkach widać mapowanie parametrów HTML na argumenty przekazywane do zmapowanej funkcji `get "/enrollments/:id/show"` udostępni id w drugim argumencie jako mapie `%{"id" => numeryczne_id}`.

### MVC

Framework Phoenix realizuje model MVC, często spotykany w rozwiązaniach webowych.

[Modele](#Modele) realizowane są jako struktury w definiowane części biznesowej kodu źródłowego `lib/plan_picker`. Wraz z ich strukturą definiowane są też funkcje pozwalające na przetwarzanie danych związanych z tym modelem.

Przykładem jest plik `subject.ex`, opisujący model przedmiotu.

```elixir
schema "subjects" do
    field :name, :string
    has_many :classes, PlanPicker.Class

    belongs_to :enrollment, PlanPicker.Enrollment

    timestamps()
end
```

Opisana jest w nim struktura danych, ale także funkcje z nią związane:

```elixir
def create_subject!(subject_params, enrollment) do
    %PlanPicker.Subject{}
    |> changeset(subject_params)
    |> put_assoc(:classes, [])
    |> put_assoc(:enrollment, enrollment)
    |> Repo.insert!()
end

def get_subject!(subject_id, opts \\ [preload: [classes: [:teacher, :users, :terms]]]) do
    PlanPicker.Subject
    |> Repo.get!(subject_id)
    |> Repo.preload(opts[:preload])
end
```

Warto zauważyć, że w funkcji `get_subject!` oprócz funkcji `Repo.get!` służącej do pobierania danych z bazy danych, użyta jest też funkcja `Repo.preload`, pobierająca powiązania (w tym przypadku grupy danego przedmiotu, a z każdej grupy nauczyciela, studentów i terminy).

W celu zachowania separacje między warstwami systemu, jedynie funkcje udostępnione przez model są wykorzystywane przez [kontrolery](#Kontroler) do zarządzania danymi, np. w pliku `lib/plan_picker_web/controllers/enrollment_controller.ex`:

```elixir
def show(conn, %{"id" => enrollment_id}) do
    terms =
        enrollment_id
        |> Enrollment.get_enrollment!()
        |> Enrollment.get_terms_for_enrollment()

    render(conn, "show.html", terms: terms)
end
```

Funkcja `show` zdefiniowana w kontrolerze `EnrollmentController` korzysta z funkcji `get_enrollment!` i `get_terms_for_enrollment` w modelu `Enrollment`. Następnie, korzystając z funkcji `render`, przekazując w niej dane z modelu do [widoku](#View-i-template).

### Kontroler

Kontroler w podstawowej aplikacji Phoenixa jest realizowany jako zestaw funkcji przetwarzających dane. W [routerze](#Router) zdefiniowane jest, kiedy dane funkcje kontrolera są wykonywane.

Kontroler jest pośrednikiem pomiędzy modelem logicznym aplikacji a jej widokiem od strony użytkownika. Wszystkie operacje na modelu są wykonywane przed renderowaniem strony HTML (z wyjątkiem mechanizmu [LiveView](#Phoenix-LiveView)) - jest to zasada we frameworku Phoenix - widok jest generowany deterministycznie z danych w modelu.

Kontroler może przetworzone dane przekazać dalej widokowi za pomocą funkcji `render`, tak jak w `enrollment_controller.ex`:

```elixir
def index(conn, _params) do
    enrollments = conn |> UserAuth.current_user() |> Enrollment.get_enrollments_for_user()

    render(conn, "index.html", enrollments: enrollments)
end
```

Jak widać na powyższym przykładzie, zapisy dla użytkownika są pobierane z bazy, a po pobraniu są przypisywane do symbolu `enrollments`. Dzięki temu będą one mogły być użyte przez widok.

Poza renderowaniem widoku, kontroler może manipulować połączeniem w inne sposoby. Jednym z nich jest przekierowanie za pomocą funkcji `redirect`:

```elixir
def delete(conn, %{"id" => enrollment_id}) do
    Enrollment.delete_enrollment!(enrollment_id)

    conn
    |> put_flash(:info, "Enrollment deleted.")
    |> redirect(to: Routes.enrollment_management_path(conn, :index))
end
```

W tym przypadku funkcja `delete` w `enrollment_management_controller.ex` przekieruje użytkownika do ścieżki wywołującej funkcję `index` z tego samego kontrolera.

### View i template

Widoki i szablony są bardzo powiązanymi bytami: każdy szablon jest skompilowany do modułu widoku i jest zwracany jako wartość funkcji `render`, dlatego każdy kontroler musi być skojarzony z widokiem i każdy szablon, który może być renderowany musi być powiązany z widokiem. Tradycyjnie w module widoku definiuje się funkcje pomocnicze przydatne w szablonach: `enrollment_view.ex` ma funkcję `get_width_perc` liczącą procent przydzielonych przez użytkownika punktów w porównaniu do maksymalnej liczby w szablonie `points_assignments.html.leex`:

```elixir
def get_width_perc(0), do: 0
def get_width_perc(points) when points > 0,
    do: trunc(100 * points / PlanPicker.PointAssignmentLive.max_points())
```

Szablony umożliwiają dodawanie wyrażeń Elixira przez specjalny język tagów: `<%= %>` renderuje do HTML wartość zwróconą w środku tagu, `<% %>` tego nie robi. Przykładem jest plik `_terms.html.eex`:

```html
<%= for term <- @terms do %>
  <div class="term-overlay mb-3">
    <%= live_render(@conn, PlanPicker.PointAssignmentLive, session: %{"term_id" => term.id}) %>
    <div class="box content is-size-6">
      <p class="mb-0">
        <strong><%= term.name %></strong> <%= term.type %><%= prefix_if_not_empty(term.group_number, ", ") %><%= term |> display_week_type() |> prefix_if_not_empty(" - ") %>
      </p>
      <p class="mb-0"><%= Timestamp.Range.to_human_readable_iodata(term.interval) %></p>
      <p><%= term.location %></p>
      <span><%= term.teacher.name %> <%= term.teacher.surname %></span>
    </div>
  </div>
<% end %>
```

Jak widać, elementy HTML są zamknięte w wyrażeniu `for`, co sprawia, że są renderowane dla każdego terminu w `@terms`. `@terms` to dane przypisane wcześniej do symbolu `terms` za pomocą funkcji `render`. Znaczniki `<%= %>` są używane do wyświetlania danych dotyczących terminu. Jest też użyta funkcja helper `prefix_if_not_empty` zdefiniowana w pliku widoku `enrollment_view.ex`.

## Phoenix LiveView

Phoenix LiveView jest rozwiązaniem pozwalającym na tworzenie widoków dynamicznych w Phoenix. Jest on rozwiązaniem problemu prezentowanego przez domyślny system kontrolerów i widoków Phoenix, pozwalających jedynie na tworzenie stron statycznych, gdyż (w przeciwieństwie do Phoenix View) LiveView pozwala na dynamicze zmiany stanu.

Zasada deterministycznej generacji HTML nadal jest zachowana - odpowiednie elementy strony są regenerowane przy zmianie danych.

W przeciwieństwie do domyślnego widoku, LiveView jest odpowiedzialny za interakcję z modelem. Aby otrzymać tę funkcjonalność, należy zdefiniować funkcje `mount` oraz `render`. 

### Funkcja `mount`

Funkcja `mount` jest wykonywana przed renderowaniem widoku. LiveView nie ma dostępu do połączenia `conn` - nie pozwala ono na dynamiczną zmianę stanu. Zamiast niego używane jest gniazdo `socket`. Funkcja mount inicjalizuje dane w gnieździe. Musi zwrócić krotkę w postaci `{:ok, socket}`, gdzie `socket` to gotowe gniazdo.

```elixir
  def mount(%{"id" => enrollment_id}, %{"user_token" => token} = _session, socket) do
    enrollment = Enrollment.get_enrollment!(enrollment_id)

    user = Accounts.get_user_by_session_token(token)

    roles = Role.get_roles_for(user)

    socket =
        if user in enrollment.users || :admin in roles do
            subject = get_first_subject(enrollment)

            socket
            |> assign(:enrollment, enrollment)
            |> assign(:selected_subject, subject)
            |> assign(:selected_class, nil)
            |> assign(:selected_users, [])
            |> assign(:points_assignments, %{})
        else
            socket
            |> put_flash(:error, "You do not have required permissions to view this enrollment.")
            |> redirect(to: Routes.enrollment_management_path(socket, :index))
        end

    {:ok, socket}
end
```

W powyższym przykładzie z pliku `class_management_live.ex` funkcja pobiera wartość `enrollment_id` z parametrów ścieżki, oraz token sesji użytkownika `token`. Potem funkcja przypisuje do poszczególnych symboli początkowe wartości z modelu (lub przekierowuje do innej strony, gdy użytkownik nie ma odpowiednich uprawnień).

To zachowanie jest podobne do zachowania kontrolera w klasycznym Phoenixie.

### Funkcja `render`

Funkcja `render` ma taką samą funkcjonalność jak w klasycznym widoku. Różnica polega na tym, że kiedy dane w gnieździe (oznaczone zmienną `assigns`) się zmienią, części szablonu które korzystały z tych danych są ponownie generowane.

```elixir
def render(assigns) do
    render(EnrollmentView, "points_assignments.html", assigns)
end
```

LiveView może także korzystać z już istniejącego widoku, jak w powyższym przykładzie z pliku `ponts_assignments_live.ex`. Widok będzie wtedy dynamicznie regenerowany pod warunkiem, że plik definiujący renderowany szablon (w tym przypadku `points_assignments.html.leex`) ma rozszerzenie `*.html.leex`.

Co ciekawe, funkcja `render` nie musi być implementowana przez programistę - jeżeli w katalogu `lib/plan_picker_web/live` znajduje się plik `*.html.leex` o takiej samej nazwie co moduł LiveView, będzie on renderowany automatycznie. Taka sytuacja zachodzi w plikach `class_management_live.ex` oraz `class_management_live.html.leex`.

### Funkcja `handle_event`

Stan w LiveView może zmieniać się pod wpływem wielu wydarzeń. Najczęściej używaną są wydarzenia generowane przez akcje użytkownika. Aby skorzystać z tego mechanizmu, należy zdefiniować funkcję `handle_event`.

```elixir
def handle_event("toggle_user", %{"id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    selected_users = socket.assigns[:selected_users]

    if user in selected_users do
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
            new_subject = Subject.get_subject!(subject_id)
            {:noreply, assign(socket, :selected_subject, new_subject)}
    end
end

def handle_event("select_class", %{"id" => class_id}, socket) do
    selected_class = socket.assigns[:selected_class]
      # ...
```

W powyższym przykładzie w `class_management_live.ex` w odpowiedzi na zdarzenia, LiveView uaktualnia stan za pomocą funkcji `assign`.

Aby generować wydarzenie, Phoenix LiveView dostarcza specjalne atrybuty do elementów HTML, w szczególności `phx-click` oraz `phx-value-<nazwa_wartości>`:

```html
<li phx-click="select_subject" phx-value-id="<%= subject.id %>">
  <a> <%= subject.name %> </a>
</li>
```

Po kliknięciu w link, wygenerowane będzie zdarzenie "select_subject", a jako wartość zostanie wysłana mapa `%{"id" => <id_przedmiotu>}`. Dane te są wykorzystane w funkcji `handle_event`:

```elixir
def handle_event("select_subject", %{"id" => subject_id}, socket) do
    case socket.assigns[:selected_subject].id do
        ^subject_id ->
            {:noreply, socket}

        _ ->
            new_subject = Subject.get_subject!(subject_id)
            {:noreply, assign(socket, :selected_subject, new_subject)}
    end
end
```

W tym przypadku, jeżeli użytkownik kliknął na przedmiot inny niż ten związany z symbolem `:selected_subject`, zostanie on odpowiednio pobrany z bazy oraz aktualizowany w gnieździe.