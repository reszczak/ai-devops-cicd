# Luki we wzorcach AWS w `straznik.py`

Wzorce „ARN zasobu AWS” i „identyfikator konta AWS” z listy `WZORCE` mają luki.
Poniższe prompty sprawdzono na samych wzorcach z `WZORCE` (osobnym skryptem `re`) —
żaden z nich nie został zatrzymany. Skaner `Secrets` z `llm_guard` nie był sprawdzany.

## Trzy przykłady, które przechodzą, a nie powinny

### 1. Zmienna środowiskowa `AWS_ACCOUNT_ID`

```
export AWS_ACCOUNT_ID=123456789012
```

Wzorzec wymaga cyfr zaraz po `account` / `aws_account`, a tu w środku jest `_ID`.
Wersja `Account: 123456789012` (samo `Account`, bez `id`) też przechodzi.

### 2. Identyfikator konta w adresie ECR

```
docker pull 123456789012.dkr.ecr.eu-central-1.amazonaws.com/quotes-api
```

Konto stoi na początku hosta, bez słowa kontekstowego przed nim. To samo dotyczy
`123456789012.signin.aws.amazon.com`.

### 3. Identyfikator w innym zapisie

```
Konto w konsoli: 1234-5678-9012
```

Konsola AWS pokazuje numer z myślnikami, a wzorzec oczekuje 12 cyfr pod rząd.

Inne warianty, które również przechodzą:

| Prompt | Dlaczego przechodzi |
|---|---|
| `konto produkcyjne to 123456789012` | między słowem „konto” a cyframi stoi inny tekst |
| `ARN:AWS:iam::123456789012:role/Admin` | wzorzec ARN rozróżnia wielkość liter |
| `arn:aws:iam:: 123456789012 :role/Admin` | wzorzec nie dopuszcza spacji w środku |

## Ograniczenia ogólne

- Wzorce działają na dosłownym tekście — ARN zakodowany base64, rozbity na linie
  albo podzielony na części przejdzie.
- ARN z placeholderem (`arn:aws:iam::${ACCOUNT}:role/x`) zostanie zatrzymany,
  choć nic nie wycieka (fałszywy alarm).

## Możliwe poprawki

- Dodać `(?i)` do wzorca ARN i dopuścić `AWS_ACCOUNT_ID` oraz samo `account`.
- Dodać wzorce `\b\d{12}\.dkr\.ecr\.` oraz `\b\d{4}-\d{4}-\d{4}\b`.

Wniosek dla demo: lista wzorców nigdy nie będzie kompletna.
