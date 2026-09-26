# Custom REST backend — universal contract

Αν δεν θες Supabase ή PocketBase, μπορείς να φτιάξεις **οποιοδήποτε δικό
σου server** (Node, Python/FastAPI, PHP, Go, ό,τι θες) αρκεί να εκθέτει
αυτά τα 3 endpoints. Η εφαρμογή δεν ξέρει τίποτα άλλο για το πώς είναι
φτιαγμένος ο server σου.

Στις ρυθμίσεις της εφαρμογής (Ρυθμίσεις -> Συγχρονισμός):
- **Backend provider** = "Custom REST"
- **URL** = η βάση του server σου, π.χ. `https://myserver.example.com`
- **API Key / Token** = ό,τι θες, πάει αυτολεξεί στο header
  `Authorization`. Αν γράψεις κάτι σαν `Bearer xyz` ή `Basic abc==`,
  μένει όπως το έγραψες. Αν γράψεις μόνο μια τιμή (π.χ. `xyz123`),
  στέλνεται σαν `Authorization: Bearer xyz123`.

## 1. `GET {URL}/sync_entries/ping`

Χρησιμοποιείται μόνο από το κουμπί "Δοκιμή σύνδεσης". Απάντησε με
οποιοδήποτε status < 400 (π.χ. 200, κενό body).

## 2. `POST {URL}/sync_entries/push`

Body (JSON):
```json
{
  "rows": [
    {
      "entry_id": "b3f1...-uuid",
      "device_origin": "leftheris-laptop",
      "payload": "base64-encrypted-blob...",
      "updated_at": "2026-09-05T21:00:00.000Z"
    }
  ]
}
```

Πρέπει να κάνεις **upsert** με βάση το `entry_id` (αν υπάρχει ήδη, update·
αλλιώς insert). Απάντησε με status < 400.

Το `payload` είναι ΗΔΗ κρυπτογραφημένο (AES-256-GCM) από την εφαρμογή -
είναι ένα ενιαίο blob που μπορεί να περιέχει είτε μια σημείωση είτε μια
εγγραφή καθημερινού (ο διαχωρισμός γίνεται ΜΕΣΑ στο κρυπτογραφημένο JSON,
πεδίο `kind`). Ο server σου απλά το αποθηκεύει σαν αδιαφανές string - δεν
χρειάζεται να ξέρει τίποτα για κρυπτογράφηση ή για τη δομή του Nivens.

## 3. `GET {URL}/sync_entries/pull?since=<ISO-8601 ή απουσιάζει>`

Επίστρεψε όλες τις γραμμές με `updated_at` **μεγαλύτερο** από το `since`
(ή όλες, αν δεν δόθηκε `since` — πρώτος συγχρονισμός). Format απάντησης:

```json
{
  "rows": [
    {
      "entry_id": "...",
      "device_origin": "...",
      "payload": "...",
      "updated_at": "2026-09-05T21:00:00.000Z"
    }
  ]
}
```

## Ελάχιστο schema (αν χρησιμοποιείς SQL από πίσω)

```sql
CREATE TABLE sync_entries (
  entry_id      TEXT PRIMARY KEY,
  device_origin TEXT NOT NULL,
  payload       TEXT NOT NULL,
  updated_at    TIMESTAMPTZ NOT NULL
);
CREATE INDEX idx_sync_entries_updated_at ON sync_entries (updated_at);
```

Αυτό είναι όλο — ο δικός σου server μπορεί να είναι όσο απλός ή σύνθετος
θες (auth, rate limiting, backups, ό,τι θες), αρκεί να τηρεί αυτά τα 3
endpoints.
