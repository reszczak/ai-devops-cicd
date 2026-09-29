# Moduł `app-storage` — wersja referencyjna

Infrastruktura pod aplikację `quotes-api`: bucket na artefakty, sieć i security group.

To jest **wzorzec**, do którego porównujemy wyniki generowania z AI (Blok 1) i rozwiązania
z labu 01. Nie ma tu żadnych celowych błędów — te są w `../app-storage-bledny/`.

## Użycie

```hcl
module "app_storage" {
  source     = "../../modules/app-storage"
  uczestnik  = "anna-k"
  blok       = "b1"
}
```

## Wejście

| Zmienna | Typ | Domyślna | Opis |
|---|---|---|---|
| `uczestnik` | string | — | Identyfikator uczestnika, wchodzi w nazwy zasobów |
| `blok` | string | `"b1"` | Numer bloku szkolenia, do tagów |
| `region` | string | `"eu-central-1"` | Region AWS |
| `cidr_vpc` | string | `"10.20.0.0/16"` | Zakres adresów VPC |

## Wyjście

| Wyjście | Opis |
|---|---|
| `bucket_name` | Nazwa bucketu na artefakty |
| `vpc_id` | ID utworzonej VPC |
| `security_group_id` | ID security group aplikacji |

## Co ten moduł robi dobrze — i dlaczego

- **Bucket ma szyfrowanie i blokadę dostępu publicznego.** Domyślne ustawienia AWS nie
  wystarczają; `aws_s3_bucket_public_access_block` musi być zasobem jawnym.
- **Security group wpuszcza tylko 443.** Port 22 z internetu nie jest potrzebny do niczego,
  co robimy na szkoleniu.
- **Reguły egress są zawężone.** Domyślny `0.0.0.0/0` na wyjściu przechodzi przez skanery,
  ale ułatwia wyprowadzenie danych.
- **Wszystkie zasoby mają komplet tagów.** `Usuwac = tak` pozwala prowadzącemu znaleźć
  zapomniane zasoby podczas sprzątania konta szkoleniowego.

## Cztery zgłoszenia, które tu zostają — i dlaczego

Ten moduł **nie przechodzi skanerów na zero**. To nie jest niedopatrzenie, tylko materiał
do Bloku 1: zielony wynik skanera nie jest celem, celem jest świadoma decyzja przy każdym
zgłoszeniu.

| Zgłoszenie | Decyzja |
|---|---|
| `AVD-AWS-0104` — nieograniczony ruch wychodzący | **Zostaje.** Aplikacja musi sięgać do ECR i API AWS. Zawęziliśmy port do 443; zawężenie adresów wymagałoby VPC Endpoints, co na koncie szkoleniowym kosztuje więcej, niż daje. W projekcie produkcyjnym: endpointy zamiast IGW. |
| `AVD-AWS-0132` — brak klucza zarządzanego przez klienta | **Zostaje.** SSE-S3 wystarcza dla artefaktów buildów, które i tak wygasają po 30 dniach. CMK ma sens tam, gdzie potrzebujesz własnej rotacji i audytu użycia klucza. |
| `AVD-AWS-0178` — brak VPC Flow Logs | **Zostaje.** Flow logs wymagają grupy CloudWatch i roli IAM, a płaci się za każdy zapisany gigabajt. Na środowisku żyjącym dwa dni to koszt bez zwrotu. Na produkcji — włącz. |
| `AVD-AWS-0090` (w wariancie bez wersjonowania) | **Naprawione.** Wersjonowanie jest włączone — to jedyna rzecz, która ratuje po przypadkowym nadpisaniu artefaktu. |

Różnica między tą tabelą a dopisaniem `#checkov:skip` w czterech miejscach jest taka,
że tutaj decyzja jest zapisana razem z uzasadnieniem i da się ją zakwestionować przy
następnym przeglądzie. Wyciszenie w kodzie znika z pola widzenia po tygodniu.
