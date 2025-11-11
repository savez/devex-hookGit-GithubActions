#!/bin/bash
# Lefthook passa il file del commit come primo argomento
commit_msg_file=$1
commit_msg=$(cat "$commit_msg_file")

# Regex Better Commit / Conventional Commit
pattern="^(feat|fix|chore|docs|style|refactor|perf|test)(\([a-z0-9_-]+\))?\: .{1,50}"

if [[ ! "$commit_msg" =~ $pattern ]]; then
  echo "🚫 Commit non valido!"
  echo "Il messaggio deve rispettare lo stile Better Commit:"
  echo "  tipo(scope opzionale): descrizione"
  echo ""
  echo "Tipi consentiti: feat, fix, chore, docs, style, refactor, perf, test"
  echo "💡 TIPS: utilizzate la funzione di VSCode per generare commit. potete anche precaricare sul sistema un prompt che vi aiuta a scriverlo seguendo la convenzione di bettercommit."
  echo "di seguito vi do un prompt che potete usare (caricatelo nel settings.json di VSCode"
  cat <<'EOF'
"github.copilot.chat.commitMessageGeneration.instructions": [
  { "text": "Scrivi il messaggio di commit SOLO in italiano." },
  { "text": "Usa lo stile Better Commit: <type>[optional scope]: <emoji> <descrizione breve imperativa>." },
  { "text": "Titolo: massimo 72 caratteri, formale e imperativo. Dopo il titolo lascia una riga vuota." },
  { "text": "Aggiungi sempre un'emoji pertinente subito dopo il tipo (es. feat ✨, fix 🐛, docs 📝, refactor ♻️, style 🎨)." },
  { "text": "Descrizione: scrivi una descrizione tecnica a punti elenco che risponda a: Cosa è stato modificato; Perché; Impatti e rollback se applicabili; File o funzioni principali toccati." },
  { "text": "La descrizione deve avere titoli per ogni sezione." },
  { "text": "Se possibile includi statistiche automatiche: righe aggiunte/rimosse e coverage dei test. Queste statistiche puoi prenderle con un git diff o lanciando la coverage del progetto. Se non disponibili non inserire nulla." },
  { "text": "Mantieni uno stile conciso, professionale e leggibile. Prediligi punti elenco per la descrizione." },
  { "text": "Esempio di output desiderato:\nfeat(gql): ✨ Implementata selezione dinamica dei campi GraphQL\n\n- Implementata selezione dinamica per admission, admissions, appointment, appointments\n- Aggiunta funzione buildRequestFields per generare selection set ricorsivi (supporta patient.consents, visit.attachments)\n- Aggiornate query per usare selectionSetList invece di query hardcoded\n" }
],
EOF
  exit 1
fi

# Commit valido
exit 0