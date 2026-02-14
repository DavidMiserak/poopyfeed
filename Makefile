# Makefile
# Root Makefile for PoopyFeed - orchestrates both front-end and back-end

RUNTIME := podman  # podman or docker

.PHONY: help
help:
	@echo "PoopyFeed Development Commands"
	@echo "=============================="
	@echo "make run              - Start both front-end and back-end services"
	@echo "make stop             - Stop all services"
	@echo "make logs             - View logs from all services"
	@echo "make logs-backend     - View back-end logs only"
	@echo "make logs-frontend    - View front-end logs only"
	@echo "make restart          - Restart all services"
	@echo "make clean            - Stop services and remove volumes"
	@echo ""
	@echo "Back-end Commands:"
	@echo "make migrate          - Run Django migrations"
	@echo "make test-backend     - Run back-end tests"
	@echo "make shell-backend    - Django shell access"
	@echo ""
	@echo "Front-end Commands:"
	@echo "make test-frontend             - Run front-end tests"
	@echo "make test-frontend-coverage    - Run front-end tests with coverage (for SonarQube)"
	@echo "make shell-frontend            - Front-end container shell"
	@echo "make build-frontend            - Build production front-end"
	@echo ""
	@echo "Redis & Celery Commands:"
	@echo "make redis-cli         - Open Redis CLI"
	@echo "make redis-flush       - Clear all Redis data (WARNING: also clears sessions)"
	@echo "make celery-worker     - Start Celery worker (run in separate terminal)"
	@echo "make celery-beat       - Start Celery beat scheduler (run in separate terminal)"
	@echo ""
	@echo "Development Setup:"
	@echo "make setup            - Initial setup (install hooks, build images)"
	@echo "make pre-commit-setup - Install pre-commit hooks"

.PHONY: run
run:
	@echo "Starting PoopyFeed services..."
	$(RUNTIME) compose up -d --build
	@echo ""
	@echo "Services started!"
	@echo "- Front-end: http://localhost:4200"
	@echo "- Back-end API: http://localhost:8000/api/v1/"
	@echo "- Django Admin: http://localhost:8000/admin/"
	@echo ""
	@echo "Run 'make logs' to view logs"

.PHONY: stop
stop:
	@echo "Stopping all services..."
	$(RUNTIME) compose down

.PHONY: logs
logs:
	$(RUNTIME) compose logs

.PHONY: logs-backend
logs-backend:
	$(RUNTIME) compose logs backend

.PHONY: logs-frontend
logs-frontend:
	$(RUNTIME) compose logs frontend

.PHONY: restart
restart: stop run

.PHONY: clean
clean:
	@echo "Stopping services and removing volumes..."
	$(RUNTIME) compose down -v
	@echo "Cleaned up!"

# Back-end specific commands
.PHONY: migrate
migrate:
	@echo "Running Django migrations..."
	$(RUNTIME) compose exec backend python manage.py makemigrations
	$(RUNTIME) compose exec backend python manage.py migrate

.PHONY: test-backend
test-backend:
	@echo "======================================"
	@echo "Running back-end tests with coverage"
	@echo "Expected: ~53 seconds, 100% pass rate"
	@echo "Use case: CI/CD pipeline + full coverage verification"
	@echo "======================================"
	$(RUNTIME) compose exec backend coverage run manage.py test
	$(RUNTIME) compose exec backend coverage xml
	$(RUNTIME) compose exec backend coverage report
	@echo ""
	@echo "Coverage reports generated:"
	@echo "  - back-end/coverage.xml (for SonarQube)"
	@echo "  - Run: cd back-end && sonar-scanner"

.PHONY: test-backend-fast
test-backend-fast:
	@echo "======================================"
	@echo "Running back-end tests (fast, no coverage)"
	@echo "Expected: ~45 seconds, 100% pass rate"
	@echo "Use case: Quick feedback during development"
	@echo "======================================"
	$(RUNTIME) compose exec backend python manage.py test --verbosity=2

