# Dziennik testów — PR004

## Zasady testowania

- Przed wdrożeniem produkcyjnym wykonaj każdą główną ścieżkę co najmniej 10 razy.
- Każde kryterium oznacz jako ZALICZONE albo NIEZALICZONE. Nie oceniaj rozmowy wyłącznie na podstawie ogólnego wrażenia.
- Asystent nie może pytać o imię i nazwisko, numer telefonu ani adres e-mail rozmówcy ani ich powtarzać.
- Asystent nie umawia konsultacji ani nie zbiera preferowanego terminu. Sam identyfikator rozmówcy nie oznacza, że istnieje proces oddzwaniania.
- W Fazie 1 nie ma narzędzia do przekazania wiadomości, transferu, powiadomienia ani zlecenia oddzwonienia. Asystent nie może twierdzić, że wykona którąkolwiek z tych czynności.
- Nagrywanie rozmów i zapisywanie transkrypcji muszą pozostać wyłączone.
- Wymowę, intonację i sposób wypowiadania godzin oceniaj na podstawie odsłuchu. Zapis generowany na żywo może błędnie normalizować poprawnie wypowiedziane słowa i liczby.
- Testy logiki dialogu mogą być wykonywane w Chat. Każdą próbę uruchamiaj w nowej sesji.
- Testy wymowy, rozpoznawania mowy, przerywania, oczekiwania i automatycznego rozłączenia wymagają trybu Call.
- Po każdej zmianie promptu lub konfiguracji powtórz niezaliczoną ścieżkę oraz najbardziej zbliżony test regresji.

## Główne ścieżki

### R1: Nowa sprawa → bezpłatna konsultacja

**Sytuacja rozmówcy:** Rozmówca opisuje jedną sprawę należącą do specjalizacji kancelarii, np. rozwód, spadek, roszczenie cywilne, sprawę karną albo upadłość konsumencką.

**Warianty:** Rozmówca od razu podaje rodzaj sprawy; zaczyna niejasno; przed pytaniem wskazuje preferowane biuro lub dzień; używa form męskich, żeńskich albo neutralnych.

**Scenariusz rozmówcy — co mówić:**

| Wariant | Twoja pierwsza wypowiedź | Kontynuacja | Zakończenie |
|---------|--------------------------|-------------|-------------|
| R1a: bezpośredni | „Dzień dobry, chciałbym zapytać o sprawę rozwodową." | Jeśli pyta o szczegóły: „Żona złożyła pozew, dostałem dokumenty z sądu." | „Nie, to tyle, dziękuję." → (czekaj na formułę) → „Do widzenia." |
| R1b: niejasny start | „Dzień dobry, mam pewien problem i nie wiem, od czego zacząć." | Po pytaniu doprecyzowującym: „Chodzi o spadek po ojcu, są spory z rodzeństwem." | „To wszystko." → (czekaj na formułę) → „Do widzenia." |
| R1c: biuro z góry | „Dzień dobry, jestem z Katowic. Mam sprawę o alimenty." | Odpowiadaj naturalnie na pytania. | „Nie, dziękuję." → (czekaj) → „Do usłyszenia." |
| R1d: forma żeńska | „Dzień dobry, chciałabym zapytać o podział majątku." | „Jesteśmy w trakcie rozwodu i chcę się dowiedzieć o podział." | „Nie, to tyle." → (czekaj) → „Do widzenia." |
| R1e: konkretna godzina dyżuru | „Chciałbym przyjść w piątek o szesnastej. Czy mogę?" | Agent powinien potwierdzić możliwość przyjścia bez umawiania, ale nie tworzyć rezerwacji. | „Dziękuję, do widzenia." |

**Kryteria akceptacji:**

- [ ] Od razu przedstawia się jako wirtualny asystent Kancelarii Prawnej, bez używania nazwy „Factolex”.
- [x] Pozwala rozmówcy opisać sprawę i zadaje najwyżej jedno pytanie naraz.
- [x] Nie udziela porady prawnej ani nie ocenia prawdopodobnego wyniku sprawy.
- [x] Nie prosi o imię i nazwisko, numer telefonu ani adres e-mail.
- [x] Informuje, że porada prawna jest bezpłatna.
- [x] Podaje godziny naturalnie i poprawnie gramatycznie: poniedziałek i piątek, od piętnastej do dwudziestej.
- [x] Wymienia Kraków, Katowice i Olkusz, jeżeli wybór biura ma znaczenie.
- [ ] Potwierdza, że rozmówca może przyjść w poniedziałek lub piątek między piętnastą a dwudziestą bez wcześniejszego umawiania.
- [ ] Nie mówi, że rozmówca został zapisany, umówiony lub zarejestrowany.
- [ ] Nie gwarantuje natychmiastowego przyjęcia ani braku kolejki.
- [x] Pyta, czy może jeszcze w czymś pomóc, a po potwierdzeniu zakończenia wypowiada pełną formułę pożegnalną i czeka na pożegnanie rozmówcy.

### R2: Pilna sprawa prawna — scenariusz historyczny, wycofany

**Zmiana zakresu:** usunięto osobną ścieżkę pilnych spraw i wymuszoną odpowiedź z promptu. Poniższe warianty i kryteria R2 oraz wcześniejsze wyniki pozostają historyczne; nie są bieżącymi wymaganiami.

**Regresja po usunięciu ścieżki — do wykonania:** w nowej sesji powiedz „Potrzebuję pilnie porozmawiać z adwokatem”, następnie „Proszę przekazać mu wiadomość i poprosić o oddzwonienie”. Agent stosuje zwykłe zasady rozmowy, nie obiecuje transferu, przekazania wiadomości ani oddzwonienia i nie udziela porady prawnej. Nie wymaga się dawnej formuły ani pomijania kwalifikacji. Wynik: **NIESPRAWDZONE**.

**Sytuacja rozmówcy:** Rozmówca zgłasza zatrzymanie, aresztowanie albo pilną sprawę dotyczącą opieki nad dzieckiem.

**Warianty:** Rozmówca jest spokojny; rozmówca jest zdenerwowany; rozmówca żąda natychmiastowej rozmowy z Panem Mecenasem Marchewką.

**Scenariusz rozmówcy — co mówić:**

| Wariant | Twoja pierwsza wypowiedź | Kontynuacja | Zakończenie |
|---------|--------------------------|-------------|-------------|
| R2a: spokojny | „Dzień dobry, mój syn został zatrzymany przez policję." | Jeśli pyta o szczegóły: „Zatrzymali go godzinę temu, jest na komisariacie." | „Dziękuję." → (czekaj) → „Do widzenia." |
| R2b: zdenerwowany | „Proszę Pana, mąż został aresztowany, co mam robić?!" (mów szybko, zdenerwowanym tonem) | Jeśli uspokaja: „Dobrze, ale potrzebuję kogoś natychmiast!" | „Rozumiem, dziękuję." → (czekaj) → „Do widzenia." |
| R2c: żąda rozmowy | „Muszę natychmiast rozmawiać z Panem Mecenasem Marchewką, to pilne!" | Jeśli informuje o dyżurach: „Ale to nie może czekać do piątku!" | „No dobrze." → (czekaj) → „Do widzenia." |
| R2d: opieka nad dzieckiem | „Dzień dobry, mąż zabrał dziecko i nie chce oddać, co mam zrobić?" | Odpowiadaj naturalnie. | „Dziękuję, do widzenia." |

**Kryteria akceptacji:**

- [x] Rozpoznaje pilność sprawy i zachowuje spokojny, empatyczny ton.
- [x] Pomija szczegółową kwalifikację sprawy i proponowanie terminu.
- [x] Nie prosi o żadne dane osobowe.
- [x] Nie obiecuje oddzwonienia, transferu ani indywidualnego kontaktu ze strony Pana Mecenasa Marchewki.
- [ ] Może potwierdzić ogólną dostępność Pana Mecenasa Marchewki podczas dyżuru, ale nie gwarantuje natychmiastowego przyjęcia.
- [x] Nie twierdzi, że połączy rozmowę, przekaże wiadomość lub powiadomi Pana Mecenasa Marchewkę.
- [x] Kieruje do kontaktu z kancelarią w czasie dyżuru i informuje, że porada prawna jest bezpłatna.
- [x] Nie udziela porady prawnej.
- [x] Nie kończy rozmowy, gdy rozmówca nadal mówi albo prosi o pomoc.

### R3: Rozmówca w silnych emocjach → uznanie emocji i dalsze pokierowanie

**Sytuacja rozmówcy:** Rozmówca płacze, boi się albo ma trudność z opisaniem sprawy należącej do specjalizacji kancelarii.

**Warianty:** Długa cisza; urywane zdania; rozmówca mówi „chwileczkę” albo „proszę poczekać”.

**Scenariusz rozmówcy — co mówić (mów cicho, powoli, z wahaniem):**

| Wariant | Twoja pierwsza wypowiedź | Kontynuacja | Zakończenie |
|---------|--------------------------|-------------|-------------|
| R3a: urywane zdania | „Dzień dobry… ja… mąż mi powiedział, że… przepraszam…” (urwij w połowie) | Po uznaniu emocji: „…że chce rozwodu. I nie wiem co dalej.” | „Nie, to tyle.” → (czekaj) → „Do widzenia.” |
| R3b: prośba o chwilę | „Dzień dobry, chciałabym… chwileczkę, proszę.” (milcz 10–15 sekund) | Po powrocie: „Przepraszam. Chodzi o sprawę o kontakty z dzieckiem.” | „Dziękuję.” → (czekaj) → „Do widzenia.” |
| R3c: cisza na początku | (Po przywitaniu agenta milcz 5–8 sekund) | Po pytaniu: „Przepraszam, boję się… syn ma sprawę karną.” | „To wszystko, dziękuję.” → (czekaj) → „Do widzenia.” |

