---
description: Recenzja pull requesta jako drugi recenzent
---

PR do recenzji: $ARGUMENTS (numer PR albo bieżący branch).

Najpierw przeczytaj **cały** diff (`gh pr diff` albo `git diff main...HEAD`), dopiero potem
zacznij komentować. Zrecenzuj w trzech przebiegach, w tej kolejności — nie mieszaj ich ze sobą:

**Przebieg 1 — poprawność.** Czy kod robi to, co obiecuje opis PR? Szukaj przypadków
brzegowych, które autor pominął: puste wejście, brak uprawnień, timeout, równoległe wywołania.

**Przebieg 2 — bezpieczeństwo.** Sekrety w kodzie, uprawnienia szersze niż potrzeba,
dane użytkownika w logach, zapytania składane przez konkatenację stringów.

**Przebieg 3 — złożoność i wydajność.** Zapytania w pętli, operacje O(n²) na danych,
które będą rosnąć, funkcje, które robią więcej niż jedną rzecz.

## Checklista dla tego repo

Sprawdź w każdym przebiegu, co dotyczy zmienionych plików:

**Terraform** — ekspozycja sieciowa, szyfrowanie, zakres IAM, tagi i nazewnictwo,
zmiany wymuszające odtworzenie zasobu z danymi.

**Workflow GitHub Actions** — `permissions` na poziomie joba, `timeout-minutes`, akcje przypięte
do wersji, sekrety poza `run:`, brak `pull_request_target` z checkoutem forka.

**Python** — obsługa błędów, zapytania w pętli, dane wrażliwe w logach, brak testu
do nowej ścieżki kodu.

**Reguła zespołu: timeout przy wywołaniach HTTP** — każde wywołanie zewnętrznego serwisu
(`requests`, `httpx`, `urllib`) musi mieć jawny timeout (connect i read). Brak timeoutu zgłaszaj
jako `WAŻNE`; w handlerze FastAPI, na ścieżce obsługującej żądania, jako `BLOKUJĄCE`.
Scenariusz: zależność przestaje odpowiadać, wątki robocze zawisają i `quotes-api` przestaje
odpowiadać na probe'y — Kubernetes restartuje pody.

## Format znaleziska

```
[WAGA] plik:linia
Problem:    jedno zdanie
Scenariusz: kiedy to wybucha
Poprawka:   konkretnie, najlepiej fragment kodu
```

Waga: `BLOKUJĄCE` / `WAŻNE` / `DROBIAZG`.

## Zasada twarda

Nie zgłaszaj znaleziska, do którego nie umiesz napisać scenariusza. Lista trzech realnych
problemów jest warta więcej niż dwadzieścia uwag stylistycznych. Nie poprawiaj plików
w `labs/*/start/` ani `infra/modules/app-storage-bledny` bez polecenia — tylko je recenzuj.

Na końcu: `APROBATA` albo `DO POPRAWY` z listą rzeczy blokujących.
