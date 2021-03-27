# Projekt z baz danych 2 – Karol Wilk, Jakub Gonet

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


# Typy encji

## Student

Reprezentuje aktora Student.
- Imię
- Nazwisko
- E-mail
- Numer indeksu

## Moderator

Podklasa typu encji _Student_

Reprezentuje aktora Moderator.

## Administrator

Podklasa typu encji _Moderator_

Reprezentuje aktora Administrator.

## Rocznik

Reprezentuje grupę użytkowników na tym samym roczniku i kierunku.

- Rok rozpoczęcia nauki
- Nazwa kierunku

## Zapis

Reprezentuje zapis, w ramach którego studenci będą przypisywani do grup.

- Nazwa zapisu
- Stan zapisu (otwarty, oczekiwanie na wyniki itp.)
- Minimalna liczba punktów na przedmiot
- Maksymalna liczba punktów na przedmiot
- Maksymalna liczba punktów na grupę

## Przedmiot

Reprezentuje przedmiot, z którego organizowane są zajęcia.

- Nazwa przedmiotu
- Rodzaj zajęć (wykład, laboratoria itp.)
- Sposób prowadzenia zajęć (zdalne, stacjonarne itp.)

## Grupa

Reprezentuje grupę zajęciową.

- Prowadzący

## Termin

Reprezentuje blok zajęciowy odbywający się w danym terminie.

- Dzień wykonywania
- Godzina rozpoczęcia
- Godzina zakończenia
- Ograniczenia czasowe (tydzień A/B itp.)

## Preferencja

Reprezentuje nadane przez studenta punkty priorytetu.

- Liczba punktów

# Schemat bazy