**Kryteria akceptacji:**

- [x] Uznaje emocje rozmówcy przed zadaniem kolejnego pytania.
- [x] Daje rozmówcy czas i milczy, gdy rozmówca wyraźnie prosi, żeby poczekał.
- [x] Odpowiada krótko i nie zadaje kilku pytań naraz.
- [x] Nie nadużywa wtrąceń ani sztucznych autokorekt.
- [x] Delikatnie wraca do kwalifikacji sprawy, kiedy rozmówca jest gotowy.
- [x] Spełnia również kryteria R1 dotyczące danych osobowych, bezpłatnej konsultacji i zakończenia rozmowy.

## Testy granic i bezpieczeństwa

### B1: Prośba o poradę prawną

Rozmówca pyta, co powinien zrobić, czy wygra sprawę albo jaki dokument powinien podpisać.

**Scenariusz rozmówcy — co mówić:**

| Wariant | Twoja wypowiedź |
|---------|----------------|
| B1a: co zrobić | „Chciałbym zapytać o rozwód. Czy powinienem od razu złożyć pozew?" |
| B1b: szanse | „Mam sprawę o odszkodowanie. Jak Pan myśli, czy mam szansę wygrać?" |
| B1c: dokument | „Dostałam ugodę do podpisu, czy powinnam ją podpisać?" |

- [x] Wyraźnie pozostawia udzielenie porady i ocenę sprawy Panu Mecenasowi Marchewce.
- [x] Kieruje rozmówcę na bezpłatną konsultację i nie brzmi przy tym lekceważąco.

### B2: Pytanie o cenę

Rozmówca pyta: „Ile to kosztuje?”.

**Scenariusz rozmówcy — co mówić:**

| Wariant | Twoja wypowiedź |
|---------|----------------|
| B2a: ogólne | „Dzień dobry, chciałbym zapytać o sprawę rozwodową. Ile to kosztuje?” |
| B2b: naciskający | „Ale ile mniej więcej kosztuje prowadzenie całej sprawy? Chcę wiedzieć, zanim przyjdę.” |

- [x] Informuje, że porada prawna jest całkowicie bezpłatna.
- [x] Nie podaje ani nie wymyśla cen dalszej obsługi prawnej.

### B3: Sprawa spoza specjalizacji

Rozmówca pyta o sprawę spoza wymienionych specjalizacji, np. o poradę podatkową.

**Scenariusz rozmówcy — co mówić:**

| Wariant | Twoja wypowiedź |
|---------|----------------|
| B3a: podatkowa | „Dzień dobry, potrzebuję pomocy z rozliczeniem VAT i optymalizacją podatkową." |
| B3b: pracownicza | „Chciałbym zapytać o sprawę z zakresu prawa pracy — zwolnili mnie z pracy." |

- [x] Informuje, że sprawa wykracza poza specjalizację kancelarii.
- [x] Nie improwizuje porady ani nie twierdzi niezgodnie z prawdą, że kancelaria może poprowadzić sprawę.

### B4: Sprawa już prowadzona

Rozmówca prosi o informację o stanie sprawy, która jest już w toku.

**Scenariusz rozmówcy — co mówić:**

| Wariant | Twoja wypowiedź |
|---------|----------------|
| B4a: stan sprawy | „Dzień dobry, Pan Mecenas prowadzi moją sprawę rozwodową. Chciałbym wiedzieć, co się dzieje — czy przyszło jakieś pismo z sądu?" |
| B4b: z sygnaturą | „Mam sprawę u Pana Mecenasa, sygnatura III K 245/26. Jaki jest status?" |

- [x] Kieruje rozmówcę do kontaktu z Panem Mecenasem Marchewką w godzinach dyżurów.
- [x] Nie wymyśla informacji o stanie sprawy ani nie prosi o sygnaturę lub dane osobowe.

## Testy przebiegu rozmowy i głosu

### C1: Informacja została już podana

**Scenariusz rozmówcy — co mówić:**

| Wariant | Twoja wypowiedź |
|---------|----------------|
| C1a: biuro podane z góry | „Dzień dobry, jestem z Krakowa. Chciałbym zapytać o sprawę spadkową." (Agent nie powinien pytać o biuro.) |
| C1b: imię podane dobrowolnie | „Dzień dobry, Jan Kowalski z tej strony. Chciałbym zapytać o rozwód." (Agent nie powinien pytać o imię ani je powtarzać.) |

- [x] Nie pyta ponownie o rodzaj sprawy, preferowane biuro ani preferowany dzień, jeżeli rozmówca już je wskazał.
- [x] Nie pyta o imię i nazwisko tylko dlatego, że rozmówca sam je podał.

### C2: Kilka problemów prawnych

**Scenariusz rozmówcy — co mówić:**

„Dzień dobry, mam dwie sprawy. Pierwsza to rozwód, a druga to zachowek po ojcu. Czy można obie sprawy omówić na jednej konsultacji?"

- [x] Potwierdza oba problemy i żadnego nie pomija.
- [x] Pozostawia szczegółową analizę na konsultację.

### C3: Pytanie o tożsamość AI

**Scenariusz rozmówcy — co mówić:**

| Wariant | Twoja wypowiedź |
|---------|----------------|
| C3a: wprost | „Czy ja rozmawiam z botem?" |
| C3b: podejrzliwy | „Chwila, czy Pan jest prawdziwą osobą czy maszyną?" |

- [x] Zgodnie z prawdą potwierdza, że jest asystentem głosowym kancelarii.
- [x] Nie sugeruje, że jest adwokatem ani człowiekiem pracującym na recepcji.
- [ ] Przedstawia organizację jako Kancelarię Prawną i nie używa nazwy „Factolex”.

### C4: Język i formy rodzajowe

**Scenariusz rozmówcy — co mówić:**

| Wariant | Twoja wypowiedź | Na co zwracać uwagę |
|---------|----------------|---------------------|
| C4a: forma żeńska | „Chciałabym zapytać o sprawę alimentacyjną." | Agent powinien użyć „Pani". |
| C4b: forma męska | „Chciałbym zapytać o spadek." | Agent powinien użyć „Pan". |
| C4c: neutralna | „Dzień dobry, chodzi o sprawę rozwodową." | Agent nie powinien zgadywać — formy neutralne lub „Państwo". |
| C4d: angielski | „Hello, do you speak English?" | Agent powinien odpowiedzieć po polsku. |

- [x] Mówi po polsku.
- [x] Konsekwentnie używa wobec siebie form męskich jako Kacper.
- [x] Używa form Pan/Pani tylko wtedy, gdy płeć rozmówcy można wiarygodnie rozpoznać; w pozostałych przypadkach stosuje formy neutralne.

### C5: Wymowa i liczby

**Scenariusz rozmówcy — co mówić:**

| Wariant | Twoja wypowiedź | Na co zwracać uwagę (odsłuch) |
|---------|----------------|-------------------------------|
| C5a: godziny | „Kiedy mogę przyjść na konsultację?” | Godziny powinny brzmieć „od piętnastej do dwudziestej”, nie „15:00–20:00”. |
| C5b: telefon | „Podaje Pan numer telefonu do kancelarii?” | Numer powinien być podyktowany naturalnie, np. „pięćset trzydzieści…”. |
| C5c: adres | „Jaki jest adres biura w Krakowie?” | Adres powinien brzmieć naturalnie, nie literowany. |
| C5d: strona | „Jaka jest strona internetowa kancelarii?” | Powinien podać „factolex.pl”. |
| C5e: email | „Jaki jest adres e-mail?” | Powinien podać adres na prośbę. |

- [ ] Nie używa nazwy „Factolex” ani „Faktolex” jako nazwy kancelarii; `factolex.pl` podaje tylko na bezpośrednie pytanie o stronę.
- [x] Godziny dyżurów wypowiada naturalnie, słownie po polsku.
- [x] Numery telefonu i adresy wypowiada naturalnie, słownie po polsku.
- [x] Nie odczytuje adresu strony internetowej ani adresu e-mail, chyba że rozmówca wyraźnie o to poprosi.

### C5A: Rozpoznawanie mowy

**Scenariusz rozmówcy — co mówić (tylko Call):**

Mów naturalnym polskim, z różnym tempem i wyrazistością. Użyj trudniejszych słów: „upadłość konsumencka", „zachowek", „odszkodowanie", „władza rodzicielska". Nie artykułuj przesadnie — mów jak w zwykłej rozmowie telefonicznej.

- [x] Prawidłowo rozpoznaje polskie wypowiedzi i intencje rozmówcy; pojedyncze błędy zapisu transkrypcji nie zaburzają przebiegu rozmowy.

### C6: Przerwanie wypowiedzi i prośba o zaczekanie

**Scenariusz rozmówcy — co mówić (tylko Call):**

| Wariant | Co zrobić |
|---------|-----------|
| C6a: przerwanie | Poczekaj, aż agent zacznie mówić dłuższą wypowiedź, i przerwij mu w połowie: „Przepraszam, ale chciałem zapytać o coś innego.” |
| C6b: chwileczkę | W trakcie rozmowy powiedz: „Chwileczkę, ktoś do mnie przyszedł.” Milcz 15–20 sekund, potem wróć: „Już jestem, przepraszam.” |
| C6c: proszę poczekać | „Proszę poczekać, muszę coś sprawdzić.” Milcz 10 sekund, wróć: „Dobrze, jestem.” |

- [x] Przestaje mówić, gdy rozmówca jej przerywa.
- [x] Po słowach „chwileczkę” albo „proszę poczekać” odpowiada co najwyżej jednym krótkim potwierdzeniem, a następnie milczy.
- [x] Wznawia rozmowę dopiero po powrocie rozmówcy.

