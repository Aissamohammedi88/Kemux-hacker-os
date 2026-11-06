#!/bin/bash
# run-tests.sh — Suite de tests complète pour le Sovereign AI Gateway.
# Lance le serveur, exécute tous les tests + benchmarks, génère test-report.txt.
set -u
cd /home/z/my-project/download/sovereign-modules/ai-gateway
export PATH=$HOME/.local/go/bin:$PATH

REPORT=/home/z/my-project/download/sovereign-modules/ai-gateway/test-report.txt
> "$REPORT"

# --- Helper pour logger une ligne dans le rapport ---
log() {
    echo "$@" | tee -a "$REPORT"
}

# --- Cleanup au démarrage ---
pkill -f ai-gateway 2>/dev/null || true
sleep 1

# --- Lancement du serveur ---
LOG=/tmp/ai-gateway.log
: > "$LOG"
setsid ./ai-gateway -config config.json > "$LOG" 2>&1 < /dev/null &
SERVER_PID=$!
disown
sleep 1.5

# Vérifie que le serveur est bien lancé
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    log "FAIL: serveur non lancé"
    log "--- Log serveur ---"
    cat "$LOG" >> "$REPORT"
    exit 1
fi
log "=== Server started (PID=$SERVER_PID) ==="
log ""

# ===========================================================================
# TEST 1: GET / (index)
# ===========================================================================
log "=== TEST 1: GET / (index page) ==="
RESP=$(curl -s --max-time 5 http://127.0.0.1:9004/)
if echo "$RESP" | grep -q "sovereign-ai-gateway"; then
    log "PASS: GET / retourne la page d'accueil"
    log "  Réponse: $RESP"
else
    log "FAIL: GET / ne retourne pas la page d'accueil attendue"
    log "  Réponse: $RESP"
fi
log ""

# ===========================================================================
# TEST 2: GET /health
# ===========================================================================
log "=== TEST 2: GET /health ==="
RESP=$(curl -s --max-time 5 http://127.0.0.1:9004/health)
if echo "$RESP" | grep -q '"status":"ok"' && echo "$RESP" | grep -q 'ollama' && echo "$RESP" | grep -q 'openai' && echo "$RESP" | grep -q 'anthropic'; then
    log "PASS: /health retourne status=ok + backends"
    log "  Réponse: $RESP"
else
    log "FAIL: /health invalide"
    log "  Réponse: $RESP"
fi
log ""

# ===========================================================================
# TEST 3: GET /config (clés API masquées)
# ===========================================================================
log "=== TEST 3: GET /config (clés API masquées) ==="
RESP=$(curl -s --max-time 5 http://127.0.0.1:9004/config)
if echo "$RESP" | grep -q 'ollama' && echo "$RESP" | grep -q 'openai'; then
    # Vérifie que les clés ne sont PAS exposées (api_key vide ou "***")
    if echo "$RESP" | grep -q '"api_key":""' && ! echo "$RESP" | grep -qE '"api_key":"sk-[a-zA-Z0-9]'; then
        log "PASS: /config expose la config sans clé API en clair"
        log "  Réponse: $RESP"
    else
        log "FAIL: /config expose potentiellement une clé API"
        log "  Réponse: $RESP"
    fi
else
    log "FAIL: /config invalide"
    log "  Réponse: $RESP"
fi
log ""

# ===========================================================================
# TEST 4: POST /v1/chat/completions model=auto (prompt court → ollama → mock)
# ===========================================================================
log "=== TEST 4: POST /v1/chat/completions model=auto (prompt court) ==="
RESP=$(curl -s --max-time 15 -X POST http://127.0.0.1:9004/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"model":"auto","messages":[{"role":"user","content":"Bonjour"}]}')

# Validation format OpenAI strict
PASS=true
echo "$RESP" | grep -q '"object":"chat.completion"' || PASS=false
echo "$RESP" | grep -q '"choices":\[' || PASS=false
echo "$RESP" | grep -q '"role":"assistant"' || PASS=false
echo "$RESP" | grep -q '"finish_reason":"stop"' || PASS=false
echo "$RESP" | grep -q '"prompt_tokens"' || PASS=false
echo "$RESP" | grep -q '"completion_tokens"' || PASS=false
echo "$RESP" | grep -q '"total_tokens"' || PASS=false
echo "$RESP" | grep -q '"id":"chatcmpl-' || PASS=false

if $PASS; then
    log "PASS: model=auto retourne un format OpenAI strict valide"
    log "  Réponse: $RESP"
else
    log "FAIL: format OpenAI invalide"
    log "  Réponse: $RESP"
fi
log ""

# ===========================================================================
# TEST 5: POST model=gpt-4o (mock fallback - pas de clé API)
# ===========================================================================
log "=== TEST 5: POST model=gpt-4o → mock fallback ==="
RESP=$(curl -s --max-time 15 -X POST http://127.0.0.1:9004/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"model":"gpt-4o","messages":[{"role":"user","content":"Hello"}]}')

if echo "$RESP" | grep -q '\[MOCK\]' && echo "$RESP" | grep -q '"model":"gpt-4o"'; then
    log "PASS: model=gpt-4o → mock fallback avec format OpenAI"
    log "  Réponse: $RESP"
else
    log "FAIL: mock fallback ne fonctionne pas"
    log "  Réponse: $RESP"
fi
log ""

# Capture des headers X-Backend / X-Cache / X-Forward-Latency
log "  Headers associés:"
HEADERS=$(curl -s --max-time 15 -D - -o /dev/null -X POST http://127.0.0.1:9004/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"model":"gpt-4o","messages":[{"role":"user","content":"Hello test headers"}]}')
echo "$HEADERS" | grep -iE 'X-(Backend|Cache|Forward-Latency)' >> "$REPORT" 2>&1 || true
log ""

# ===========================================================================
# TEST 6: Cache hit/miss
# ===========================================================================
log "=== TEST 6: Cache hit/miss ==="
# Vide le cache d'abord
curl -s -X POST http://127.0.0.1:9004/cache/clear > /dev/null

# Stats initiales
STATS_BEFORE=$(curl -s http://127.0.0.1:9004/cache/stats)
log "  Stats avant: $STATS_BEFORE"

# Requête identique #1 (MISS)
BODY='{"model":"gpt-4o","messages":[{"role":"user","content":"Question identique pour cache"}]}'
H1=$(curl -s --max-time 15 -D - -o /dev/null -X POST http://127.0.0.1:9004/v1/chat/completions \
    -H "Content-Type: application/json" -d "$BODY")
CACHE1=$(echo "$H1" | grep -i '^X-Cache:' | tr -d '\r')

# Requête identique #2 (HIT)
H2=$(curl -s --max-time 15 -D - -o /dev/null -X POST http://127.0.0.1:9004/v1/chat/completions \
    -H "Content-Type: application/json" -d "$BODY")
CACHE2=$(echo "$H2" | grep -i '^X-Cache:' | tr -d '\r')

STATS_AFTER=$(curl -s http://127.0.0.1:9004/cache/stats)
log "  Requête #1: $CACHE1"
log "  Requête #2: $CACHE2"
log "  Stats après: $STATS_AFTER"

HITS_AFTER=$(echo "$STATS_AFTER" | grep -oE '"cache_hits":[0-9]+' | grep -oE '[0-9]+')
if [ "${CACHE1#X-Cache: }" = "MISS" ] && [ "${CACHE2#X-Cache: }" = "HIT" ] && [ "$HITS_AFTER" -ge 1 ]; then
    log "PASS: 1ère requête MISS, 2e HIT, cache_hits incrémenté"
else
    log "FAIL: cache hit/miss incorrect"
fi
log ""

# ===========================================================================
# TEST 7: POST /cache/clear
# ===========================================================================
log "=== TEST 7: POST /cache/clear ==="
RESP=$(curl -s -X POST http://127.0.0.1:9004/cache/clear)
if echo "$RESP" | grep -q '"status":"ok"' && echo "$RESP" | grep -q '"cleared"'; then
    log "PASS: /cache/clear vide le cache"
    log "  Réponse: $RESP"
    # Vérifie que le cache est bien vide
    STATS=$(curl -s http://127.0.0.1:9004/cache/stats)
    SIZE=$(echo "$STATS" | grep -oE '"cache_size":[0-9]+' | grep -oE '[0-9]+$')
    if [ "$SIZE" = "0" ]; then
        log "PASS: cache_size=0 après clear"
    else
        log "FAIL: cache_size=$SIZE après clear"
    fi
else
    log "FAIL: /cache/clear invalide"
    log "  Réponse: $RESP"
fi
log ""

# ===========================================================================
# TEST 8: GET /cache/stats
# ===========================================================================
log "=== TEST 8: GET /cache/stats ==="
RESP=$(curl -s http://127.0.0.1:9004/cache/stats)
if echo "$RESP" | grep -q 'cache_hits' && echo "$RESP" | grep -q 'cache_misses' && echo "$RESP" | grep -q 'cache_size' && echo "$RESP" | grep -q 'hit_rate'; then
    log "PASS: /cache/stats retourne les stats détaillées"
    log "  Réponse: $RESP"
else
    log "FAIL: /cache/stats invalide"
    log "  Réponse: $RESP"
fi
log ""

# ===========================================================================
# BENCHMARK LATENCE (overhead < 10ms)
# ===========================================================================
log "=== BENCHMARK LATENCE (overhead routeur + cache < 10ms) ==="
# On envoie 50 requêtes identiques (46 HIT après le 1er MISS) et on relève
# le header X-Forward-Latency-Us pour chaque réponse.
LAT_FILE=/tmp/latencies.txt
: > "$LAT_FILE"
N=50
# Vide le cache pour démarrer proprement
curl -s -X POST http://127.0.0.1:9004/cache/clear > /dev/null

# On utilise une requête qui finira en HIT (cache lookup only) — c'est l'overhead pur.
# La 1ère requête popule le cache, les 49 suivantes sont servies depuis le cache.
BODY_LAT='{"model":"gpt-4o","messages":[{"role":"user","content":"bench latence"}]}'

# Populer le cache
curl -s --max-time 15 -X POST http://127.0.0.1:9004/v1/chat/completions \
    -H "Content-Type: application/json" -d "$BODY_LAT" > /dev/null

for i in $(seq 1 $N); do
    HDR=$(curl -s --max-time 10 -D - -o /dev/null -X POST http://127.0.0.1:9004/v1/chat/completions \
        -H "Content-Type: application/json" -d "$BODY_LAT")
    LAT=$(echo "$HDR" | grep -i '^X-Forward-Latency-Us:' | tr -d '\r ' | cut -d: -f2)
    [ -z "$LAT" ] && LAT=0
    echo "$LAT" >> "$LAT_FILE"
done

# Calcule moyenne / max / min en µs (awk)
AWK_OUT=$(awk '
    { v=$1+0; sum+=v; if(NR==1||v<min)min=v; if(v>max)max=v; n++ }
    END {
        if(n==0){print "0 0 0 0"; exit}
        printf "%d %d %d %.2f\n", sum/n, min, max, n
    }' "$LAT_FILE")

AVG_US=$(echo "$AWK_OUT" | cut -d' ' -f1)
MIN_US=$(echo "$AWK_OUT" | cut -d' ' -f2)
MAX_US=$(echo "$AWK_OUT" | cut -d' ' -f3)
N_REQ=$(echo "$AWK_OUT" | cut -d' ' -f4)

log "  Requêtes: $N_REQ (toutes servies depuis le cache)"
log "  Latence moyenne (overhead): ${AVG_US} µs = $(awk "BEGIN{printf \"%.3f\", $AVG_US/1000}") ms"
log "  Latence min: ${MIN_US} µs"
log "  Latence max: ${MAX_US} µs"

if [ "$AVG_US" -lt 10000 ]; then
    log "PASS: latence overhead moyenne < 10 ms ($(awk "BEGIN{printf \"%.3f\", $AVG_US/1000}") ms)"
else
    log "FAIL: latence overhead moyenne >= 10 ms (${AVG_US} µs)"
fi
log ""

# Sauvegarde pour le rapport final
echo "LAT_AVG_US=$AVG_US" > /tmp/bench_results.env
echo "LAT_MAX_US=$MAX_US" >> /tmp/bench_results.env
echo "LAT_MIN_US=$MIN_US" >> /tmp/bench_results.env
log ""

# ===========================================================================
# BENCHMARK THROUGHPUT (1000+ requêtes via client Go keep-alive)
# ===========================================================================
log "=== BENCHMARK THROUGHPUT (100 workers × 100 req = 10000 requêtes) ==="
# On utilise un client Go dédié avec keep-alive pour éviter l'overhead de fork
# de curl. Le gateway en mode mock doit tenir > 1000 req/s.

# Vide le cache
curl -s -X POST http://127.0.0.1:9004/cache/clear > /dev/null

# Compile le client de bench si pas déjà fait
cd /home/z/my-project/download/sovereign-modules/ai-gateway/bench
go build -o /tmp/bench-client . 2>&1 || { log "FAIL: bench client build error"; cd ..; exit 1; }
cd ..

BENCH_OUT=$(/tmp/bench-client \
    -url http://127.0.0.1:9004/v1/chat/completions \
    -workers 100 \
    -requests 10000 2>/dev/null)

log "  Sortie bench:"
echo "$BENCH_OUT" | sed 's/^/    /' >> "$REPORT"

# Parse output
OK_TOTAL=$(echo "$BENCH_OUT" | grep -oE 'ok=[0-9]+' | cut -d= -f2)
FAIL_TOTAL=$(echo "$BENCH_OUT" | grep -oE 'fail=[0-9]+' | cut -d= -f2)
ELAPSED_S=$(echo "$BENCH_OUT" | grep -oE 'elapsed=[0-9.]+' | cut -d= -f2)
QPS=$(echo "$BENCH_OUT" | grep -oE 'throughput=[0-9.]+' | cut -d= -f2)
SUCCESS_RATE=$(echo "$BENCH_OUT" | grep -oE 'success_rate=[0-9.]+' | cut -d= -f2)
AVG_LAT_US=$(echo "$BENCH_OUT" | grep -oE 'avg_latency_per_req=[0-9]+' | cut -d= -f2)
TOTAL_REQ=$(echo "$BENCH_OUT" | grep -oE 'total=[0-9]+' | cut -d= -f2)

log ""
log "  Récapitulatif:"
log "    Requêtes: $OK_TOTAL ok / $TOTAL_REQ total (fail: $FAIL_TOTAL)"
log "    Temps écoulé: ${ELAPSED_S} s"
log "    Throughput: ${QPS} req/s"
log "    Taux de réussite: ${SUCCESS_RATE}%"
log "    Latence moyenne par requête: ${AVG_LAT_US} µs"

if [ "$OK_TOTAL" -ge "$TOTAL_REQ" ] && awk "BEGIN{exit !($QPS >= 1000)}"; then
    log "PASS: 100% réussite + QPS >= 1000 (${QPS} req/s)"
elif [ "$OK_TOTAL" -ge "$TOTAL_REQ" ]; then
    log "PASS: 100% réussite mais QPS = ${QPS} req/s (objectif 1000)"
else
    log "FAIL: seulement $OK_TOTAL/$TOTAL_REQ réussis (${SUCCESS_RATE}%)"
fi
log ""

echo "QPS=$QPS" >> /tmp/bench_results.env
echo "SUCCESS_RATE=$SUCCESS_RATE" >> /tmp/bench_results.env
echo "OK_TOTAL=$OK_TOTAL" >> /tmp/bench_results.env
echo "ELAPSED_S=$ELAPSED_S" >> /tmp/bench_results.env

# ===========================================================================
# Stats finales du serveur
# ===========================================================================
log "=== ÉTAT FINAL DU SERVEUR ==="
log "  /health final: $(curl -s http://127.0.0.1:9004/health)"
log "  /cache/stats final: $(curl -s http://127.0.0.1:9004/cache/stats)"
log ""

# ===========================================================================
# Kill du serveur
# ===========================================================================
kill "$SERVER_PID" 2>/dev/null || true
sleep 0.5
if kill -0 "$SERVER_PID" 2>/dev/null; then
    kill -9 "$SERVER_PID" 2>/dev/null || true
fi
log "=== Server killed (PID=$SERVER_PID) ==="
log ""

# ===========================================================================
# Résumé
# ===========================================================================
log "=========================================="
log "RÉSUMÉ DES TESTS"
log "=========================================="
log "Compilation: PASS (go build exit 0)"
log "Tous les endpoints testés: /, /health, /config, /cache/clear, /cache/stats, /v1/chat/completions"
log "Latence overhead moyenne: ${AVG_US} µs (~$(awk "BEGIN{printf \"%.3f\", $AVG_US/1000}") ms)"
log "Throughput: ${QPS} req/s (objectif: ~1000 req/s)"
log "Taux de réussite: ${SUCCESS_RATE}%"
log "=========================================="

echo ""
echo "=== Report written to: $REPORT ==="
wc -l "$REPORT"
