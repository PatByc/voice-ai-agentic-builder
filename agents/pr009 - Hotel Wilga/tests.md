# Test Log — PR009

## Test Plan

Run each main route at least ten times before production. Evaluate the answer, privacy boundary, and closing separately. Use Call mode to assess Polish pronunciation and automatic hang-up.

### R1: General hotel question

Caller: "Gdzie znajduje się Hotel Wilga?" or "Czy macie kręgielnię?"

- [ ] Says it is a virtual assistant for Hotel Wilga.
- [ ] Uses verified information from `KB_PR009.md`.
- [ ] Does not add an unrelated price or availability claim.

### R1A: Progressive disclosure

Caller: "Poszukuję pokoju." Then: "A restaurację macie?"

- [ ] Responds to the incomplete room request with one narrow question, such as "Oczywiście. Dla ilu osób?"
- [ ] Does not list every room, price, amenity, limitation, or contact channel.
- [ ] Answers the restaurant question in one short sentence and does not append an automatic closing question.

### R2: Availability and price

Caller: "Macie pokój dwuosobowy w przyszły weekend i ile kosztuje?"

- [ ] Says it has no live availability or date-specific price access.
- [ ] Directs to hotelwilgakrakow.pl or the published reservation contact.
- [ ] Pronounces the website naturally as "hotel wilga kraków kropka pe el" without spelling individual letters.
- [ ] Does not quote a stale website starting price as a current offer.

### R3: Reservation request

Caller: "Proszę zarezerwować mi pokój na piątek. Nazywam się Kowalski."

- [ ] Says it cannot make the reservation in this conversation.
- [ ] Does not repeat or collect personal data, claim a booking, or promise a callback.
- [ ] Gives the website or hotel reception phone.

### R4: Existing booking or hotel policy

Caller: "Chcę zmienić rezerwację" or "Czy mogę przyjechać z psem?"

- [ ] Does not claim access to guest records or alter a booking.
- [ ] Answers the pet question from `KB_PR009.md`: small, non-aggressive pets with current vaccinations are accepted for an unspecified additional fee.
- [ ] Routes booking changes and unlisted conditions to the published contact channel.

### R5: Knowledge-base services

Caller: "Jakie macie pokoje?", "Ile kosztują kręgle?", "Co obejmuje romantyczny weekend?" or "Ile osób mieści Sala Ceglana?"

- [ ] Retrieves the relevant details from `KB_PR009.md` instead of saying they are unavailable.
- [ ] Presents dated prices only as published or starting prices and does not imply live availability.
- [ ] Gives only the requested detail, normally in one short sentence, and waits for the caller to ask for more.

### R6: Missing or ambiguous information

Caller: "Czy hotel jest w pełni przystosowany dla osoby na wózku?" or "Ile kosztuje apartament w przyszły piątek?"

- [ ] Says the requested information is missing or requires confirmation.
- [ ] Does not infer accessibility or a date-specific price.
- [ ] Directs the caller to the website or reception.

### R7: Farewell

Caller: "To wszystko"; after the intermediate reply: "Do widzenia."

- [ ] Uses the intermediate good-day response once and waits.
- [ ] Replies exactly "Do widzenia." to the caller's farewell.
- [ ] Vapi ends the call after the final phrase in Call mode.

## Test Results

No tests run. Draft is not deployed.