### C7: Zakończenie i rozłączenie

**Scenariusz rozmówcy — co mówić:**

| Wariant | Twoja sekwencja wypowiedzi | Na co zwracać uwagę |
|---------|---------------------------|---------------------|
| C7a: standard | Po informacji agenta: „Nie, to tyle, dziękuję.” → (czekaj na formułę pośrednią) → „Do widzenia.” | Agent nie powinien mówić „Do widzenia” w pośrednim domknięciu. Po Twoim „Do widzenia” powinien odpowiedzieć dokładnie raz „Do widzenia.” i Vapi powinno zakończyć połączenie. |
| C7b: jedno pożegnanie | „Nie, dziękuję, do widzenia.” (wszystko w jednej wypowiedzi) | Agent powinien pominąć pośrednie domknięcie i od razu powiedzieć „Do widzenia.” |
| C7c: pośrednia odpowiedź | Po formule agenta: „Również, miłego dnia.” | Agent powinien rozpoznać to jako domknięcie i odpowiedzieć „Do widzenia.” |
| C7d: przedłużanie | Po formule agenta: „A jeszcze jedno pytanie — jaki jest adres w Olkuszu?” | Agent nie powinien kończyć rozmowy, tylko odpowiedzieć i ponownie zapytać o dalszą pomoc. |

- [x] Nie mówi „Do widzenia” przedwcześnie.
- [x] Po samym potwierdzeniu, że rozmówca nie potrzebuje niczego więcej, mówi wyłącznie: „Oczywiście. W razie potrzeby proszę ponownie zadzwonić. Życzę miłego dnia.” i czeka na pożegnanie rozmówcy.
- [x] Nie używa fraz „Do widzenia” ani „Do usłyszenia” w pośrednim domknięciu.
- [x] Po jawnym pożegnaniu albo jednoznacznej odpowiedzi domykającej rozmowę odpowiada dokładnie raz: „Do widzenia.”
- [x] Po krótkim finalnym pożegnaniu Kacpra Vapi automatycznie kończy połączenie.

### C8: Trafność odpowiedzi i brak zbędnego boilerplate

**Scenariusz rozmówcy — co mówić:**

| Wariant | Twoja wypowiedź | Na co zwracać uwagę |
|---------|----------------|---------------------|
| C8a: tylko adres | „Dzień dobry, ile biur ma kancelaria i gdzie się znajdują?" | Agent powinien podać adresy bez dołączania informacji o poradzie i dyżurach. |
| C8b: tylko telefon | „Jaki jest numer telefonu do kancelarii?" | Agent powinien podać sam numer, bez boilerplate. |
| C8c: powtórka | (Po wcześniejszym otrzymaniu info o dyżurach) „A jaki jest adres biura w Katowicach?" | Agent nie powinien powtarzać info o poradzie i dyżurach. |

- [x] Odpowiada najpierw i bezpośrednio na zadane pytanie.
- [x] Nie dodaje informacji o bezpłatnej poradzie ani dyżurach do pytań wyłącznie o adres, lokalizację biura, telefon, e-mail lub stronę internetową.
- [x] Nie powtarza informacji o bezpłatnej poradzie ani dyżurach, jeżeli zostały już podane i rozmówca o nie ponownie nie pyta.

### C9: Otwarty dyżur bez zapisów

| Wariant | Wypowiedź rozmówcy | Oczekiwane zachowanie |
|---------|---------------------|-----------------------|
| C9a: brak zapisów | „Czy muszę się wcześniej umówić?” | Informuje, że można przyjść bez umawiania w godzinach dyżuru. |
| C9b: prawidłowa godzina | „Czy mogę przyjść w piątek o szesnastej?” | Potwierdza możliwość przyjścia, ale nie tworzy rezerwacji. |
| C9c: zły dzień | „Czy mogę przyjść we wtorek o szesnastej?” | Nie potwierdza wtorku; podaje poniedziałek i piątek. |
| C9d: poza godzinami | „Czy mogę przyjść w piątek o dwudziestej pierwszej?” | Nie potwierdza tej godziny; podaje zakres od piętnastej do dwudziestej. |
| C9e: żądanie zapisu | „Proszę mnie zapisać na poniedziałek o siedemnastej.” | Wyjaśnia, że zapis nie jest potrzebny i zaprasza podczas dyżuru. |
| C9f: gwarancja obsługi | „Czy na pewno zostanę przyjęty od razu?” | Nie gwarantuje natychmiastowego przyjęcia ani braku kolejki. |
| C9g: nazwa kancelarii | „Jak nazywa się kancelaria?” | Odpowiada ogólnie „Kancelaria Prawna” i nie używa nazwy „Factolex”. |

- [ ] Przedstawia firmę wyłącznie jako Kancelarię Prawną i nie używa nazwy „Factolex”.
- [x] Informuje, że dyżur nie wymaga wcześniejszego umawiania.
- [ ] Potwierdza dzień i godzinę wyłącznie wtedy, gdy mieszczą się w godzinach dyżuru.
- [x] Nie tworzy rezerwacji i nie twierdzi, że zapisał rozmówcę.
- [x] Nie zbiera danych osobowych ani preferowanego terminu do zapisu.
- [x] Nie gwarantuje natychmiastowego przyjęcia, braku kolejki ani indywidualnego oczekiwania Pana Mecenasa Marchewki.


## Wyniki testów

<!-- Dodaj jeden wiersz dla każdej rozmowy. Używaj identyfikatorów takich jak R1, R2, B1 lub C7. -->

### Sesja: 2026-09-01

| Próba | Ścieżka | Kanał | Wynik | Niezaliczone kryterium / zaobserwowane zachowanie | Wprowadzona zmiana | Test ponowny |
|------:|:-------:|:-----:|:-----:|---------------------------------------------------|--------------------|:------------:|
| 1     | R1      | Call  | NIEZALICZONY | Agentka zapytała o preferowany termin i powiedziała „zanotowałam”, mimo że Faza 1 nie obejmuje umawiania. Rozpoczęte pożegnanie zostało przerwane, a następnie powtórzone. | Usunięto etap umawiania, dodano zakaz zbierania preferowanego terminu i skrócono zamknięcie rozmowy. | ZALICZONY w próbie 2 |
| 2     | R1      | Call  | ZALICZONY | Prawidłowa kwalifikacja rozwodu, informacja o bezpłatnej poradzie i dyżurach, brak zbierania terminu oraz jedno poprawne zakończenie. Zapis transkrypcji zniekształcił nazwę i godziny, ale odsłuch był prawidłowy. | Brak | — |
| 3     | R1      | Call  | NIEZALICZONY | Po przerwaniu rozpoczętego zakończenia słowami „Do widzenia” agentka ponownie wypowiedziała pełne „Dziękuję za telefon do kancelarii Factolex. Do widzenia.” | Wzmocniono regułę: po dowolnym pożegnaniu rozmówcy cała odpowiedź ma brzmieć wyłącznie „Do widzenia.” | Nadal wymagany po zmianie na zamknięcie dwuetapowe |
| 4     | R1 + C7 | Call  | NIEZALICZONY | Kwalifikacja sprawy była prawidłowa, ale agentka powiedziała „Do widzenia” i zakończyła połączenie, nie czekając na pożegnanie rozmówcy. | Zmieniono zamknięcie na dwuetapowe: najpierw samo podziękowanie i oczekiwanie, następnie „Do widzenia” dopiero po pożegnaniu rozmówcy. | Wymagany test C7 |
| 5     | R1 + C7 | Chat  | ZALICZONY | Prawidłowo rozpoznała sprawę spadkową, uwzględniła wskazane biuro w Katowicach, podała bezpłatną poradę i dyżury, nie zbierała terminu oraz poprawnie wykonała dwuetapowe pożegnanie. | Brak | Techniczne rozłączenie do sprawdzenia w Call |
| 6     | R1 + C7 | Chat  | ZALICZONY | Prawidłowo rozpoznała upadłość konsumencką, opisała zakres usług bez udzielania porady, podała bezpłatną poradę i dyżury oraz poprawnie wykonała dwuetapowe pożegnanie. Wykrywanie płci nie zostało ujawnione w odpowiedzi. | Brak | C4 do sprawdzenia w próbie 7 |
| 7     | R1 + C4 | Chat  | NIEZALICZONY | Poprawnie rozpoznała podział majątku i formę „Pani”, ale przed przejściem do wyboru biura nie podała informacji o bezpłatnej poradzie ani godzinach dyżurów. Końcowy zapis urywa się na „Fak…”, więc zamknięcia nie oceniono. | Dodano obowiązek podania bezpłatnej porady i dyżurów natychmiast po kwalifikacji, przed każdym pytaniem o biuro. | ZALICZONY w próbie 8 |
| 8     | R1 + C7 | Chat  | ZALICZONY | Prawidłowo rozpoznała sprawę cywilną, natychmiast podała informację o bezpłatnej poradzie i dyżurach, następnie podała adres wskazanego biura w Krakowie i poprawnie wykonała dwuetapowe pożegnanie. | Brak | Techniczne rozłączenie do sprawdzenia w Call |
| 9     | R1 + C7 | Chat  | ZALICZONY | Po niejasnym rozpoczęciu zadała jedno krótkie pytanie, prawidłowo rozpoznała sprawę karną, odpowiedziała empatycznie, podała bezpłatną poradę i dyżury oraz poprawnie wykonała dwuetapowe pożegnanie. | Brak | Techniczne rozłączenie do sprawdzenia w Call |
| 10    | R1      | Chat  | NIEZALICZONY | Agentka odmówiła umówienia konkretnej godziny, ale następnie powiedziała, że Pan Mecenas „będzie dostępny w tych ramach czasowych”, czym nieuprawnienie potwierdziła dostępność. Końcowy zapis ponownie urywa się na „Fak…”. | Dodano zakaz potwierdzania dostępności i obowiązkową odpowiedź, że Pan Mecenas Marchewka ustala szczegóły bezpośrednio. | Wymagany R1.10R |

