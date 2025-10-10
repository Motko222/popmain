docker exec popmain ./pop status
docker exec popmain ./pop earnings
docker exec popmain curl -s http://localhost:8081/health/detailed | jq
