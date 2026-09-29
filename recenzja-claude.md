# Recenzja Claude — zmiany w working tree (`git diff`, 15 plików)

Brak otwartego PR i różnicy `main...HEAD` (branch `main`), więc zrecenzowano niezatwierdzone
zmiany. Przeczytano cały diff przed komentowaniem. Żadnych plików nie zmieniano.

## Przebieg 1 — poprawność

```
[BLOKUJĄCE] infra/modules/app-storage-bledny/* (usunięty w całości)
Problem:    Usunięto moduł z celowymi błędami, do którego odwołują się skrypt i materiały szkoleniowe.
Scenariusz: `scripts/waliduj.sh:9` ma go jako domyślny katalog. Na czystym checkoucie
            `cd "$KATALOG"` się nie udaje. `prompts/blok1-iac.md:37`, `.claude/CLAUDE.md:37`
            i `docs/claudecode/claude-code.md:41` wskazują nieistniejący katalog,
            więc Blok 1 nie ruszy. Kopia leży tylko w nieśledzonym `tmp/`.
Poprawka:   git checkout HEAD -- infra/modules/app-storage-bledny
            (a jeśli usunięcie jest zamierzone: najpierw zmienić waliduj.sh, prompt i CLAUDE.md)
```

```
[BLOKUJĄCE] infra/modules/app-storage/main.tf:5 i :22
Problem:    Zmiana `prefix` i nazwy bucketu zmienia nazwy wszystkich zasobów, a zmiana CIDR-ów
            wymusza odtworzenie VPC i podsieci (main.tf:89, :98, variables.tf:20).
Scenariusz: `terraform apply` na istniejącym stanie uczestnika próbuje usunąć bucket
            `szkolenie-b1-anna-k-artifacts` z włączonym wersjonowaniem. To kończy się
            BucketNotEmpty albo utratą artefaktów. VPC z 10.20 → 10.40 rozbiera też
            podsieci i security group, które mogą być już podpięte (np. do EKS).
Poprawka:   Zostawić dotychczasowe nazwy i CIDR albo dodać bloki `moved {}`. Odtworzenie
            bucketu z danymi wymaga świadomej decyzji, a `terraform plan` w opisie PR
            powinien pokazać liczbę zasobów do `replace`.
```

```
[WAŻNE] infra/modules/app-storage/variables.tf (usunięta zmienna `region`)
Problem:    Usunięcie wejścia modułu to zmiana łamiąca interfejs, a README modułu, który je opisywał, też skasowano.
Scenariusz: Każdy, kto wywołuje moduł z `region = "eu-central-1"` (wg dotychczasowej
            dokumentacji), dostaje "Unsupported argument".
Poprawka:   Przywrócić zmienną albo zaznaczyć zmianę w opisie PR. W repo nie znalazłem
            wywołania z `region`, więc ryzyko dotyczy uczestników.
```

```
[WAŻNE] labs/lab02-workflow-z-ai/README.md:50
Problem:    Zmienna `AWS_DEPLOY_ROLE_ARN` dostała ARN użytkownika IAM
            `user/dawid-r/...` zamiast roli, do tego z wiodącą spacją w cudzysłowie.
Scenariusz: Uczestnik kopiuje polecenie. Spacja i ARN typu `user` sprawiają, że
            `aws-actions/configure-aws-credentials` z OIDC zwraca błąd
            (AssumeRoleWithWebIdentity wymaga roli), a lab02 staje na pierwszym uruchomieniu.
Poprawka:   gh variable set AWS_DEPLOY_ROLE_ARN --body "arn:aws:iam::<KONTO>:role/github-actions-deploy"
```

```
[DROBIAZG] labs/lab02-workflow-z-ai/README.md:29
Problem:    Ścieżka `<root Twojego repo>/.github/...` zastąpiona osobistą `reszczak/ai-devops-cicd/...`.
Scenariusz: Każdy inny uczestnik ma inną ścieżkę, a instrukcja wskazuje repozytorium jednej osoby.
Poprawka:   Wrócić do `<root Twojego repo>/.github/workflows/deploy.yml`.
```