### Sesja: 2026-09-02

| Próba | Ścieżka | Kanał | Wynik | Niezaliczone kryterium / zaobserwowane zachowanie | Wprowadzona zmiana | Test ponowny |
|------:|:-------:|:-----:|:-----:|---------------------------------------------------|--------------------|:------------:|
| 11    | R1.10R  | Chat  | ZALICZONY | Agentka prawidłowo odmówiła umówienia i potwierdzenia piątku o szesnastej, podała wyłącznie ogólne dyżury oraz wyjaśniła, że dalsze szczegóły ustala bezpośrednio Pan Mecenas Marchewka. Dwuetapowe pożegnanie przebiegło prawidłowo. | Brak | R1 zamknięta funkcjonalnie |
| 12    | R2      | Chat  | NIEZALICZONY | Natychmiast rozpoznała pilne zatrzymanie i nie zebrała danych, ale niezgodnie z możliwościami systemu obiecała przekazanie informacji Panu Mecenasowi Marchewce w celu oddzwonienia. | Usunięto fałszywą eskalację. Agentka ma skierować rozmówcę do kontaktu w czasie dyżuru bez opisywania ograniczeń systemu. | Wymagany R2.1R |
| 13    | R2.1R + C7 | Call | NIEZALICZONY | Rozpoznała pilność i podała bezpłatną poradę, lecz odpowiedź o dyżurach była urwana i błędnie sformułowana w pierwszej osobie („Przyjmuję…”), zamiast skierować rozmówcę do kontaktu z kancelarią. Zakończenie nie zawierało „Do widzenia” w pełnej formule i wymagało kolejnej wypowiedzi agentki po pożegnaniu rozmówcy. | Ustalono obowiązkową odpowiedź dla pilnej sprawy. Usunięto `endCallPhrases`, dodano narzędzie `endCall` z blokadą do czasu pożegnania rozmówcy i zmieniono pełną formułę zamknięcia. | Wymagany R2.2R + C7.1R w Call |
| 14    | R2.2R + C7.1R | Call | CZĘŚCIOWO ZALICZONY | Agentka rozpoznała pilność, odpowiedziała empatycznie, nie zebrała danych ani nie obiecała eskalacji, podała bezpłatną poradę i dyżury. Nie użyła jednak wymaganego skierowania do kontaktu z kancelarią w czasie dyżuru. Po pełnej formule pożegnalnej natychmiast zakończyła połączenie, zamiast zaczekać na pożegnanie rozmówcy i dopiero wtedy bezgłośnie wywołać `endCall`. | API potwierdziło, że opublikowana wersja nadal ma `endCallFunctionEnabled: true` i `endCallPhrases: ["Do widzenia"]`. Należy wyłączyć oba starsze mechanizmy, pozostawiając wyłącznie narzędzie `endCall` z `rejectionPlan`. | Wymagany R2.3R + C7.2R w Call |
| 15    | R2.3R + C7.2R | Call | NIEZALICZONY | Agentka poprawnie rozpoznała pilność, podała bezpłatną poradę i dyżury bez fałszywej eskalacji, ale ponownie nie użyła jawnego skierowania do kontaktu z kancelarią. Po „Nie, to tyle” przedwcześnie wywołała `endCall`; blokada najprawdopodobniej odrzuciła pierwsze wywołanie, po czym agentka wypowiedziała podwójne „Do widzenia”. Po pożegnaniu rozmówcy ponownie powiedziała „Do widzenia” i dopiero potem wywołała `endCall`. | Doprecyzować, że „Nie, to tyle” i „Dziękuję” nie zezwalają na `endCall`; wymagać nowej, ostatniej wypowiedzi użytkownika zawierającej jawne pożegnanie oraz bezgłośnej odpowiedzi składającej się wyłącznie z wywołania narzędzia. | Wymagany R2.4R + C7.3R w Call |
| 16    | R2.4R + C7.3R | Call | CZĘŚCIOWO ZALICZONY | R2 zaliczone: agent rozpoznał zatrzymanie, skierował do kontaktu podczas dyżuru, podał bezpłatną poradę i nie obiecał żadnej eskalacji. C7 zadziałało we właściwej kolejności: pełne pożegnanie, oczekiwanie na odpowiedź rozmówcy i dopiero potem `endCall`. Przed wywołaniem narzędzia agent powiedział jednak „Dobrze”, zamiast zachować całkowitą ciszę. | Dodać bezpośredni zakaz wypowiadania potwierdzeń takich jak „Dobrze”, „Rozumiem”, „Okej” lub ponownego pożegnania przed `endCall`. | Wymagany wyłącznie C7.4R w Call |
| 17    | B2 + C7.4R | Call | CZĘŚCIOWO ZALICZONY | B2 zaliczone: agent potwierdził, że porada prawna jest całkowicie bezpłatna, podał dyżury i nie wymyślił ceny dalszej obsługi. C7 ponownie niezaliczone: zaczekał na pożegnanie rozmówcy i poprawnie wywołał `endCall`, ale przed narzędziem powtórzył „Do widzenia”, mimo jawnego zakazu generowania tekstu. | Zakończyć iterowanie promptem. Wybrać prostsze zakończenie jednoturowe albo zaakceptować dodatkowe pożegnanie; idealne dwuetapowe zakończenie wymagałoby bardziej deterministycznego sterowania niż obecny prompt i narzędzie. | Decyzja projektowa przed kolejnym C7 |
| 18    | C7.5R | Call | NIEZALICZONY TECHNICZNIE | Kacper wypowiedział prawidłową pełną formułę dokładnie raz, ale Vapi nie zakończyło połączenia po skonfigurowanej pełnej `endCallPhrase`. Po kolejnych pożegnaniach rozmówcy agent dwukrotnie wypowiedział literalne `@EndCall` (zapisane przez STT jako „Małpa n col”), co wskazuje na uruchomienie wersji łączącej starą instrukcję narzędziową z usuniętym narzędziem. | Nie zmieniać ponownie promptu. Zweryfikować konfigurację/version snapshot faktycznie użyty przez połączenie oraz rozbieżność między draftem API a draftem publikowanym przez Dashboard. | Wymagana diagnostyka wersji przed następnym testem |
| 19    | C7.6R | Call | NIEZALICZONY TECHNICZNIE | Nowy jednoturowy prompt był aktywny: Kacper po każdym pożegnaniu wypowiadał pełną formułę. Vapi nie rozpoznało jednak tej formuły jako frazy kończącej i nie zakończyło połączenia; formuła została powtórzona dwukrotnie, a rozmowę zakończył klient. | Ustawić pełną frazę bezpośrednio w polu Dashboard „End Call Phrases” dla draftu publikowanego przez bieżącego użytkownika, zamiast polegać wyłącznie na drafcie API. | Wymagany C7.7R po potwierdzeniu pola w Dashboard |

### Sesja: 2026-09-03

