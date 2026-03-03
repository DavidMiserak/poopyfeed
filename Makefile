# Makefile
# Root Makefile for PoopyFeed - orchestrates both front-end and back-end

RUNTIME := podman  # podman or docker
ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
E2E_DIR := $(ROOT)front-end/poopyfeed

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
	@echo "make test-e2e                 - Run E2E in container (requires: make run; backend uses relaxed throttling)"
	@echo "make test-e2e-local            - Run E2E on host (requires: make run; run make test-e2e-install once)"
	@echo "make shell-frontend            - Front-end container shell"
	@echo "make build-frontend            - Build production front-end"
	@echo ""
	@echo "Android Commands:"
	@echo "make build-android    - Build Android debug APK in container"
	@echo "make test-android     - Run Android unit tests in container"
	@echo "make lint-android     - Run Android lint checks in container"
	@echo "make format-android   - Format Kotlin code"
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
	@echo "Waiting for backend to be ready..."
	@$(MAKE) wait-for-backend
	@echo ""
	@echo "Services started!"
	@echo "- Front-end: http://localhost:4200"
	@echo "- Back-end API: http://localhost:8000/api/v1/"
	@echo "- Django Admin: http://localhost:8000/admin/"
	@echo ""
	@echo "Run 'make logs' to view logs"

.PHONY: wait-for-backend
wait-for-backend:
	@for i in $$(seq 1 30); do \
		curl -s -o /dev/null http://localhost:8000/api/v1/ 2>/dev/null && echo "Backend is ready." && exit 0; \
		sleep 2; \
	done; \
	echo "Backend failed to start within 60 seconds"; \
	exit 1

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
	@echo "Expected: ~120 seconds, 100% pass rate"
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

.PHONY: seed-data
seed-data:
	$(RUNTIME) compose exec backend python manage.py seed_data

.PHONY: seed-data-flush
seed-data-flush:
	$(RUNTIME) compose exec backend python manage.py seed_data --flush

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

.PHONY: test-e2e
test-e2e:
	@echo "======================================"
	@echo "Running E2E tests in container (Firefox, BASE_URL=frontend:4200)"
	@echo "Prerequisite: make run (frontend + backend must be up)"
	@echo "Backend runs with RELAX_E2E_THROTTLES=1 so E2E does not hit rate limits (429)."
	@echo "======================================"
	$(RUNTIME) compose exec frontend npm run test:e2e

.PHONY: test-e2e-local
test-e2e-local:
	@echo "======================================"
	@echo "Running E2E tests on host (Firefox, localhost:4200)"
	@echo "Prerequisite: make run; run make test-e2e-install once"
	@echo "Backend from 'make run' uses RELAX_E2E_THROTTLES=1 to avoid 429s during E2E."
	@echo "======================================"
	cd $(E2E_DIR) && npm run test:e2e

.PHONY: test-e2e-install
test-e2e-install:
	@echo "Installing E2E deps and Playwright Firefox (run once for test-e2e-local)..."
	cd $(E2E_DIR) && npm install && npx playwright install firefox

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
	@echo "Installing pre-commit hooks in android..."
	cd android && $(MAKE) pre-commit-setup
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

# Android commands (on-demand builds via compose profile)
.PHONY: build-android
build-android:
	@echo "Building Android debug APK..."
	$(RUNTIME) compose --profile android build android
	$(RUNTIME) compose --profile android run --rm android assembleDebug --no-daemon

.PHONY: test-android
test-android:
	@echo "Running Android unit tests..."
	$(RUNTIME) compose --profile android build android
	$(RUNTIME) compose --profile android run --rm android test --no-daemon

.PHONY: test-android-coverage
test-android-coverage:
	@echo "Running Android unit tests with coverage..."
	$(RUNTIME) compose --profile android build android
	$(RUNTIME) compose --profile android run --rm android jacocoTestReport --no-daemon

.PHONY: lint-android
lint-android:
	@echo "Running Android lint checks..."
	$(RUNTIME) compose --profile android build android
	$(RUNTIME) compose --profile android run --rm android lint --no-daemon

.PHONY: format-android
format-android:
	@echo "Formatting Android Kotlin code..."
	cd android && make format
