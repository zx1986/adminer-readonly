.PHONY: help up down restart logs test load-test clean

# Absolutely awesome: http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Display this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

up: ## Start services in background
	docker-compose up -d

down: ## Stop and remove services
	docker-compose down

restart: ## Restart all services
	docker-compose restart

logs: ## Follow containers logs
	docker-compose logs -f

test: ## Run functional login verification
	./test-login.sh

load-test: ## Run k6 stress testing
	./run-load-test.sh

clean: ## Remove temporary test files
	rm -f load-test-results.json load-test-summary.json
	@echo "Cleaned up test artifacts."
