# Recenzja zmian względem main

## Zakres

Lokalnie istnieje tylko branch `main`, więc `git diff main...HEAD` jest pusty (0 commitów).
Zrecenzowany został niezacommitowany diff `git diff HEAD`: 15 plików, +117/−311. Diff został przeczytany w całości.

Pliki nieśledzone (`tmp/`, `zmieniona_nazwa_folderu/`, `RECENZJA-z-zaleznosciami.md`, binarka) nie wchodzą do diffu.
Nie sprawdzano, czy `terraform validate` przechodzi na zmienionym module.

---

## Znaleziska

### [BLOKUJĄCE] infra/modules/app-storage-bledny/* (usunięty w całości)

- **Problem:** usunięto moduł z celowymi błędami, na którym opiera się demo z Bloku 1.
- **Scenariusz:** `./scripts/waliduj.sh` bez argumentu ma domyślny katalog `infra/modules/app-storage-bledny` (linia 9). Po zmianie `cd "$KATALOG"` się nie udaje, a `terraform validate` nie ma czego sprawdzać. Prompt `prompts/blok1-iac.md:37` i `.claude/CLAUDE.md:37` wskazują ten sam nieistniejący katalog. Kopia jest tylko w nieśledzonym `tmp/modules/`, więc na czystym checkoucie jej nie będzie.
- **Poprawka:** `git checkout HEAD -- infra/modules/app-storage-bledny`. Jeśli usunięcie jest zamierzone, trzeba najpierw zmienić `waliduj.sh`, prompt i CLAUDE.md.

### [BLOKUJĄCE] labs/lab02-workflow-z-ai/README.md:50

- **Problem:** w komendzie `gh variable set AWS_DEPLOY_ROLE_ARN` wpisano ARN konkretnej osoby: ` arn:aws:iam::574921529806:user/dawid-r/github-actions-deploy`.
- **Scenariusz:** ARN zaczyna się od spacji, więc jest niepoprawny. Jest też typu `user/`, a pipeline używa OIDC i roli (`role/`). Uczestnik kopiuje komendę, a `aws-actions/configure-aws-credentials` kończy się błędem przy `AssumeRole`. Dodatkowo ID konta AWS trafia do repo szkoleniowego.
- **Poprawka:** przywrócić placeholder `"arn:aws:iam::<KONTO>:role/github-actions-deploy"`.

### [WAŻNE] labs/lab02-workflow-z-ai/README.md:29

- **Problem:** ścieżka `<root Twojego repo>/.github/workflows/deploy.yml` zastąpiona przez `reszczak/ai-devops-cicd/.github/...`.
- **Scenariusz:** każdy inny uczestnik dostaje w instrukcji nazwę cudzego konta GitHub. Może zapisać plik w katalogu `reszczak/`, gdzie GitHub Actions go nie wykryje.
- **Poprawka:** przywrócić `<root Twojego repo>/.github/workflows/deploy.yml`.

### [WAŻNE] labs/lab01-walidacja-i-fix/start/main.tf:28, :76, :91 oraz variables.tf:17

- **Problem:** naprawiono błędy w pliku startowym ćwiczenia (brak szyfrowania, zahardkodowany ARN, syslog 514 z `0.0.0.0/0`). CLAUDE.md zabrania tego bez polecenia: `labs/*/start/` to pliki startowe, a rozwiązania omawia prowadzący.
- **Scenariusz:** uczestnik uruchamia skanery na `start/` i dostaje niemal zero zgłoszeń, więc ćwiczenie „walidacja i fix" nie ma czego naprawiać.
- **Poprawka:** cofnąć zmiany w `labs/lab01-walidacja-i-fix/start/`. Jeśli ktoś chce rozwiązanie, ma trafić do `solution/` albo do materiałów prowadzącego. Przy okazji: `egress 0.0.0.0/0` w linii 99 zostało nietknięte, więc nawet jako „naprawa" plik jest niespójny.

### [WAŻNE] infra/modules/app-storage/main.tf:22, :89, :98, :147 oraz variables.tf:20

