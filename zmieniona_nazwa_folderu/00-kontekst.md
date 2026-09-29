# Kontekst projektu (Cline)

Celowo ta sama treść co w `.claude/CLAUDE.md`. W Bloku 1 porównujemy, jak dwa różne
agenty wykorzystują identyczny kontekst — różnica ma leżeć w sposobie pracy, nie w tym,
że jednemu daliśmy lepsze instrukcje.

## Stack

- Aplikacja: Python 3.12, FastAPI, testy w pytest, lint `ruff`
- Infrastruktura: Terraform, provider `hashicorp/aws`, region `eu-central-1`
- Kubernetes: EKS, wdrożenia przez Argo Rollouts (obiekt `Rollout`, nie `Deployment`).
  Wyjątek: dzień 1 (lab02) wdraża zwykły `Deployment` `quotes-api-d1` z `app/k8s-dzien1/`
- CI/CD: GitHub Actions, uwierzytelnianie do AWS przez OIDC
- Feature-flagi: OpenFeature + flagd
- Sekrety: GitHub Secrets, nigdy wartości w repo

## Konwencje

- Nazwy zasobów: `szkolenie-<blok>-<zasob>-<uczestnik>`
- Tagi na każdym zasobie AWS: `Projekt`, `Uczestnik`, `Blok`, `Usuwac = tak`
- Zmienne Terraform zawsze z `description` i jawnym `type`
- Bucket S3: szyfrowanie, blokada dostępu publicznego, wersjonowanie
- Security group: żadnego `0.0.0.0/0` poza portem 443
- Workflow: zawsze `permissions:` i `timeout-minutes`
- Teksty po polsku, nazwy techniczne po angielsku

## Czego nie rób

- Nie uruchamiaj `terraform apply` ani `kubectl delete` bez wyraźnej prośby
- Nie wyciszaj skanerów przez `#checkov:skip`
- Nie otwieraj plików `.env`, `*.tfvars`, `credentials`
- W `labs/*/start/` są celowo niepełne lub błędne pliki; nie poprawiaj ich bez polecenia