.PHONY: test-backend-quick
test-backend-quick:
	@echo "======================================"
	@echo "Running back-end tests (ultra-fast, minimal output)"
	@echo "Expected: ~42 seconds, 100% pass rate"
	@echo "Use case: Minimal output for rapid checks"
	@echo "======================================"
	$(RUNTIME) compose exec backend python manage.py test --verbosity=0

.PHONY: test-backend-parallel
test-backend-parallel:
	@echo "======================================"
	@echo "Running back-end tests with pytest parallel execution"
	@echo "Expected: ~16 seconds, 99.08% pass rate (4 workers)"
	@echo "Use case: Development with full test output"
	@echo "Note: 4 Redis tests fail in parallel (expected, use -m \"not parallel_unsafe\" to skip)"
	@echo "======================================"
	$(RUNTIME) compose exec backend pytest -n 4 --dist loadscope -v -m "not parallel_unsafe"

.PHONY: test-backend-parallel-fast
test-backend-parallel-fast:
	@echo "======================================"
	@echo "Running back-end tests with pytest parallel (fast mode)"
	@echo "Expected: ~13-15 seconds, 99.08% pass rate (4 workers)"
	@echo "Speedup: 3.5-4.0x faster than sequential tests! 🚀"
	@echo "Use case: FASTEST feedback during development"
	@echo "======================================"
	$(RUNTIME) compose exec backend pytest -n 4 --dist loadscope -q --no-cov -m "not parallel_unsafe"

.PHONY: test-backend-parallel-auto
test-backend-parallel-auto:
	@echo "======================================"
	@echo "Running back-end tests with pytest parallel (auto-detect CPU cores)"
	@echo "Expected: ~15-20 seconds, 99.08% pass rate (workers = CPU cores)"
	@echo "Use case: Development with flexible worker allocation"
	@echo "======================================"
	$(RUNTIME) compose exec backend pytest -n auto --dist loadscope -v

.PHONY: shell-backend
shell-backend:
	$(RUNTIME) compose exec backend python manage.py shell

.PHONY: createsuperuser
createsuperuser:
	$(RUNTIME) compose exec backend python manage.py createsuperuser

# Front-end specific commands
.PHONY: test-frontend
test-frontend:
	@echo "Running front-end tests..."
	$(RUNTIME) compose exec frontend npm test -- --watch=false

.PHONY: test-frontend-coverage
test-frontend-coverage:
	@echo "Running front-end tests with coverage..."
	$(RUNTIME) compose exec frontend npm test -- --coverage=true --watch=false

.PHONY: shell-frontend
shell-frontend:
	$(RUNTIME) compose exec frontend sh

.PHONY: build-frontend
build-frontend:
	@echo "Building production front-end..."
	$(RUNTIME) compose exec frontend npm run build

# Development setup
.PHONY: setup
setup: pre-commit-setup
	@echo "Building images..."
	$(RUNTIME) compose build
	@echo "Setup complete! Run 'make run' to start services."

.PHONY: pre-commit-setup
pre-commit-setup:
	@echo "Installing pre-commit hooks in root..."
	pre-commit install
	pre-commit install --install-hooks
	@echo "Installing pre-commit hooks in back-end..."
	cd back-end && $(MAKE) pre-commit-setup
	@echo "Installing pre-commit hooks in front-end..."
	cd front-end && $(MAKE) pre-commit-setup
	@echo "Pre-commit hooks installed!"

# Redis and Celery Commands
.PHONY: redis-cli
redis-cli:
	$(RUNTIME) compose exec redis redis-cli

.PHONY: redis-flush
redis-flush:
	@echo "WARNING: This will clear all Redis data including sessions and cache!"
	@read -p "Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		$(RUNTIME) compose exec redis redis-cli FLUSHALL; \
		@echo "Redis cleared!"; \
	else \
		@echo "Cancelled."; \
	fi

.PHONY: celery-worker
celery-worker:
	$(RUNTIME) compose exec backend celery -A django_project worker -l info

.PHONY: celery-beat
celery-beat:
	$(RUNTIME) compose exec backend celery -A django_project beat -l info