- **Problem:** zmiany nazw i adresacji wymuszają odtworzenie zasobów w istniejącym stanie:
  - nazwa bucketu z `…-b1-<uczestnik>-artifacts` na `…-b1-artifacts-<uczestnik>`,
  - `name` security group (ForceNew),
  - CIDR obu podsieci (`cidrsubnet(..., 1/2)` na `0/1`),
  - domyślny `cidr_vpc` z `10.20.0.0/16` na `10.40.0.0/16`.
- **Scenariusz:** uczestnik po Bloku 1 ma stan z bucketem i VPC. `deploy.sh` robi `plan`, a potem `apply`. Plan pokaże `destroy/create` bucketu z włączonym wersjonowaniem, a `apply` padnie na `BucketNotEmpty` albo usunie artefakty. Zmiana CIDR VPC zniszczy całą sieć.
- **Poprawka:** jeśli to zmiana zamierzona (nowa nazwa jest zgodna z konwencją `<blok>-<zasob>-<uczestnik>`), opisać ją w commicie jako breaking i dodać `moved`/`terraform state mv` albo wymóg `destroy` przed `apply`. Zmianę CIDR wycofać, bo nic jej nie uzasadnia.

### [WAŻNE] infra/modules/app-storage/README.md (usunięty) oraz .clinerules/* (usunięte)

- **Problem:** usunięto tabelę „Cztery zgłoszenia, które tu zostają" i oba pliki Cline.
- **Scenariusz:** `labs/lab01-walidacja-i-fix/README.md:40,59` odsyła do tej tabeli. `labs/lab04-cline-jako-recenzent/README.md:11,26,28,61,72`, `prompts/blok3-review.md:6` i `README.md:48` odsyłają do `.clinerules/10-recenzja-pr.md`. Lab04 każe „otworzyć" nieistniejący plik i porównać recenzję „z `.clinerules` i bez", a bez tych plików nie ma jak tego zrobić. Uzasadnienia dla AVD-AWS-0104/0132/0178 znikają razem z nimi.
- **Poprawka:** `git checkout HEAD -- .clinerules infra/modules/app-storage/README.md`. Jeśli reguły celowo przeniesiono do `.claude/commands/pr-review.md`, zaktualizować wszystkie odwołania.

### [DROBIAZG] infra/modules/app-storage/main.tf:91

- **Problem:** `map_public_ip_on_launch = true` na podsieci publicznej, a nic w module nie uruchamia instancji.
- **Scenariusz:** `trivy config` zgłasza AVD-AWS-0164. Wcześniej takie zgłoszenia miały uzasadnienie w usuniętym README, teraz to jest nowe, nieudokumentowane zgłoszenie. Każda instancja dołożona później w tej podsieci dostaje publiczny IP bez jawnej decyzji.
- **Poprawka:** usunąć linię albo dopisać decyzję do README.

### [DROBIAZG] .claude/commands/pr-review.md (linia z `git diff main...HEAD`)

- **Problem:** komenda zakłada commity na branchu i nie ma obsługi pustego diffu.
- **Scenariusz:** uruchomienie na `main` z lokalnymi zmianami daje pusty diff. Agent może ocenić „APROBATA" bez przeczytania czegokolwiek. Tak wyglądało to w tej recenzji.
- **Poprawka:** dopisać „jeśli `git diff main...HEAD` jest pusty, sprawdź `git diff HEAD` i napisz, co recenzujesz. Jeśli obie wersje są puste, przerwij".

### [DROBIAZG] kubectl-argo-rollouts-linux-amd64 (nieśledzony, ~135 MB), `tmp/`, `zmieniona_nazwa_folderu/`

- **Problem:** binarka i katalogi robocze leżą w rootcie repo.
- **Scenariusz:** `git add .` wrzuca 135 MB do historii, a to trudno cofnąć.
- **Poprawka:** przenieść poza repo albo dopisać do `.gitignore`.

---

## Werdykt: DO POPRAWY

Blokują dwa punkty:

1. Usunięty `app-storage-bledny` psuje `waliduj.sh` i Blok 1.
2. Wklejony do README lab02 ARN z osobistymi danymi i spacją psuje ćwiczenie.

Dobre zmiany, które warto zostawić w module `app-storage`:

- `aws_default_security_group` bez reguł,
- osobna route table dla podsieci prywatnej,
- `abort_incomplete_multipart_upload`,
- nazwy zgodne z konwencją.

Podczas recenzji nie zmieniano żadnych plików.
