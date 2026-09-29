# Recenzja zmian: working tree względem `main`

Recenzja wykonana przez Cline według schematu z `.clinerules/10-recenzja-pr.md`.

Jesteśmy na `main`, a zmiany nie są zacommitowane, więc `main...HEAD` był pusty i użyłem
`git diff HEAD`. Przeczytałem cały diff, w tym usunięcie `app-storage-bledny`. Niczego nie
uruchamiałem ani nie poprawiałem.

## Znaleziska

```
[BLOKUJĄCE] labs/lab02-workflow-z-ai/README.md:50
Problem:    Komenda `gh variable set AWS_DEPLOY_ROLE_ARN` ma czyjeś prawdziwe ID konta, ARN typu `user/dawid-r/...` zamiast `role/...` i spację przed `arn:`.
Scenariusz: Uczestnik kopiuje komendę, zmienna dostaje wartość ze spacją i nieistniejącą rolą. `aws-actions/configure-aws-credentials` kończy się błędem OIDC AssumeRole na pierwszym uruchomieniu workflow. Prywatne ID konta i nazwa użytkownika trafiają też do repo szkoleniowego.
Poprawka:   gh variable set AWS_DEPLOY_ROLE_ARN --body "arn:aws:iam::<KONTO>:role/github-actions-deploy"
```

```
[WAŻNE] labs/lab02-workflow-z-ai/README.md:29
Problem:    Ścieżka `<root Twojego repo>/.github/workflows/deploy.yml` została zastąpiona przez `reszczak/ai-devops-cicd/.github/...`, czyli nazwę konkretnego użytkownika.
Scenariusz: Uczestnik pracujący w swoim forku tworzy plik pod cudzą ścieżką albo nie wie, gdzie go położyć, więc wynik labu nie trafia w `.github/workflows/`.
Poprawka:   Przywrócić `<root Twojego repo>/.github/workflows/deploy.yml`.
```

```
[WAŻNE] infra/modules/app-storage-bledny/* (usunięty w całości) oraz infra/modules/app-storage/README.md (usunięty)
Problem:    Usunięto moduł z celowymi błędami i README modułu referencyjnego, a odwołania do nich zostały.
Scenariusz: Odwołują się do nich m.in. `prompts/blok1-iac.md:37` (skanery na `app-storage-bledny`), `.claude/CLAUDE.md:37`, `docs/claudecode/claude-code.md:41` i `labs/lab01-walidacja-i-fix/README.md:40` (tabela decyzji w README modułu). W Bloku 1 komendy skanujące wskazują nieistniejący katalog. Uzasadnienia świadomie pozostawionych zgłoszeń (AVD-AWS-0104, 0132, 0178) znikają, a lab01 odsyła do nieistniejącej tabeli. Kopie leżą w niezatrackowanym `tmp/modules/`, więc na czystym checkoucie ich nie będzie.
Poprawka:   Przywrócić oba elementy (`git checkout HEAD -- infra/modules/app-storage-bledny infra/modules/app-storage/README.md`). Jeśli usunięcie jest zamierzone, zaktualizować wszystkie odwołania.
```

```
[WAŻNE] infra/modules/app-storage/main.tf:22 (oraz :89, :98 i variables.tf:20)
Problem:    Zmieniły się nazwa bucketu (`szkolenie-b1-<u>-artifacts` na `szkolenie-b1-artifacts-<u>`), indeksy podsieci i domyślny CIDR VPC (10.20 na 10.40), co wymusza odtworzenie zasobów.
Scenariusz: Uczestnik ma już zastosowany stan i robi `apply`. Bucket dostaje nową nazwę, więc Terraform próbuje go usunąć razem z artefaktami. Bez `force_destroy` operacja kończy się błędem BucketNotEmpty na wersjonowanym, niepustym buckecie. VPC, podsieci i SG też są niszczone i tworzone od nowa.
Poprawka:   Zmiana nazw zgodnie z konwencją jest w porządku, ale najpierw `terraform plan` i przegląd sekcji „must be replaced". Dla istniejących środowisk najpierw opróżnić bucket albo użyć `moved`/`terraform state mv`. Zmianę CIDR i indeksów warto wydzielić do osobnego PR.
```

```
[WAŻNE] labs/lab01-walidacja-i-fix/start/main.tf:28, :76, :91 (oraz start/variables.tf:17)
Problem:    Zmodyfikowano plik startowy labu, w którym błędy są celowe: dodano szyfrowanie, zastąpiono zakodowany ARN i zawężono 514/tcp z `0.0.0.0/0`. Zasady repo zabraniają poprawiania `labs/*/start/` bez polecenia.
Scenariusz: Uczestnicy lab01 dostają plik, w którym skanery nie znajdują tych trzech problemów, więc ćwiczenie z walidacji i poprawek traci sens. Nowa zmienna `cidr_vpc` ma domyślnie `10.20.0.0/16`, a moduł po tym diffie tworzy VPC `10.40.0.0/16`. Kolektor wdrożony w takiej VPC odrzuca syslog.
Poprawka:   Cofnąć zmiany w `labs/lab01-walidacja-i-fix/start/` (`git checkout HEAD -- labs/lab01-walidacja-i-fix/start`). Rozwiązanie ma trafić do materiałów prowadzącego.
```

```
[DROBIAZG] infra/modules/app-storage/main.tf:91
Problem:    `map_public_ip_on_launch = true` na podsieci publicznej nadaje publiczne IP każdej instancji.
Scenariusz: Ktoś uruchamia w tej podsieci instancję bez zamiaru wystawiania jej. Dostaje publiczne IP, a SG z ingress 443 z `0.0.0.0/0` daje jej ekspozycję. Skanery zgłoszą to jako AVD-AWS-0164.
Poprawka:   Usunąć atrybut. Publiczne IP nadawać jawnie tam, gdzie jest potrzebne (`associate_public_ip_address`).
```

```
[DROBIAZG] kubectl-argo-rollouts-linux-amd64 oraz tmp/ (niezatrackowane w katalogu głównym repo)
Problem:    W katalogu głównym leży binarka i katalog tymczasowy z kopiami modułów.
Scenariusz: `git add .` commituje binarkę o rozmiarze kilkudziesięciu MB i zduplikowane moduły do PR.
Poprawka:   Dodać do `.gitignore` albo usunąć przed commitem.
```

## Bez uwag

- `.claude/commands/pr-review.md` i `.clinerules/10-recenzja-pr.md` (reguła timeoutu HTTP i format znalezisk).
- Zmiany w `aws_default_security_group`, `abort_incomplete_multipart_upload` i zawężenie egress do 443 są poprawne.
- Usunięcie nieużywanej zmiennej `region` jest w porządku, bo żaden wywołujący jej nie przekazuje.

## Werdykt

**DO POPRAWY.** Blokuje ARN w README lab02 (linia 50). Do rozstrzygnięcia przed merge'em
zostają usunięcie modułu `app-storage-bledny` z README, zmiany w `labs/lab01/start`
i odtworzenie zasobów przy `apply`.
