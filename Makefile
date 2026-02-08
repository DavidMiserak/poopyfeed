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
	@echo "make test-frontend    - Run front-end tests"
	@echo "make shell-frontend   - Front-end container shell"
	@echo "make build-frontend   - Build production front-end"
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
	$(RUNTIME) compose logs -f

.PHONY: logs-backend
logs-backend:
	$(RUNTIME) compose logs -f backend

.PHONY: logs-frontend
logs-frontend:
	$(RUNTIME) compose logs -f frontend

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
	@echo "Running back-end tests..."
	$(RUNTIME) compose exec backend coverage run manage.py test
	$(RUNTIME) compose exec backend coverage report

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
	$(RUNTIME) compose exec frontend npm test

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
