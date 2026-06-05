#!/bin/bash

# Cores para o output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "===================================================="
echo "🚀 INICIANDO SMOKE TEST - TOOGLE MASTER"
echo "===================================================="

SERVICES=(
    "auth-service:8001"
    "flag-service:8002"
    "targeting-service:8003"
    "evaluation-service:8004"
    "analytics-service:8005"
)

FAILED=0

for service in "${SERVICES[@]}"; do
    NAME=$(echo $service | cut -d: -f1)
    PORT=$(echo $service | cut -d: -f2)
    
    echo -n "Checando $NAME na porta $PORT... "
    
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/health)
    
    if [ "$STATUS" == "200" ]; then
        echo -e "${GREEN}OK (200)${NC}"
    else
        echo -e "${RED}FALHOU ($STATUS)${NC}"
        FAILED=$((FAILED + 1))
    fi
done

echo "===================================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ TODOS OS SERVIÇOS ESTÃO SAUDÁVEIS!${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILED SERVIÇO(S) COM PROBLEMAS.${NC}"
    exit 1
fi
