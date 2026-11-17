#!/usr/bin/env bash
# Prueba E2E solo para proyecto demo y emuladores locales.
set -euo pipefail
PROJECT="demo-healthy-habit"
HOST="127.0.0.1"
AUTH="http://$HOST:9099"
FUNCTIONS="http://$HOST:5001/$PROJECT/us-central1"
STORE="http://$HOST:8080/v1/projects/$PROJECT/databases/(default)/documents"
command -v python3 >/dev/null || { echo "Necesitas python3"; exit 1; }
command -v curl >/dev/null || { echo "Necesitas curl"; exit 1; }

echo "Creando usuario ANÓNIMO en Auth Emulator (sin credenciales reales)..."
auth_response=$(curl -fsS -X POST "$AUTH/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key" \
  -H "Content-Type: application/json" -d '{"returnSecureToken":true}')
UID_TEST=$(printf '%s' "$auth_response" | python3 -c 'import json,sys; print(json.load(sys.stdin)["localId"])')
TOKEN=$(printf '%s' "$auth_response" | python3 -c 'import json,sys; print(json.load(sys.stdin)["idToken"])')

echo "Creando SOLO datos ficticios en el emulador de Firestore..."
curl -fsS -X PATCH "$STORE/users/$UID_TEST/user_habits/water" \
  -H "Content-Type: application/json" \
  -d '{"fields":{"title":{"stringValue":"Tomar agua"}}}' >/dev/null
curl -fsS -X PATCH "$STORE/users/$UID_TEST/user_habits/water/attempts/attempt1" \
  -H "Content-Type: application/json" \
  -d '{"fields":{"status":{"stringValue":"inProgress"}}}' >/dev/null

echo "Solicitando desafío de prueba..."
creation=$(curl -fsS -X POST "$FUNCTIONS/startEvidenceChallenge" \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"data":{"habitId":"water","attemptId":"attempt1","objectId":"spoon"}}')
echo "$creation" | python3 -m json.tool
CHALLENGE_ID=$(printf '%s' "$creation" | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["challengeId"])')
CODE=$(printf '%s' "$creation" | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["code"])')
export CHALLENGE_ID CODE
body=$(python3 - <<'PY'
import json, os
print(json.dumps({"data": {
  "habitId": "water",
  "attemptId": "attempt1",
  "challengeId": os.environ["CHALLENGE_ID"],
  "code": os.environ["CODE"]
}}))
PY
)

echo "Comprobando código una sola vez (esto NO verifica una fotografía)..."
response=$(curl -fsS -X POST "$FUNCTIONS/checkEvidenceChallengeCode" \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d "$body")
echo "$response" | python3 -m json.tool
printf '%s' "$response" | python3 -c 'import json,sys; r=json.load(sys.stdin)["result"]; assert r["codeMatched"] and not r["imageVerified"] and r["xpAwarded"] == 0'

echo "Comprobando que reutilizar el desafío sea rechazado..."
replay=$(curl -sS -X POST "$FUNCTIONS/checkEvidenceChallengeCode" \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d "$body")
echo "$replay" | python3 -m json.tool
printf '%s' "$replay" | python3 -c 'import json,sys; r=json.load(sys.stdin)["error"]; assert r["status"] == "FAILED_PRECONDITION"'
echo "Prueba E2E completada: código de sesión, consumo único, cero XP."