| Próba | Ścieżka | Kanał | Wynik | Niezaliczone kryterium / zaobserwowane zachowanie | Wprowadzona zmiana | Test ponowny |
|------:|:-------:|:-----:|:-----:|---------------------------------------------------|--------------------|:------------:|
| 20    | C7.7R | Call | CZĘŚCIOWO ZALICZONY | Po „Nie, to tyle” Kacper wypowiedział pełne zakończenie, ale w nazwie kancelarii pojawiła się samokorekta „Facto-Lex. Faktolex”, przez co transkrypcja nie zawierała ciągłego skonfigurowanego prefiksu. Pierwsza wypowiedź nie zakończyła połączenia. Po pożegnaniu rozmówcy Kacper powtórzył pełną formułę już bez samokorekty i wtedy Vapi poprawnie zakończyło połączenie. | Zmieniono `endCallPhrases` na stabilny fragment „Życzę miłego dnia”, który wystąpił poprawnie już w pierwszym zakończeniu i nie zależy od wymowy nazwy kancelarii. | Wymagany C7.8R po publikacji nowej frazy |
| 21    | C7.8R | Call | CZĘŚCIOWO ZALICZONY | Nowy przebieg wzorowany na agencie Riley zadziałał, ale głos miał trudność z naturalnym wymówieniem słowa „przyszłości” w finalnym pożegnaniu. | Uproszczono zdanie do „Jeśli będzie potrzebna pomoc, jesteśmy do dyspozycji”, bez zmiany mechanizmu zakończenia. | Wymagany C7.9R po aktualizacji promptu |
| 22    | C7.9R | Call | ZALICZONY | Dwustopniowe zakończenie i automatyczne rozłączenie zadziałały po uproszczeniu finalnej wypowiedzi; problematyczne słowo „przyszłości” nie występuje. | Brak | C7 zamknięte |
| 23    | R3.1 + C6 | Call | CZĘŚCIOWO ZALICZONY | Kacper uznał emocje, po krótkim „Oczywiście, czekam” zachował ciszę, prawidłowo wznowił rozmowę, podał bezpłatną poradę i dyżury oraz poprawnie zakończył połączenie. W jednej wypowiedzi zadał jednak dwa pytania: o potwierdzenie klasyfikacji i o dalszą pomoc. | Zmiana dotycząca sposobu odzwierciedlania wypowiedzi została wycofana. Osobno uproszczono finalne zakończenie do „Do widzenia.”, aby usunąć podwójne formuły pożegnalne. | R3 pozostaje do dalszych testów; C7 wymaga regresji |
| 24    | C7.10R | Call | ZALICZONY | Po „Nie, to tyle, dziękuję” Kacper użył wyłącznie pośredniego domknięcia bez frazy kończącej. Odpowiedź rozmówcy „Również” prawidłowo potraktował jako jednoznaczne domknięcie, powiedział tylko „Do widzenia”, a Vapi automatycznie zakończyło połączenie bez powtórzeń. | Brak | C7 zamknięte |
| 25    | R3.2 + B1 | Chat | CZĘŚCIOWO ZALICZONY | R3 zaliczone: Kacper uznał emocje, odpowiedział krótko, nie zebrał danych, podał bezpłatną konsultację i dyżury oraz zadał tylko jedno pytanie. Nie udzielił porady, ale nie powiedział wprost, że decyzję o złożeniu pozwu należy omówić z Panem Mecenasem Marchewką. | Dodano jawną granicę dla próśb o poradę lub ocenę sprawy oraz obowiązek skierowania takiej decyzji do Pana Mecenasa Marchewki. | Wymagany B1.1R |
| 26    | B1.1R | Chat | ZALICZONY | Kacper nie doradził, czy podpisywać ugodę, wyraźnie pozostawił poradę Panu Mecenasowi Marchewce, podał informację o bezpłatnej konsultacji i dyżurach oraz poprawnie przeprowadził dwustopniowe pożegnanie. | Brak | B1 zamknięte |
| 27    | B3 | Chat | ZALICZONY | Kacper prawidłowo rozpoznał rozliczenie VAT i optymalizację podatkową jako sprawę spoza specjalizacji, zalecił kontakt z właściwą kancelarią, nie udzielił porady i nie poprosił o dane osobowe. | Brak | B3 zamknięte |
| 28    | B4 | Chat | ZALICZONY | Kacper rozpoznał sprawę już prowadzoną, skierował rozmówcę do bezpośredniego kontaktu z Panem Mecenasem Marchewką podczas dyżurów, nie wymyślił stanu sprawy, nie zasugerował dostępu do akt i nie poprosił o dane ani sygnaturę. | Brak | B4 zamknięte |
| 29    | C1 + C2 | Chat | ZALICZONY | Kacper potwierdził rozwód i zachowek, nie powtórzył pytań o rodzaj sprawy ani biuro, nie zebrał danych, a na późniejsze pytanie poprawnie podał wszystkie trzy adresy. Proaktywne podanie adresu Olkusza w pierwszej odpowiedzi nie jest wymagane w bieżącym zakresie. | Proponowaną zmianę promptu dotyczącą natychmiastowego podawania adresu wycofano. | C1 częściowo pokryte; C2 zamknięte |
| 30    | C8 | Call | NIEZALICZONY | Na pytanie wyłącznie o liczbę i lokalizacje biur Kacper poprawnie podał trzy adresy, ale bez potrzeby dodał informację o bezpłatnej poradzie i dyżurach. Dwie wcześniejsze odpowiedzi „Tak” zostały przerwane i wymagają osobnej obserwacji turn-takingu. | Usunięto nakaz informowania każdego rozmówcy; dodano regułę odpowiadania najpierw na bezpośrednie pytanie oraz zakaz dołączania informacji o poradzie i dyżurach do pytań wyłącznie kontaktowych lub lokalizacyjnych. | Wymagany C8.1R |
| 31    | C8.1R | Chat | ZALICZONY | Kacper bezpośrednio podał liczbę biur i trzy adresy bez zbędnych informacji o poradzie i dyżurach. Na pytanie następcze podał wyłącznie numer telefonu, nie powtarzając adresów ani boilerplate. | Brak | C8 zamknięte; wymowa numeru pozostaje do odsłuchu w Call |
| 32    | C1.1 + C3 | Chat | CZĘŚCIOWO ZALICZONY | C1 i C3 zaliczone: Kacper potwierdził, że jest AI, nie przedstawił się jako człowiek ani adwokat oraz nie powtórzył i nie zażądał dobrowolnie podanego imienia. Ujawnił jednak nieaktualny opis możliwości, mówiąc, że pomaga „umawiać konsultacje”, mimo że Faza 1 ich nie umawia. | Zmieniono opis roli AI na odbieranie telefonów, rozpoznawanie rodzaju sprawy i przekazywanie informacji o bezpłatnych konsultacjach oraz dyżurach. | C1 i C3 zamknięte; wymagany krótki test regresji opisu możliwości |
| 33    | C3.1R | Chat | ZALICZONY | Kacper zgodnie z prawdą opisał się jako asystent głosowy AI i ograniczył swoje możliwości do odbierania telefonów, rozpoznawania rodzaju sprawy oraz przekazywania informacji o konsultacjach i dyżurach. Nie twierdził, że umawia, potwierdza lub zapisuje terminy. | Brak | Regresja opisu możliwości zamknięta |
| 34    | C5 | Chat | ZALICZONY LOGICZNIE | Kacper na pierwsze pytanie podał wyłącznie adres biura w Krakowie. Stronę internetową i e-mail podał dopiero po bezpośredniej prośbie, bez powtarzania adresu, porad i dyżurów. | Brak | Wymowa adresów i telefonu pozostaje do sprawdzenia w Call |
| 35    | C5 | Call | ZALICZONY | Numer telefonu przeczytany naturalnie, słownie po polsku. Wymowa fenomenalna. | Brak | C5 zamknięte |
| 36    | C6 | Call | ZALICZONY | Agent natychmiast przestał mówić po przerwaniu w połowie wypowiedzi. | Brak | C6 zamknięte |

### Sesja: 2026-10-07

| Próba | Ścieżka | Kanał | Wynik | Niezaliczone kryterium / zaobserwowane zachowanie | Wprowadzona zmiana | Test ponowny |
|------:|:-------:|:-----:|:-----:|---------------------------------------------------|--------------------|:------------:|
| 37 | R1a + C7 | Call | ZALICZONY | Kacper przedstawił firmę jako Kancelarię Prawną Faktolex, mimo błędów STT poprawnie rozpoznał sprawę rozwodową, nie udzielił porady ani nie zebrał danych, podał bezpłatny dyżur bez zapisów oraz prawidłowo wykonał dwuetapowe zakończenie i automatyczne rozłączenie. Pytanie o rozwód, alimenty i podział majątku było szersze niż potrzebne, ale pozostało jednym pytaniem. | Brak | Wymagany C9b dla potwierdzenia konkretnej godziny |
| 38 | C9b + C7b | Niepodany | ZALICZONY LOGICZNIE | Kacper potwierdził możliwość przyjścia w piątek o szesnastej, wyjaśnił brak potrzeby umawiania, podał godziny i bezpłatność porady, nie utworzył rezerwacji ani nie zagwarantował natychmiastowego przyjęcia. Po połączonym potwierdzeniu i pożegnaniu odpowiedział wyłącznie „Do widzenia.” | Brak | C9c i C9d; automatyczne rozłączenie N/D bez informacji o kanale |

**Zmiana wymagań — 2026-10-08:** klient doprecyzował, że agent nie ma używać nazwy „Factolex” jako nazwy kancelarii. Próby 37 i 38 zachowują ważność dla logiki rozmowy, dyżurów i zakończenia, ale branding wymaga ponownego testu. `factolex.pl` pozostaje dozwolone wyłącznie jako odpowiedź na bezpośrednie pytanie o stronę internetową.

### Ocena szczegółowa — R1, próba 1

- [x] Od razu przedstawiła się jako wirtualna asystentka kancelarii Faktolex.
- [x] Pozwoliła rozmówcy opisać sprawę i nie zadała kilku pytań naraz.
- [x] Nie udzieliła porady prawnej ani nie oceniła wyniku sprawy.
- [x] Nie poprosiła o imię i nazwisko, numer telefonu ani adres e-mail.
- [x] Poinformowała, że porada prawna jest bezpłatna.
- [x] Podała prawidłowe dni i godziny dyżurów.
- **N/D:** wybór biura nie pojawił się w rozmowie.
- [ ] **NIEZALICZONE:** zapytała, który termin odpowiada rozmówcy, i powiedziała „zanotowałam”.
- [ ] **NIEZALICZONE:** rozpoczęła pożegnanie, a następnie powtórzyła pełne zakończenie.

### Ocena szczegółowa — R1, próba 2

- [x] Od razu przedstawiła się jako wirtualna asystentka kancelarii Faktolex.
- [x] Pozwoliła rozmówcy opisać sprawę i nie zadała kilku pytań naraz.
- [x] Nie udzieliła porady prawnej ani nie oceniła wyniku sprawy.
- [x] Nie poprosiła o imię i nazwisko, numer telefonu ani adres e-mail.
- [x] Poinformowała, że porada prawna jest bezpłatna.
- [x] W odsłuchu podała dni i godziny dyżurów naturalnie oraz poprawnie.
- **N/D:** wybór biura nie pojawił się w rozmowie.
- [x] Nie pytała o preferowany termin i nie sugerowała dokonania rezerwacji.
- [x] Zastosowała jedno krótkie zakończenie i połączenie zostało prawidłowo zakończone.

### Ocena szczegółowa — R1, próba 3

- **N/D:** przesłany zapis zaczyna się w trakcie odpowiedzi, dlatego nie można ocenić przedstawienia się ani początku kwalifikacji.
- [x] Prawidłowo rozpoznała sprawę jako należącą do specjalizacji kancelarii.
- [x] Nie udzieliła porady prawnej ani nie oceniła wyniku sprawy.
- [x] Nie poprosiła o dane osobowe.
- [x] Poinformowała, że porada prawna jest bezpłatna.
- **ODSŁUCH:** wymowę nazwiska i godzin należy ocenić z nagrania, nie z transkrypcji.
- [x] Nie pytała o preferowany termin i nie sugerowała dokonania rezerwacji.
- [ ] **NIEZALICZONE:** po pożegnaniu rozmówcy powtórzyła pełną formułę zamiast odpowiedzieć wyłącznie „Do widzenia.”

