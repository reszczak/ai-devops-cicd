# Recenzja PR #47: ranking najpopularniejszych cytatów

**Werdykt: Request changes.** Jest jeden bloker bezpieczeństwa. Dwie kolejne uwagi (wydajność, styl) też trzeba poprawić przed merge'em.

## Blokujące

### 1. IAM: aplikacja dostaje odczyt danych z całego konta (`iam-ranking.tf:20-29`)
Drugi `Statement` daje `dynamodb:Scan` z `Resource = "*"`. Aplikacja do wyświetlania cytatów mogłaby wtedy skanować każdą tabelę DynamoDB na koncie, a nie tylko `quotes-stats`.

- `Scan` to odczyt danych, a nie metadanych. Nazwa bloku `OpisTabel` maskuje ten problem.
- `Resource = "*"` jest uzasadnione tylko dla `ListTables`, bo ta akcja działa na poziomie konta.
- Kod aplikacji nie używa żadnej z trzech akcji z tego bloku. `ranking.py` woła tylko `get_item` i `update_item`.

**Poprawka:** usuń cały drugi `Statement`. Jeśli `DescribeTable` jest potrzebne, dodaj je do pierwszego bloku z `Resource = aws_dynamodb_table.stats.arn`.

W pierwszym bloku `dynamodb:Query` też nie jest używane. Jeśli nie planujesz go użyć, usuń je, żeby zachować least privilege. Jeśli przejdziesz na `BatchGetItem` (pkt 2), dodaj `dynamodb:BatchGetItem`.

## Do poprawy

### 2. Wydajność: N+1 zapytań i nowy obiekt `Table` przy każdym wywołaniu (`ranking.py:19-40`)
- `zbuduj_ranking` woła `pobierz_licznik` w pętli, a ta robi jedno `get_item` na cytat. Przy 4 cytatach to 4 sekwencyjne round-tripy, a przy 1000 cytatów będzie ich 1000 na każde żądanie `/top`. Opóźnienie rośnie liniowo, a koszt RCU razem z nim.
- `dynamo.Table(TABELA)` tworzy się w każdym wywołaniu. Wystarczy jeden obiekt na poziomie modułu.
- `datetime.now()` jest liczone osobno dla każdego cytatu. Wartości różnią się o mikrosekundy, a `datetime.now()` bez strefy czasowej jest niejednoznaczne. Lepiej policzyć raz przed pętlą i użyć `datetime.now(timezone.utc)`.

**Poprawka:** jedno `batch_get_item` (limit 100 kluczy na żądanie, więc porcjuj i obsłuż `UnprocessedKeys`). Alternatywnie dodaj krótki cache wyniku rankingu, bo dla licznika wyświetleń kilkusekundowa nieświeżość jest akceptowalna.

### 3. Styl: `zwieksz_licznik(quoteId)` odstaje od reszty modułu (`ranking.py:43`)
- Parametr jest w camelCase, a reszta kodu (`quote_id`, `pobierz_licznik`) używa snake_case zgodnie z PEP 8. `ruff` ze zwykłym zestawem reguł (`N`) to zgłosi.
- Funkcja nie ma docstringa ani adnotacji zwracanego typu, a pozostałe funkcje je mają.

## Mniejsze uwagi

- **Niezgodność nazw tabeli.** Terraform tworzy `${local.prefix}-quotes-stats`, a kod domyślnie szuka `quotes-stats`. Opis PR też mówi `quotes-stats`. Działa tylko wtedy, gdy `STATS_TABLE` jest ustawione. W tym PR nie widać, gdzie to się dzieje (Deployment/Rollout, `main.py`). Lokalne `curl` z opisu zadziała tylko wtedy, gdy ktoś stworzył tabelę o nazwie domyślnej.
- **Testy.** Opis mówi „testy przechodzą", ale PR nie dodaje żadnego testu dla `zbuduj_ranking` ani `zwieksz_licznik`. Jedyny opisany test to ręczne `curl`. Wystarczy `moto` albo mock `boto3`, żeby sprawdzić sortowanie i `limit`.
- **Dane w kodzie.** `QUOTES` jest zaszyte w module, mimo że liczniki są w bazie. Warto to zaznaczyć jako dług, jeśli lista ma rosnąć do tysięcy pozycji.
- **Tabela DynamoDB.**
  - Brakuje `point_in_time_recovery` i jawnego `server_side_encryption`. Domyślne szyfrowanie działa, ale skanery (checkov) mogą to zgłosić. Napraw przyczynę, nie dodawaj `#checkov:skip`.
  - Tag `Blok = "lab05"` odbiega od schematu `b<N>` z konwencji repo.
- **Kosmetyka.** Komentarz w pierwszej linii `iam-ranking.tf` nie ma polskich znaków („licznikow", „wyswietlen").
- **Opis PR.** Dodaj, że zmiana wymaga nowej polityki IAM i tabeli, oraz wskaż zmienną `STATS_TABLE`.

## Uwaga do procesu
Kod został wygenerowany przez AI i przejrzany pobieżnie. Najpoważniejszy problem (zbyt szerokie uprawnienia) jest w pliku, który nie wpływa na wynik `curl`, więc test funkcjonalny nigdy by go nie wykrył. Przy zmianach w IAM warto uruchomić skaner (checkov/tfsec) w CI i recenzować politykę osobno od kodu aplikacji.
