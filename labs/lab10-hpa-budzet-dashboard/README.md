# Lab 10 — skalowanie i widoczność

**Blok 5 · 25 minut**

## Zadanie

Doprowadź aplikację do stanu, w którym przetrwa obciążenie, i dołóż panel, który to pokazuje.

### Etap 1 — zmierz, zanim zmienisz (7 min)

Lab korzysta z aplikacji wdrożonej w lab07. Polecenia uruchamiaj z głównego katalogu repo:

```bash
cd "$(git rev-parse --show-toplevel)"
set -a; source .env; set +a
export NS=$UCZESTNIK
kubectl apply -f labs/lab10-hpa-budzet-dashboard/start/hpa.yaml -n $NS
kubectl get hpa,pods -n $NS -w      # zostaw na ekranie
```

W drugim terminalu, też z głównego katalogu:

```bash
set -a; source .env; set +a
./scripts/obciaz.sh $UCZESTNIK
```

Zapisz trzy liczby:

- ile sekund minęło od startu obciążenia do pierwszej **działającej** nowej repliki - 30
- do ilu replik doszło skalowanie - 3
- jaki był p95 czasu odpowiedzi w szczycie - 684 ms

### Etap 2 — dostrój (10 min)

`labs/lab10-hpa-budzet-dashboard/start/hpa.yaml` jest ustawiony źle: próg 90% i maksymalnie
3 repliki. Po każdej zmianie ponów `kubectl apply` i ten sam test obciążenia.
Zmień parametry tak, żeby p95 nie przekroczył 1 sekundy pod tym samym obciążeniem.

Możesz poprosić agenta o propozycję — ale zmierz wynik sam. Zmiana, której efektu
nie zmierzyłeś, jest zgadywaniem.

### Etap 3 — panel (8 min)

Dodaj do dashboardu `quotes-api` w Grafanie panel pokazujący liczbę replik w czasie,
z zaznaczonym progiem HPA.

Prompt: `prompts/blok5-guardrails.md`, sekcja „Dashboard".

## Podpowiedzi

<details>
<summary>Podpowiedź 1 — HPA pokazuje `<unknown>`</summary>

Brakuje `metrics-server` (sprawdź: `kubectl top pods -n $NS` — błąd `Metrics API not available`
zgłoś prowadzącemu) albo kontener nie ma zdefiniowanych `resources.requests`.
HPA liczy wykorzystanie jako procent **względem requests** — bez nich nie ma od czego liczyć.
</details>

<details>
<summary>Podpowiedź 2 — skalowanie startuje za późno</summary>

Trzy parametry wchodzą w grę: próg `averageUtilization`, `scaleUp.stabilizationWindowSeconds`
i wartość `requests.cpu`. Zbyt wysoki request oznacza, że procent rośnie wolno
i HPA reaguje dopiero przy realnym przeciążeniu.
</details>

<details>
<summary>Podpowiedź 3 — repliki nie rosną mimo poprawnej konfiguracji</summary>

```bash
kubectl describe quota -n $NS
kubectl get pods -n $NS | grep Pending
```

`ResourceQuota` namespace'u albo brak miejsca na węzłach. To jest realistyczne ograniczenie
— opisz je w odpowiedzi zamiast obchodzić.
</details>

## Weryfikacja

Pod tym samym obciążeniem p95 poniżej 1 s, a panel w Grafanie pokazuje moment skalowania.
Porównaj swoje parametry z wersją pokazaną przez prowadzącego — nie muszą być identyczne,
ale uzasadnienie powinno się zgadzać.

## Pułapki

**Autoskalowanie jako odpowiedź na skok ruchu.** Od wzrostu obciążenia do działającej repliki
mija zwykle 60–90 sekund: metryki co 15 s, przeliczenie co 15 s, start poda, readiness.
Na nagły skok pomaga zapas mocy, nie HPA.

**Skalowanie po CPU dla aplikacji czekającej na I/O.** Taka aplikacja ma niskie CPU
i długie czasy odpowiedzi jednocześnie. HPA nie zareaguje, bo patrzy nie na to.

**`maxReplicas` większe niż pojemność klastra.** HPA poprosi o pody, które nie mają gdzie wstać,
i zostaną w `Pending`. Skalowanie węzłów to osobny mechanizm (Karpenter, Cluster Autoscaler).

**Panel bez progu.** Wykres liczby replik bez zaznaczonego `maxReplicas` nie odpowiada
na pytanie, które zadajesz o trzeciej w nocy: czy jest jeszcze zapas.
