# Moduł `app-storage-bledny`

Ten sam moduł co `../app-storage`, ale z celowo wprowadzonymi błędami. Służy do demo
walidacji w Bloku 1.

**Nie naprawiaj go.** Jest zepsuty z premedytacją i ma taki zostać — inaczej demo przestanie
działać. Jeśli chcesz poćwiczyć naprawianie, użyj kopii z `labs/lab01-walidacja-i-fix/start/`.

Skanery **mają** na nim zgłaszać błędy. Czerwony wynik jest tu wynikiem oczekiwanym:

```bash
terraform validate     # przechodzi — składnia jest poprawna
tflint                 # zgłasza
checkov -d .           # zgłasza
trivy config .         # zgłasza
```

Pełny przebieg walidacji uruchomisz z katalogu głównego przez `./scripts/waliduj.sh`.
