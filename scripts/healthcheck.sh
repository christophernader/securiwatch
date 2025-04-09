#!/bin/bash

# SecuriWatch Health Check Script
# This script checks the health of all components in the SecuriWatch stack

# Set color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "SecuriWatch Health Check"
echo "======================="
echo

# Check if docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}ERROR: Docker is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
fi

# Get list of services
SERVICES=$(docker-compose ps --services)

# Check each service
for SERVICE in $SERVICES; do
    echo -n "Checking $SERVICE... "
    
    # Get container ID
    CONTAINER_ID=$(docker-compose ps -q $SERVICE)
    
    # Check if container is running
    if [ -z "$CONTAINER_ID" ]; then
        echo -e "${RED}NOT RUNNING${NC}"
        continue
    fi
    
    STATUS=$(docker inspect --format='{{.State.Status}}' $CONTAINER_ID)
    
    if [ "$STATUS" == "running" ]; then
        # Get health status if available
        HEALTH=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}N/A{{end}}' $CONTAINER_ID)
        
        if [ "$HEALTH" == "healthy" ]; then
            echo -e "${GREEN}HEALTHY${NC}"
        elif [ "$HEALTH" == "N/A" ]; then
            echo -e "${GREEN}RUNNING${NC}"
        else
            echo -e "${YELLOW}$HEALTH${NC}"
        fi
        
        # Get uptime
        STARTED_AT=$(docker inspect --format='{{.State.StartedAt}}' $CONTAINER_ID)
        STARTED_TIMESTAMP=$(date -d "$STARTED_AT" +%s)
        CURRENT_TIMESTAMP=$(date +%s)
        UPTIME_SECONDS=$((CURRENT_TIMESTAMP - STARTED_TIMESTAMP))
        
        # Convert seconds to days, hours, minutes
        DAYS=$((UPTIME_SECONDS / 86400))
        HOURS=$(( (UPTIME_SECONDS % 86400) / 3600 ))
        MINUTES=$(( (UPTIME_SECONDS % 3600) / 60 ))
        
        echo "   - Uptime: ${DAYS}d ${HOURS}h ${MINUTES}m"
        
        # Get resource usage
        CPU=$(docker stats --no-stream --format "{{.CPUPerc}}" $CONTAINER_ID)
        MEM=$(docker stats --no-stream --format "{{.MemUsage}}" $CONTAINER_ID)
        
        echo "   - CPU: $CPU"
        echo "   - Memory: $MEM"
    else
        echo -e "${RED}$STATUS${NC}"
    fi
done

echo
echo "Network Check"
echo "------------"

# Check if services can communicate
if docker-compose exec -T elasticsearch curl -s -o /dev/null -w "%{http_code}" http://localhost:9200 >/dev/null 2>&1; then
    ES_STATUS=$(docker-compose exec -T elasticsearch curl -s -o /dev/null -w "%{http_code}" http://localhost:9200)
    if [ "$ES_STATUS" == "200" ]; then
        echo -e "Elasticsearch API: ${GREEN}OK ($ES_STATUS)${NC}"
    else
        echo -e "Elasticsearch API: ${YELLOW}RESPONDING WITH $ES_STATUS${NC}"
    fi
else
    echo -e "Elasticsearch API: ${RED}NOT RESPONDING${NC}"
fi

if docker-compose exec -T kibana curl -s -o /dev/null -w "%{http_code}" http://localhost:5601 >/dev/null 2>&1; then
    KIBANA_STATUS=$(docker-compose exec -T kibana curl -s -o /dev/null -w "%{http_code}" http://localhost:5601)
    if [ "$KIBANA_STATUS" == "200" ] || [ "$KIBANA_STATUS" == "302" ]; then
        echo -e "Kibana: ${GREEN}OK ($KIBANA_STATUS)${NC}"
    else
        echo -e "Kibana: ${YELLOW}RESPONDING WITH $KIBANA_STATUS${NC}"
    fi
else
    echo -e "Kibana: ${RED}NOT RESPONDING${NC}"
fi

if docker-compose exec -T logstash curl -s -o /dev/null -w "%{http_code}" http://localhost:9600 >/dev/null 2>&1; then
    LS_STATUS=$(docker-compose exec -T logstash curl -s -o /dev/null -w "%{http_code}" http://localhost:9600)
    if [ "$LS_STATUS" == "200" ]; then
        echo -e "Logstash API: ${GREEN}OK ($LS_STATUS)${NC}"
    else
        echo -e "Logstash API: ${YELLOW}RESPONDING WITH $LS_STATUS${NC}"
    fi
else
    echo -e "Logstash API: ${RED}NOT RESPONDING${NC}"
fi

echo
echo "Security Check"
echo "-------------"

# Check exposed ports
EXPOSED_9200=$(docker-compose port elasticsearch 9200)
if [ -n "$EXPOSED_9200" ]; then
    echo -e "${YELLOW}WARNING: Elasticsearch port 9200 is publicly exposed: $EXPOSED_9200${NC}"
    echo "   Consider removing the port mapping from docker-compose.yml for production use"
fi

# Check basic auth for nginx
if [ -f "config/nginx/.htpasswd" ]; then
    echo -e "Basic Authentication: ${GREEN}CONFIGURED${NC}"
else
    echo -e "Basic Authentication: ${RED}NOT CONFIGURED${NC}"
    echo "   Run the setup script to generate default credentials"
fi

# Check SSL certificates
if [ -f "config/nginx/ssl/securiwatch.crt" ] && [ -f "config/nginx/ssl/securiwatch.key" ]; then
    CERT_EXPIRY=$(openssl x509 -enddate -noout -in config/nginx/ssl/securiwatch.crt | cut -d= -f2)
    echo -e "SSL Certificates: ${GREEN}CONFIGURED${NC}"
    echo "   Expires: $CERT_EXPIRY"
else
    echo -e "SSL Certificates: ${RED}NOT CONFIGURED${NC}"
    echo "   Run the setup script to generate SSL certificates"
fi

echo
echo "For detailed logs, run: docker-compose logs"
echo "For service-specific logs, run: docker-compose logs [service_name]" 