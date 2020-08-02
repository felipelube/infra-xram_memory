dev-test:
	docker-compose -f docker-compose.yml -f docker-compose.local.yml up -d && \
	docker-compose -f docker-compose.yml -f docker-compose.local.yml exec -e PYTHONUNBUFFERED=TRUE --user 33 webadmin echo "start" && \
	docker-compose -f docker-compose.yml -f docker-compose.local.yml exec -e PYTHONUNBUFFERED=TRUE --user 33 webadmin pytest
dev-test-taxonomy:
	docker-compose -f docker-compose.yml -f docker-compose.local.yml exec --user 33 webadmin pytest tests/test_taxonomy.py