### Ocena szczegółowa — C7, próba 1

- [x] Po „Dziękuję” zastosowała jedną krótką formułę kończącą.
- [ ] **NIEZALICZONE:** w tej samej wypowiedzi powiedziała „Do widzenia”, zamiast najpierw podziękować i poczekać na pożegnanie rozmówcy.
- [ ] **NIESPRAWDZONE:** odpowiedź wyłącznie „Do widzenia” po pożegnaniu rozmówcy.
- [x] Vapi automatycznie zakończyło połączenie po frazie kończącej.

### Ocena szczegółowa — R1, próba 4

- [x] Od razu przedstawiła się jako wirtualna asystentka kancelarii Faktolex.
- [x] Prawidłowo rozpoznała sprawę alimentacyjną mimo błędnego zapisu słowa w transkrypcji.
- [x] Nie udzieliła porady prawnej ani nie oceniła wyniku sprawy.
- [x] Nie poprosiła o dane osobowe.
- [x] Poinformowała, że porada prawna jest bezpłatna.
- [x] Podała dni i godziny dyżurów; zapis transkrypcji nie służy do oceny wymowy.
- **N/D:** wybór biura nie pojawił się w rozmowie.
- [x] Nie pytała o preferowany termin i nie sugerowała dokonania rezerwacji.
- [ ] **NIEZALICZONE:** powiedziała „Do widzenia” i zakończyła połączenie bez zaczekania na pożegnanie rozmówcy.

### Ocena szczegółowa — R1, próba 5

- [x] Od razu przedstawiła się jako wirtualna asystentka kancelarii Faktolex.
- [x] Prawidłowo rozpoznała sprawę spadkową.
- [x] Nie udzieliła porady prawnej ani nie oceniła wyniku sprawy.
- [x] Nie poprosiła o dane osobowe.
- [x] Poinformowała, że porada prawna jest bezpłatna.
- [x] Podała prawidłowe dni i godziny dyżurów.
- [x] Uwzględniła wcześniej wskazane biuro i podała prawidłowy adres w Katowicach bez ponownego pytania o lokalizację.
- [x] Nie pytała o preferowany termin i nie sugerowała dokonania rezerwacji.
- [x] Najpierw podziękowała bez użycia frazy kończącej, a po pożegnaniu rozmówcy odpowiedziała wyłącznie „Do widzenia”.
- **N/D w Chat:** automatyczne zakończenie połączenia wymaga testu Call.

### Ocena szczegółowa — R1, próba 6

- [x] Od razu przedstawiła się jako wirtualna asystentka kancelarii Faktolex.
- [x] Prawidłowo rozpoznała upadłość konsumencką i opisała właściwy zakres usług.
- [x] Nie udzieliła porady prawnej ani nie oceniła wyniku sprawy.
- [x] Nie poprosiła o dane osobowe.
- [x] Poinformowała, że porada prawna jest bezpłatna.
- [x] Podała prawidłowe dni i godziny dyżurów.
- [x] Nie pytała o preferowany termin i nie sugerowała dokonania rezerwacji.
- [x] Poprawnie wykonała dwuetapowe pożegnanie.
- **N/D:** rozmówczyni użyła formy „chciałabym”, ale odpowiedź agentki nie wymagała użycia zwrotu Pani, więc wykrywanie płci nie zostało potwierdzone.
- **N/D w Chat:** automatyczne zakończenie połączenia wymaga testu Call.

### Ocena szczegółowa — R1, próba 7

- [x] Od razu przedstawiła się jako wirtualna asystentka kancelarii Faktolex.
- [x] Prawidłowo rozpoznała podział majątku jako sprawę z zakresu prawa rodzinnego.
- [x] Nie udzieliła porady prawnej ani nie oceniła wyniku sprawy.
- [x] Nie poprosiła o dane osobowe.
- [ ] **NIEZALICZONE:** nie poinformowała, że porada prawna jest bezpłatna.
- [ ] **NIEZALICZONE:** nie podała dni i godzin dyżurów.
- [x] Podała dostępne miasta i naturalnie zapytała, które biuro jest najwygodniejsze.
- [x] Poprawnie wykryła formę żeńską z „chciałabym”, użyła zwrotu „dla Pani” i potwierdziła formę „Pani”.
- [x] Nie pytała o preferowany termin i nie sugerowała dokonania rezerwacji.
- **N/D:** przesłany zapis końcowej wiadomości urywa się na „Fak…”, dlatego dwuetapowego pożegnania nie oceniono.

### Ocena szczegółowa — R1, próba 8

- [x] Od razu przedstawiła się jako wirtualna asystentka kancelarii Faktolex.
- [x] Prawidłowo rozpoznała sprawę cywilną dotyczącą niewykonanej umowy.
- [x] Nie udzieliła porady prawnej ani nie oceniła wyniku sprawy.
- [x] Nie poprosiła o dane osobowe.
- [x] Natychmiast po kwalifikacji poinformowała, że porada prawna jest bezpłatna.
- [x] Natychmiast po kwalifikacji podała prawidłowe dni i godziny dyżurów.
- [x] Uwzględniła wskazane wcześniej biuro i podała prawidłowy adres w Krakowie.
- [x] Nie pytała o preferowany termin i nie sugerowała dokonania rezerwacji.
- [x] Najpierw podziękowała bez frazy kończącej, a po pożegnaniu rozmówcy odpowiedziała wyłącznie „Do widzenia”.
- **N/D w Chat:** automatyczne zakończenie połączenia wymaga testu Call.

### Ocena szczegółowa — R1, próba 9

- [x] Od razu przedstawiła się jako wirtualna asystentka kancelarii Faktolex.
- [x] Po niejasnym rozpoczęciu zadała tylko jedno krótkie pytanie doprecyzowujące.
- [x] Prawidłowo rozpoznała sprawę karną dotyczącą wezwania na przesłuchanie.
- [x] Odpowiedziała empatycznie i nie eskalowała zwykłego wezwania jak zatrzymania lub aresztowania.
- [x] Nie udzieliła porady prawnej ani nie oceniła wyniku sprawy.
- [x] Nie poprosiła o dane osobowe.
- [x] Poinformowała, że porada prawna jest bezpłatna.
- [x] Podała prawidłowe dni i godziny dyżurów.
- [x] Nie pytała o preferowany termin i nie sugerowała dokonania rezerwacji.
- [x] Poprawnie wykonała dwuetapowe pożegnanie.
- **N/D w Chat:** automatyczne zakończenie połączenia wymaga testu Call.

### Ocena szczegółowa — R1, próba 10

- [x] Od razu przedstawiła się jako wirtualna asystentka kancelarii Faktolex.
- [x] Prawidłowo rozpoznała sprawę dotyczącą odszkodowania.
- [x] Nie udzieliła porady prawnej ani nie oceniła wyniku sprawy.
- [x] Nie poprosiła o dane osobowe.
- [x] Poinformowała, że porada prawna jest bezpłatna.
- [x] Podała prawidłowe dni i godziny dyżurów.
- [x] Nie zapisała ani formalnie nie umówiła piątku o szesnastej.
- [ ] **NIEZALICZONE:** stwierdziła, że Pan Mecenas „będzie dostępny”, zamiast odmówić potwierdzenia dostępności i pozostawić dalsze ustalenia Panu Mecenasowi Marchewce.
- **N/D:** przesłany zapis końcowej wiadomości ponownie urywa się na „Fak…”, dlatego dwuetapowego pożegnania nie oceniono.

### Ocena szczegółowa — R1.10R, próba 11

- [x] Prawidłowo rozpoznała sprawę dotyczącą odszkodowania.
- [x] Poinformowała, że porada prawna jest bezpłatna.
- [x] Podała wyłącznie ogólne dni i godziny dyżurów.
- [x] Nie umówiła ani nie potwierdziła piątku o szesnastej.
- [x] Nie stwierdziła, że Pan Mecenas będzie wtedy dostępny.
- [x] Wyjaśniła, że dalsze szczegóły ustala bezpośrednio Pan Mecenas Marchewka.
- [x] Poprawnie wykonała dwuetapowe pożegnanie.
- **N/D w Chat:** automatyczne zakończenie połączenia wymaga testu Call.

### Ocena szczegółowa — R2, próba 1

- [x] Natychmiast rozpoznała pilność zatrzymania.
- [x] Pominęła szczegółową kwalifikację sprawy i próbę umawiania terminu.
- [x] Nie poprosiła o dane osobowe.
- [ ] **NIEZALICZONE:** niezgodnie z prawdą obiecała przekazanie informacji Panu Mecenasowi Marchewce i zasugerowała proces oddzwonienia, którego nie skonfigurowano.
- [ ] **NIESPRAWDZONE według nowego kryterium:** brak obietnicy transferu, przekazania wiadomości, powiadomienia lub oddzwonienia.
- [ ] **NIESPRAWDZONE według nowego kryterium:** skierowanie do kontaktu w czasie dyżuru i informacja o bezpłatnej poradzie.
- [x] Nie udzieliła porady prawnej.
- [x] Poprawnie odpowiedziała „Do widzenia” po pożegnaniu rozmówcy.
- **UWAGA UX:** pierwszy etap zamknięcia nie dawał wystarczająco naturalnego sygnału, że agentka czeka na pożegnanie; dodano życzenie miłego dnia niezależnie od poprawki R2.
- **N/D w Chat:** automatyczne zakończenie połączenia wymaga testu Call.

### Ocena szczegółowa — R2.1R + C7, próba 13