## Przebieg 2 — bezpieczeństwo

```
[WAŻNE] labs/lab02-workflow-z-ai/README.md:50
Problem:    Do repo trafił prawdziwy identyfikator konta AWS (574921529806) i nazwa użytkownika IAM.
Scenariusz: Repo jest udostępniane uczestnikom lub forkowane, a numer konta i login IAM
            ułatwiają rekonesans (enumeracja ról, phishing). To nie sekret, ale też nie
            powinno być w materiałach.
Poprawka:   Placeholder `<KONTO>`, wartość z `.env` (jak reszta instrukcji).
```

```
[WAŻNE] labs/lab01-walidacja-i-fix/start/main.tf:28,76,91 oraz start/variables.tf:17
Problem:    Pliki startowe ćwiczenia zostały naprawione (szyfrowanie, hardcoded ARN, `0.0.0.0/0` na 514).
Scenariusz: `start/` ma zawierać błędy, które uczestnik znajduje i poprawia. Po tej
            zmianie skaner nie ma czego zgłosić i lab01 traci sens. Zasady repo zabraniają
            poprawiania tych plików bez polecenia. Dodatkowo domyślny `cidr_vpc` w labie
            (10.20.0.0/16) nie zgadza się z nowym CIDR modułu (10.40.0.0/16). Kolektor
            używający VPC z modułu blokowałby syslog po cichu.
Poprawka:   Przywrócić `start/` z HEAD. Rozwiązanie pokazuje prowadzący.
```

```
[DROBIAZG] infra/modules/app-storage/main.tf:91
Problem:    `map_public_ip_on_launch = true` na podsieci publicznej.
Scenariusz: Każda instancja uruchomiona w tej podsieci dostaje publiczny IP bez jawnej decyzji.
            Skaner (CKV_AWS_130) to zgłosi, a konwencja zabrania wyciszania go w kodzie.
Poprawka:   Usunąć atrybut. Zasób, który potrzebuje publicznego IP, dostaje go jawnie.
```

Pozostałe zmiany w Terraformie wyglądają dobrze: `aws_default_security_group` bez reguł,
`abort_incomplete_multipart_upload`, egress tylko na 443 i komplet tagów. Sieć nie ma sekretów.

## Przebieg 3 — złożoność i wydajność

Nie znaleziono nic z realnym scenariuszem. Nie ma pętli ani zapytań.

## Dokumentacja i materiały

```
[WAŻNE] infra/modules/app-storage/README.md i .clinerules/* (usunięte)
Problem:    Skasowano README z tabelą decyzji o zgłoszeniach skanera oraz reguły Cline.
Scenariusz: `labs/lab01-walidacja-i-fix/README.md:40` odsyła do tej tabeli.
            `labs/lab04-cline-jako-recenzent/README.md` (linie 11, 26, 28, 61, 72),
            `prompts/blok3-review.md:6` i `README.md:48` odsyłają do `.clinerules/10-recenzja-pr.md`.
            Uczestnik otwiera nieistniejący plik. Znikają też uzasadnienia dla
            AVD-AWS-0104/0132/0178, więc zgłoszenia stają się niewyjaśnionymi
            "błędami" (a zasada repo mówi: zapisz decyzję, nie wyciszaj).
Poprawka:   git checkout HEAD -- .clinerules infra/modules/app-storage/README.md
            i zaktualizować README o zmiany (m.in. usuniętą `region`, nowe wyjścia).
```

Zmiany w `.claude/commands/pr-review.md` są w porządku.

## Werdykt

**DO POPRAWY.** Blokują:

1. Usunięcie `app-storage-bledny` psuje `waliduj.sh` i Blok 1.
2. Zmiana prefiksu, nazwy bucketu i CIDR wymusza odtworzenie zasobów z danymi. Brakuje `plan` i bloków `moved`.

Do naprawy przed merge'em: zepsuty ARN i konto AWS w lab02, naprawione pliki `labs/lab01/start`,
usunięte README i `.clinerules` z żywymi odwołaniami oraz usunięta zmienna `region`.
