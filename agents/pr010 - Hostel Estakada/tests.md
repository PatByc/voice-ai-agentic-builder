# Test Log — PR010

## Test Plan

Run each route at least ten times before production. Evaluate factual accuracy, brevity, privacy, pronunciation, and closing separately.

### R1: General accommodation inquiry

Caller: "Szukam noclegu dla czterech pracowników."

- [ ] Identifies itself as the virtual assistant for Hostel Estakada.
- [ ] Asks only for the missing stay duration.
- [ ] Does not list every room or every price.

### R2: Published price

Caller: "Ile kosztuje pokój czteroosobowy na dwa tygodnie?"

- [ ] Says the published rate is forty per person per night.
- [ ] Does not present the rate as live availability or a confirmed quotation.
- [ ] Keeps the answer to one or two short sentences.

### R2A: Relative dates and price pronunciation

Caller: "Potrzebuję całego pokoju czteroosobowego na następny weekend."

- [ ] Resolves the weekend silently using the Vapi current date in the Europe/Warsaw timezone.
- [ ] Does not ask for a separate date confirmation when the relative dates are clear.
- [ ] Repeats the exact dates only in the final reservation summary.
- [ ] Checks that weekdays match the calendar dates.
- [ ] Says "dwieście czterdzieści za cały pokój za dobę" without digits, currency symbols, or the words "złoty/złotych".

### R3: Demo availability and reservation

Caller: "Potrzebuję całego pokoju czteroosobowego od piątku do niedzieli."

- [ ] Resolves and confirms the exact dates before pricing.
- [ ] Returns the supported static demo availability instead of forwarding immediately to staff.
- [ ] Quotes two hundred forty per room per night and four hundred eighty for two nights, without a currency label.
- [ ] After selection, collects the full name and asks to use the calling number.
- [ ] Reads the complete summary and waits for explicit confirmation.
- [ ] Returns request number 1043 as "jeden zero cztery trzy".
- [ ] Says the invoice must be paid within 24 hours and does not claim the stay is confirmed before payment.

### R3A: Calling number declined

Caller declines use of the calling number.

- [ ] Explains briefly that the demo requires the calling number.
- [ ] Does not collect an alternative phone number or email address.
- [ ] Does not claim that a reservation request was created.

### R4: Reservation process

Caller: "Jak potwierdzana jest rezerwacja?"

- [ ] Explains that the hostel issues an invoice after the request.
- [ ] States that the invoice must be paid within 24 hours.
- [ ] Says payment confirms the reservation according to the invoice.

### R5: Existing reservation or invoice

Caller: "Chcę zmienić rezerwację. Numer faktury to..."

- [ ] Does not request, repeat, or record the invoice number.
- [ ] Does not claim access to guest or invoice records.
- [ ] Routes the caller to the hostel phone or email.

### R6: Facilities and location

Caller: "Czy jest kuchnia, pralka i parking?" or "Jak daleko jest PKP Kraków Podgórze?"

- [ ] Answers only with facts embedded in the system prompt.
- [ ] Confirms shared kitchens, laundry/drying facilities, and free parking.
- [ ] Gives approximately 80 metres for the railway station when asked.

### R7: Unsupported detail

Caller: "Ile kosztuje miejsce w pokoju ośmioosobowym?"

- [ ] Says the published table does not provide that price.
- [ ] Directs the caller to confirm it with the hostel.
- [ ] Does not infer the price from another room type.

### R8: Website pronunciation

Caller: "Jaka jest strona internetowa?"

- [ ] Pronounces it naturally as "hostel estakada kropka pe el".
- [ ] Does not spell every character unless explicitly asked.

### R9: Farewell

Caller: "To wszystko"; then: "Do widzenia."

- [ ] Gives the intermediate good-day response once.
- [ ] Waits for the caller's farewell.
- [ ] Responds exactly "Do widzenia." and ends the call.

## Test Results

No tests run. Draft is not deployed.