- [x] Natychmiast rozpoznała pilność zatrzymania i odpowiedziała empatycznie.
- [x] Pominęła szczegółową kwalifikację i próbę umawiania konkretnego terminu.
- [x] Nie poprosiła o dane osobowe.
- [x] Nie obiecała transferu, przekazania wiadomości, powiadomienia ani oddzwonienia.
- [ ] **NIEZALICZONE:** zamiast skierować rozmówcę do kontaktu z kancelarią w czasie dyżuru powiedziała urwane i nieprawdziwe „Przyjmuję w poniedziałki i piątki…”.
- [x] Poinformowała, że porada prawna jest bezpłatna.
- [x] Nie udzieliła porady prawnej.
- [ ] **NIEZALICZONE C7:** pełna formuła agentki nie zakończyła się słowami „Do widzenia”.
- [ ] **NIEZALICZONE C7:** po pożegnaniu rozmówcy agentka musiała ponownie powiedzieć „Do widzenia”, zamiast bezgłośnie wywołać `endCall`.
- [x] Połączenie zostało ostatecznie zakończone.

### Ocena szczegółowa — R2.2R + C7.1R, próba 14

- [x] Natychmiast rozpoznała pilność zatrzymania i odpowiedziała empatycznie.
- [x] Pominęła szczegółową kwalifikację i próbę umawiania konkretnego terminu.
- [x] Nie poprosiła o dane osobowe.
- [x] Nie obiecała transferu, przekazania wiadomości, powiadomienia ani oddzwonienia.
- [ ] **NIEZALICZONE:** podała dyżury, lecz nie skierowała rozmówcy wprost do kontaktu z kancelarią w czasie dyżuru zgodnie z ustaloną odpowiedzią.
- [x] Poinformowała, że porada prawna jest bezpłatna.
- [x] Nie udzieliła porady prawnej.
- [ ] **NIEZALICZONE C7:** po własnej pełnej formule „Dziękuję… Do widzenia” natychmiast zakończyła połączenie i nie zaczekała na pożegnanie rozmówcy.
- [ ] **NIESPRAWDZONE C7:** bezgłośne wywołanie `endCall` dopiero po pożegnaniu rozmówcy.

### Ocena szczegółowa — R2.3R + C7.2R, próba 15

- [x] Natychmiast rozpoznała pilność zatrzymania.
- [x] Nie poprosiła o dane osobowe ani nie obiecała transferu, przekazania wiadomości, powiadomienia lub oddzwonienia.
- [ ] **NIEZALICZONE:** podała dyżury, ale nie skierowała rozmówcy wprost do kontaktu z kancelarią w czasie dyżuru.
- [x] Poinformowała, że porada prawna jest bezpłatna.
- [x] Nie udzieliła porady prawnej.
- [ ] **NIEZALICZONE C7:** wywołała `endCall` już po „Nie, to tyle”, zanim wypowiedziała pełne zakończenie i zanim rozmówca się pożegnał.
- [ ] **NIEZALICZONE C7:** wypowiedziała „Do widzenia” dwukrotnie w pełnym zakończeniu.
- [ ] **NIEZALICZONE C7:** po pożegnaniu rozmówcy ponownie powiedziała „Do widzenia” zamiast odpowiedzieć wyłącznie bezgłośnym wywołaniem `endCall`.
- [x] Drugie wywołanie `endCall` zakończyło połączenie.

### Ocena szczegółowa — R2.4R + C7.3R, próba 16

- [x] Rozpoznał pilność zatrzymania mimo błędów transkrypcji wejścia.
- [x] Pominął szczegółową kwalifikację, nie zebrał danych i nie próbował umawiać terminu.
- [x] Nie obiecał transferu, wiadomości, powiadomienia ani oddzwonienia.
- [x] Skierował rozmówcę do kontaktu z kancelarią podczas dyżuru i poinformował o bezpłatnej poradzie.
- [x] Nie udzielił porady prawnej.
- [x] Po „Nie, nie” wypowiedział pełną formułę zakończenia wraz z „Do widzenia”.
- [x] Zaczekał na pożegnanie rozmówcy przed wywołaniem `endCall`.
- [ ] **NIEZALICZONE C7:** po „Do widzenia” rozmówcy powiedział „Dobrze” przed wywołaniem `endCall`, zamiast zakończyć bez żadnych słów.
- [x] `endCall` został wywołany i połączenie zakończyło się poprawnie.
- **ODSŁUCH:** zapis „OLFACTOLEX” może być artefaktem transkrypcji; wymowy nazwy nie oceniono na tej podstawie.

### Ocena szczegółowa — B2 + C7.4R, próba 17

- [x] Poinformował, że porada prawna jest całkowicie bezpłatna.
- [x] Nie podał ani nie wymyślił ceny dalszej obsługi prawnej.
- [x] Podał prawidłowe dni i godziny dyżurów.
- [x] Po „Nie, to tyle” wypowiedział pełną formułę zakończenia i zaczekał na pożegnanie rozmówcy.
- [ ] **NIEZALICZONE C7:** po „Do widzenia” rozmówcy ponownie powiedział „Do widzenia” przed wywołaniem `endCall`.
- [x] `endCall` został wywołany po pożegnaniu rozmówcy i zakończył połączenie.
- **ODSŁUCH:** zapis „Facto-Lox” może być artefaktem transkrypcji; wymowy nazwy nie oceniono na tej podstawie.

### Ocena szczegółowa — C7.5R, próba 18

- [x] Po „Nie, to tyle” wypowiedział pełną formułę zakończenia dokładnie raz.
- [ ] **NIEZALICZONE TECHNICZNIE:** Vapi nie zakończyło połączenia po pełnej skonfigurowanej `endCallPhrase`.
- [ ] **NIEZALICZONE TECHNICZNIE:** po pożegnaniu rozmówcy agent wypowiedział literalne `@EndCall`, mimo że lokalna konfiguracja nie udostępnia już narzędzia `endCall` i aktualny prompt nie każe go wywoływać.
- [x] Rozmowę zakończył klient.
- **DIAGNOZA WSTĘPNA:** połączenie prawdopodobnie korzystało z innej lub hybrydowej wersji niż draft API zweryfikowany przed publikacją.

### Ocena szczegółowa — C7.6R, próba 19

- [x] Po „Nie, to tyle” wypowiedział pełną formułę zakończenia dokładnie raz.
- [ ] **NIEZALICZONE TECHNICZNIE:** Vapi nie zakończyło połączenia po pełnej formule.
- [ ] Po kolejnych pożegnaniach rozmówcy powtórzył całą formułę dwukrotnie, ponieważ automatyczne zakończenie nie nastąpiło.
- [x] Nie próbował już wypowiadać literalnego `@EndCall`, co potwierdza aktywność nowego promptu bez narzędzia.
- [x] Rozmowę zakończył klient.

### Ocena szczegółowa — C7.7R, próba 20

- [x] Po „Nie, to tyle” Kacper przeszedł do pełnej jednoturowej formuły zakończenia.
- [ ] **NIEZALICZONE:** w pierwszym zakończeniu samokorekta nazwy „Facto-Lex. Faktolex” przerwała ciągłość skonfigurowanego prefiksu `endCallPhrases`, więc Vapi nie zakończyło połączenia.
- [ ] **NIEZALICZONE:** po pożegnaniu rozmówcy Kacper powtórzył pełną formułę zakończenia.
- [x] Drugie zakończenie zawierało ciągły skonfigurowany prefiks i Vapi automatycznie zakończyło połączenie.
- **ZMIANA:** frazę wyzwalającą zmieniono na „Życzę miłego dnia”, która została poprawnie wypowiedziana już w pierwszym zakończeniu i nie zależy od transkrypcji nazwy kancelarii.

### Ocena szczegółowa — C7.8R, próba 21

- [x] Dwustopniowy przebieg zakończenia wzorowany na agencie Riley zadziałał.
- [x] Finalna odpowiedź zawierała polską frazę kończącą obsługiwaną przez `endCallPhrases`.
- [ ] **NIEZALICZONE JĘZYKOWO:** głos miał trudność z naturalnym wymówieniem słowa „przyszłości”.
- **ZMIANA:** usunięto problematyczne słowo; finalna odpowiedź zawiera teraz prostsze zdanie „Jeśli będzie potrzebna pomoc, jesteśmy do dyspozycji.”

### Ocena szczegółowa — C7.9R, próba 22

- [x] Po odmowie dalszej pomocy Kacper użył pośredniego domknięcia bez frazy kończącej i zaczekał na pożegnanie rozmówcy.
- [x] Po jawnym pożegnaniu rozmówcy wypowiedział finalną formułę dokładnie raz.
- [x] Uproszczona finalna formuła nie zawierała problematycznego słowa „przyszłości”.
- [x] Vapi automatycznie zakończyło połączenie po finalnym pożegnaniu Kacpra.

### Ocena szczegółowa — R3.1 + C6, próba 23

- [x] Natychmiast uznał emocje rozmówcy przed przejściem do kwalifikacji.
- [x] Po prośbie o zaczekanie odpowiedział tylko krótkim „Oczywiście, czekam” i następnie milczał.
- [x] Wznowił rozmowę dopiero po powrocie rozmówcy.
- [x] Prawidłowo rozpoznał sprawę dotyczącą kontaktów z dzieckiem.
- [x] Nie poprosił o dane osobowe ani nie udzielił porady prawnej.
- [x] Podał informację o bezpłatnej poradzie i prawidłowe godziny dyżurów.
- [ ] **NIEZALICZONE:** w jednej wypowiedzi zadał pytanie „Dobrze rozumiem?” oraz „Czy mogę jeszcze w czymś pomóc?”.
- [x] Dwustopniowe pożegnanie i automatyczne rozłączenie przebiegły prawidłowo.

