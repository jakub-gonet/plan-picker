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

## Phoenix
