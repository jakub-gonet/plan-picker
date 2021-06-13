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
