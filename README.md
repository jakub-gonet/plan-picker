# Projekt z baz danych 2 – Karol Wilk, Jakub Gonet

# Instalacja

## Docker

```bash
docker-compose up
```

## Lokalna instalacja

```bash
mix deps.get
mix ecto.setup
cd assets && npm install && cd ..

# Włączenie serwera
mix phx.server
```

Serwer działa pod adresem [http://localhost:4000/](http://localhost:4000/).

# Opis

Projekt zakłada stworzenie systemu do rejestracji na zajęcia na uczelni.
Studenci zostają przypisani do odpowiedniej grupy rocznikowej oraz są w stanie przydzielić punkty na poszczególne terminy zajęć.

Po zamknięciu zapisów moderatorzy roku przypisują studentów do grup uwzględniając ich preferencje. Po zakończeniu przydziału do grup studenci mogą zobaczyć wybrany plan.

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
