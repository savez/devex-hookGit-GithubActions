#!/bin/bash

# Script per review interattiva con GitHub Copilot
echo ""
echo "🤖 GitHub Copilot Code Review"
echo "================================"
echo ""
echo "File da revieware:"
for file in "$@"; do
  echo "  - $file"
done
echo ""

# Chiedi conferma all'utente
read -p "Vuoi che GitHub Copilot analizzi questi file? (s/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
  echo "⏭️  Review saltata. Continuando con il commit..."
  exit 0
fi

echo ""
echo "🔍 Analisi in corso..."
echo ""

# Verifica che gh copilot sia installato
if ! command -v gh &> /dev/null || ! gh extension list | grep -q "gh-copilot"; then
  echo "⚠️  GitHub Copilot CLI non installato."
  echo "   Installa con: gh extension install github/gh-copilot"
  exit 0
fi

HAS_ISSUES=false

for file in "$@"; do
  echo "📄 Reviewing: $file"
  
  # Ottieni il contenuto del file staged
  CONTENT=$(git diff --cached "$file")
  
  if [ -z "$CONTENT" ]; then
    echo "   ✅ Nessuna modifica"
    continue
  fi
  
  # Chiedi a Copilot di analizzare (versione semplificata)
  echo "   🤖 Chiedendo a Copilot..."
  
  # Crea un prompt più specifico
  PROMPT="Analizza questo diff per bug critici, vulnerabilità di sicurezza o errori logici. Sii conciso e riporta solo problemi reali:Agisci come un esperto security auditor e analizzatore di codice statico. Analizza i seguenti file per identificare:

## AREE DI ANALISI

1. **Vulnerabilità di Sicurezza:**
   - SQL Injection
   - XSS (Cross-Site Scripting)
   - CSRF (Cross-Site Request Forgery)
   - Injection di comandi
   - Path traversal
   - Deserializzazione non sicura
   - Uso di funzioni deprecate o non sicure
   - Mancanza di validazione input
   - Gestione non sicura di password/hash

2. **Esposizione Credenziali (CRITICO):**
   - API keys hardcoded nel codice
   - Token di autenticazione in chiaro
   - Password o secrets hardcoded
   - Connessioni database con credenziali in chiaro
   - Chiavi private o certificati
   - ESCLUDERE dalla ricerca: file .env, .env.*, .gitignore

3. **Bug di Flusso e Logica:**
   - Race conditions
   - Null pointer/undefined references
   - Loop infiniti potenziali
   - Memory leaks
   - Gestione errori mancante o inadeguata
   - Condizioni logiche errate
   - Off-by-one errors
   - Deadlock potenziali

4. **Best Practices Violate:**
   - Mancanza di sanitizzazione input/output
   - Logging di informazioni sensibili
   - Permessi troppo permissivi
   - Uso di HTTP invece di HTTPS
   - Mancanza di rate limiting

## FORMATO OUTPUT RICHIESTO

Fornisci un report strutturato in questo formato:

### RIEPILOGO ESECUTIVO
- Affidabilità dell'analisi: [X]% (basata su: copertura del codice analizzato, complessità del codice, certezza dei pattern rilevati)
- Totale problemi trovati: [N]
- Criticità: [N] Critici, [N] Alti, [N] Medi, [N] Bassi

### TABELLA RIASSUNTIVA

| # | Problema | Tipologia | Severità | File | Righe | Descrizione | Confidenza |
|---|----------|-----------|----------|------|-------|-------------|------------|
| 1 | API Key Hardcoded | Credenziali | CRITICO | auth.js | 45-47 | Chiave API AWS esposta | 95% |
| 2 | SQL Injection | Sicurezza | ALTO | db.js | 123 | Query concatenata senza sanitizzazione | 90% |
| 3 | XSS Vulnerability | Sicurezza | ALTO | render.js | 67 | Output non sanitizzato in innerHTML | 85% |
| ... | ... | ... | ... | ... | ... | ... | ... |

### DETTAGLIO PROBLEMI

#### 🔴 PROBLEMA #1: [Nome Problema]
- **Tipologia:** [Credenziali/Sicurezza/Bug Logico/Best Practice]
- **Severità:** [CRITICO/ALTO/MEDIO/BASSO]
- **Confidenza:** [X]%
- **File:** `path/to/file.js`
- **Righe:** 45-47
- **Codice Problematico:**
```javascript
  const apiKey = "sk-1234567890abcdef"; // ⚠️ HARDCODED API KEY
```
- **Descrizione:** Chiave API hardcoded nel codice sorgente. Questa può essere estratta facilmente da chiunque abbia accesso al repository.
- **Impatto:** Accesso non autorizzato ai servizi esterni, possibile furto di dati o abuso del servizio.
- **Raccomandazione:** 
  - Spostare la chiave in variabili d'ambiente
  - Usare un secret manager (AWS Secrets Manager, HashiCorp Vault)
  - Revocare immediatamente la chiave esposta e generarne una nuova
- **Fix Suggerito:**
```javascript
  const apiKey = process.env.API_KEY;
  if (!apiKey) throw new Error('API_KEY not configured');
```

---

[Ripeti per ogni problema trovato]

### METRICHE DI AFFIDABILITÀ

**Affidabilità complessiva: [X]%**

Fattori considerati:
- ✅ Copertura analisi: [X]% del codice esaminato
- ✅ Pattern riconosciuti: [N] pattern di sicurezza verificati
- ⚠️ Limitazioni: [eventuali limitazioni dell'analisi statica]
- ℹ️ Note: [considerazioni aggiuntive]

### RACCOMANDAZIONI PRIORITARIE

1. **URGENTE** - Rimuovere immediatamente le credenziali hardcoded (Problemi: #1, #4)
2. **ALTO** - Implementare sanitizzazione input per prevenire injection (Problemi: #2, #5)
3. **MEDIO** - Migliorare gestione errori e logging (Problemi: #7, #9)

### PROSSIMI PASSI

1. [ ] Correggere tutti i problemi CRITICI
2. [ ] Implementare test di sicurezza automatizzati
3. [ ] Code review delle aree critiche
4. [ ] Configurare SAST tools nel CI/CD

---

**NOTA:** Questa è un'analisi statica automatizzata. Si raccomanda:
- Verifica manuale dei problemi ad alta severità
- Penetration testing per confermare le vulnerabilità
- Security audit completo da parte di esperti

\`\`\`diff
$CONTENT
\`\`\`"
  
  # Usa gh copilot suggest in modo non interattivo
  REVIEW=$(echo "$PROMPT" | gh copilot suggest 2>&1 || echo "Errore nella chiamata")
  
  # Mostra il risultato
  echo "   Risposta:"
  echo "$REVIEW" | sed 's/^/   /'
  echo ""
  
  # Chiedi all'utente se vuole procedere
  if echo "$REVIEW" | grep -iE "(bug|error|vulnerability|issue|problem)" > /dev/null; then
    read -p "   ⚠️  Trovati potenziali problemi. Continuare comunque? (s/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
      HAS_ISSUES=true
      break
    fi
  fi
done

if [ "$HAS_ISSUES" = true ]; then
  echo ""
  echo "❌ Commit annullato dall'utente"
  exit 1
fi

echo ""
echo "✅ Review completata. Continuando con il commit..."
exit 0