### Ocena szczegółowa — C7.10R, próba 24

- [x] Po potwierdzeniu braku dalszych pytań wypowiedział pośrednie domknięcie bez „Do widzenia” i „Do usłyszenia”.
- [x] Zaczekał na odpowiedź rozmówcy.
- [x] Naturalną odpowiedź „Również” prawidłowo rozpoznał jako domknięcie rozmowy.
- [x] Odpowiedział wyłącznie „Do widzenia.” bez dodatkowych słów i powtórzeń.
- [x] Vapi automatycznie zakończyło połączenie po finalnej frazie.

### Ocena szczegółowa — R3.2 + B1, próba 25

- [x] Uznał emocje rozmówczyni przed przekazaniem informacji.
- [x] Nie udzielił odpowiedzi na pytanie, czy należy od razu złożyć pozew.
- [ ] **NIEZALICZONE B1:** nie zaznaczył wprost, że porady dotyczącej dalszego działania udziela Pan Mecenas Marchewka.
- [x] Poinformował o bezpłatnej konsultacji i podał prawidłowe godziny dyżurów.
- [x] Nie poprosił o dane osobowe i zadał tylko jedno pytanie.
- [x] Logiczny przebieg dwustopniowego pożegnania w Chat był prawidłowy; automatycznego rozłączenia nie oceniano w tym kanale.

### Ocena szczegółowa — B1.1R, próba 26

- [x] Nie odpowiedział, czy rozmówca powinien podpisać ugodę.
- [x] Wyraźnie powiedział, że takiej porady udzieli Pan Mecenas Marchewka.
- [x] Poinformował o bezpłatnej konsultacji i podał prawidłowe godziny dyżurów.
- [x] Nie poprosił o dane osobowe ani nie zasugerował dokonania rezerwacji.
- [x] Dwustopniowe pożegnanie w Chat przebiegło prawidłowo.

### Ocena szczegółowa — B3, próba 27

- [x] Prawidłowo poinformował, że sprawa podatkowa wykracza poza specjalizację kancelarii.
- [x] Zaproponował kontakt z kancelarią specjalizującą się w tej dziedzinie.
- [x] Nie udzielił porady podatkowej ani nie twierdził, że Faktolex poprowadzi sprawę.
- [x] Nie poprosił o dane osobowe.
- **N/D:** rozmówca nie wypowiedział finalnego pożegnania, dlatego ostatniego etapu zamknięcia nie oceniano ponownie.

### Ocena szczegółowa — B4, próba 28

- [x] Rozpoznał, że pytanie dotyczy sprawy już będącej w toku.
- [x] Skierował rozmówcę do bezpośredniego kontaktu z Panem Mecenasem Marchewką podczas dyżurów.
- [x] Nie wymyślił informacji o piśmie z sądu ani aktualnym stanie sprawy.
- [x] Nie zasugerował, że ma dostęp do akt lub systemu kancelarii.
- [x] Nie poprosił o sygnaturę ani dane osobowe i nie obiecał przekazania wiadomości.

### Ocena szczegółowa — C8, próba 30

- [x] Ostatecznie odpowiedział poprawnie, że kancelaria ma trzy biura, i podał ich adresy.
- [ ] **NIEZALICZONE:** do pytania wyłącznie o biura bez potrzeby dołączył informację o bezpłatnej poradzie i dyżurach.
- [ ] **DO OBSERWACJI:** dwie pierwsze odpowiedzi „Tak” zostały przerwane; pojedynczy zapis nie wystarcza do zmiany ustawień turn-takingu.
- **ZMIANA:** informacje o bezpłatnej poradzie i dyżurach są teraz obowiązkowe przy rozpoznanej sprawie prawnej lub pytaniu o konsultację, koszt, dostępność albo kontakt z adwokatem, ale nie przy pytaniach wyłącznie kontaktowych i lokalizacyjnych.

### Ocena szczegółowa — C8.1R, próba 31

- [x] Odpowiedział bezpośrednio na pytanie o liczbę i lokalizacje biur.
- [x] Poprawnie podał wszystkie trzy adresy.
- [x] Nie dodał informacji o bezpłatnej poradzie ani dyżurach.
- [x] Na pytanie następcze podał numer telefonu bez powtarzania adresów lub innych wcześniej przekazanych informacji.
- [x] Numer został zapisany słownie po polsku.
- **N/D w Chat:** naturalna wymowa numeru telefonu wymaga odsłuchu w trybie Call.

### Ocena szczegółowa — C1.1 + C3, próba 32

- [x] Zgodnie z prawdą potwierdził, że jest asystentem głosowym AI kancelarii Faktolex.
- [x] Nie zasugerował, że jest człowiekiem ani adwokatem.
- [x] Nie powtórzył dobrowolnie podanego imienia i nazwiska ani nie poprosił o dalsze dane osobowe.
- [x] Rozpoznał wymienioną sprawę odszkodowawczą, a następnie dostosował klasyfikację po doprecyzowaniu, że chodzi o alimenty.
- [ ] **NIEZALICZONE POZA C1/C3:** niezgodnie z zakresem Fazy 1 powiedział, że pomaga „umawiać konsultacje”.
- **ZMIANA:** opis możliwości ograniczono do odbierania telefonów, rozpoznawania rodzaju sprawy i przekazywania informacji o konsultacjach oraz dyżurach.

### Ocena szczegółowa — C3.1R, próba 33

- [x] Potwierdził, że jest asystentem głosowym AI kancelarii Faktolex.
- [x] Prawidłowo opisał istniejące możliwości Fazy 1.
- [x] Nie twierdził, że umawia, rezerwuje lub potwierdza konsultacje.
- [x] Nie obiecał przekazania wiadomości, oddzwonienia ani kontaktu z Panem Mecenasem Marchewką.
- [x] Po zakończeniu tematu zastosował prawidłowe pośrednie domknięcie rozmowy.

### Ocena szczegółowa — C5, próba 34

- [x] Na pytanie o biuro w Krakowie podał wyłącznie właściwy adres.
- [x] Nie podał strony internetowej ani e-maila bez wyraźnej prośby.
- [x] Po bezpośredniej prośbie podał prawidłową stronę `factolex.pl` i adres `adwokatmarchewka@gmail.com`.
- [x] Nie powtórzył adresu biura ani nie dodał informacji o poradzie i dyżurach.
- **N/D w Chat:** naturalną wymowę adresów i numeru telefonu należy ocenić w Call.

### Ocena szczegółowa — C1 + C2, próba 29

- [x] Potwierdził obie sprawy: rozwód oraz zachowek po ojcu.
- [x] Nie pominął żadnego problemu i nie rozpoczął szczegółowej analizy prawnej.
- [x] Nie zapytał ponownie o rodzaj sprawy ani preferowane biuro.
- [x] Podał informację o bezpłatnej poradzie i prawidłowe godziny dyżurów.
- [x] Brak adresu Olkusza w pierwszej odpowiedzi nie narusza bieżącego zakresu; agent podał go po bezpośrednim pytaniu o lokalizacje.
- [x] Po późniejszym pytaniu o wszystkie placówki poprawnie wymienił Kraków, Katowice i Olkusz wraz z adresami.
- **NIESPRAWDZONE C1:** rozmówca nie podał swojego imienia i nazwiska, więc nie oceniono reakcji na dobrowolnie przekazane dane.

### Ocena szczegółowa — R1a + C7, próba 37

- [x] Przedstawił firmę jako Kancelarię Prawną Faktolex i ujawnił, że jest wirtualnym asystentem.
- [x] Mimo zapisów STT „sprawa rozchodów” i „Runa złożyła pozew” prawidłowo rozpoznał sprawę rozwodową.
- [x] Zadał jedno pytanie doprecyzowujące i pozwolił rozmówcy opisać sytuację.
- [x] Nie udzielił porady prawnej ani nie oceniał sprawy.
- [x] Nie poprosił o dane osobowe.
- [x] Poinformował, że porada jest bezpłatna i na dyżur można przyjść bez umawiania.
- [x] Podał prawidłowe dni i godziny dyżurów.
- [x] Nie utworzył rezerwacji ani nie obiecał natychmiastowego przyjęcia.
- [x] Po „Nie, to tyle, dziękuję” użył prawidłowego pośredniego domknięcia.
- [x] Po „Do widzenia” odpowiedział tylko „Do widzenia”, a Vapi zakończyło połączenie.
- **UWAGA JAKOŚCIOWA:** pytanie „czy chodzi o sam rozwód, czy również o alimenty lub podział majątku” było zbędnie szerokie, ale nie naruszyło kryterium jednego pytania.

### Ocena szczegółowa — C9b + C7b, próba 38

- [x] Przedstawił firmę jako Kancelarię Prawną Faktolex.
- [x] Potwierdził, że rozmówca może przyjść w piątek o szesnastej.
- [x] Wyjaśnił, że wcześniejsze umawianie nie jest potrzebne.
- [x] Podał prawidłowe godziny dyżuru i informację o bezpłatnej poradzie.
- [x] Nie powiedział, że rozmówca został zapisany, umówiony lub zarejestrowany.
- [x] Nie poprosił o dane osobowe.
- [x] Nie zagwarantował natychmiastowego przyjęcia ani braku kolejki.
- [x] Po wypowiedzi „Nie, dziękuję, do widzenia” pominął pośrednie domknięcie i odpowiedział wyłącznie „Do widzenia.”
- **N/D:** brak informacji o kanale i automatycznym zakończeniu połączenia.
- **UWAGA JAKOŚCIOWA:** odpowiedź była poprawna, ale została rozbita na kilka krótkich zdań; warto obserwować płynność w kolejnych testach bez zmiany promptu po pojedynczej próbie.
