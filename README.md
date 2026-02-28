# PoopyFeed

<p align="center">
  <a href="https://github.com/DavidMiserak/poopyfeed/actions/workflows/test.yml">
    <img src="https://github.com/DavidMiserak/poopyfeed/actions/workflows/test.yml/badge.svg" alt="Tests" />
  </a>
  <a href="https://codecov.io/gh/DavidMiserak/poopyfeed">
    <img src="https://codecov.io/gh/DavidMiserak/poopyfeed/branch/main/graph/badge.svg" alt="codecov" />
  </a>
  <img src="https://img.shields.io/badge/python-3.13+-blue.svg" alt="Python 3.13+" />
  <img src="https://img.shields.io/badge/node-20+-green.svg" alt="Node 20+" />
  <img src="https://img.shields.io/badge/django-6.0-darkgreen.svg" alt="Django 6.0" />
  <img src="https://img.shields.io/badge/angular-21-red.svg" alt="Angular 21" />
  <a href="https://github.com/pre-commit/pre-commit">
    <img src="https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit" alt="pre-commit" />
  </a>
</p>

A baby care tracking web application for monitoring feeding, diapers, and sleep
patterns. Built with Django 6.0 (backend) and Angular 21 (frontend).

## Features

- **Multi-child support**: Track multiple children from one account
- **Child sharing**: Share access with co-parents and caregivers
- **Tracking**: Monitor feedings (bottle/breast), diaper changes, and naps
- **Role-based access**: Owner, co-parent, and caregiver roles
- **REST API**: Token-authenticated API for frontend and mobile apps
- **PWA ready**: Progressive Web App capabilities
- **Analytics**: Visualize feeding, diaper, and sleep trends
- **Data Export**: Export data as CSV or PDF

## Screenshots

| Sign Up                                           | Dashboard                                                    | Analytics                                             |
| ------------------------------------------------- | ------------------------------------------------------------ | ----------------------------------------------------- |
| ![Sign Up](images/mobile-screenshots/sign-up.png) | ![Quick Log](images/mobile-screenshots/dash-2-quick-log.png) | ![Analytics](images/mobile-screenshots/analytics.png) |

See **[docs/SCREENSHOTS.md](docs/SCREENSHOTS.md)** for all screenshots.

## Quick Start

### Prerequisites

- **Podman** (recommended) or **Docker**
- **Make**
- **Git**

To use Docker instead of Podman, set `RUNTIME=docker` in the root `Makefile` or use Docker Compose directly.

### Installation

```bash
# Clone repository with submodules
git clone <repo-url>
cd poopyfeed
git submodule update --init --recursive

# First-time setup (install hooks, build images)
make setup

# Start all services (frontend, backend, database, Redis, Celery worker)
make run
```

### Access

- **Frontend**: <http://localhost:4200>
- **Backend API**: <http://localhost:8000/api/v1/>
- **Django Admin**: <http://localhost:8000/admin/>

### Initial Setup

```bash
# Run database migrations
make migrate

# Create an admin user
make createsuperuser
```

## Project Structure

```text
poopyfeed/
├── front-end/           # Angular 21 frontend (submodule)
│   ├── poopyfeed/       # Angular application
│   ├── Containerfile    # Multi-stage Docker build
│   ├── Makefile         # Frontend commands
│   └── CLAUDE.md        # Frontend architecture guide
├── back-end/            # Django 6.0 backend (submodule)
│   ├── django_project/  # Django settings
│   ├── accounts/        # User management
│   ├── children/        # Child profiles & sharing
│   ├── diapers/         # Diaper tracking
│   ├── feedings/        # Feeding tracking
│   ├── naps/            # Nap tracking
│   ├── Containerfile    # Django container
│   ├── Makefile         # Backend commands
│   └── CLAUDE.md        # Backend architecture guide
├── docs/                # Design and persona documentation
├── podman-compose.yaml  # Orchestration (frontend, backend, db, Redis, Celery)
├── Makefile             # Root commands
├── DEPLOYMENT.md        # Full deployment guide
└── README.md            # This file
```

## Development

### Common Commands

```bash
make run              # Start all services
make stop             # Stop all services
make restart          # Stop and start
make logs             # View all logs
make logs-backend     # Backend logs only
make logs-frontend    # Frontend logs only
make migrate          # Run database migrations
make test-backend     # Run Django tests (with coverage)
make test-frontend    # Run Vitest tests
make clean            # Stop and remove volumes
```

Optional: `make redis-cli`, `make celery-worker`, `make celery-beat` for Redis/Celery inspection or running the scheduler.

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete documentation.

### Architecture

- **Frontend**: Angular 21 (standalone components, signals, SSR)
- **Backend**: Django 6.0 + Django REST Framework
- **Database**: PostgreSQL 14
- **Redis**: Cache, sessions, Celery broker (started with `make run`)
- **Celery**: Background tasks (e.g. PDF export); worker runs with `make run`
- **Authentication**: django-allauth (email-based) + Token auth (API)
- **Styling**: Tailwind CSS v4
- **Testing**: Vitest (frontend), Django TestCase (backend)

### Hot Reload

Both frontend and backend support hot reload during development:

- Edit files in `front-end/poopyfeed/` or `back-end/`
- Changes automatically reload in containers
- No rebuild needed!

## API Integration

The frontend connects to the backend API via a proxy configuration:

```typescript
// Frontend makes requests to /api/v1/*
this.http.get("/api/v1/children/");

// Proxy forwards to http://backend:8000/api/v1/children/
```

See `front-end/docs/API.md` for complete API documentation.

## Deployment

### Local Development

```bash
make run  # Uses podman-compose.yaml
```

### Production

- **Backend**: Deploy to Render (see `back-end/CLAUDE.md`)
- **Frontend**: Build production image with nginx (see `front-end/Containerfile`)

## Testing

```bash
# Backend tests (98%+ coverage, 280+ tests)
make test-backend

# Frontend tests (Vitest)
make test-frontend
```

## Code Quality

Pre-commit hooks enforce:

- Conventional commit messages
- Code formatting (Black, Prettier)
- Linting (Bandit, ESLint)
- Spell checking (codespell)

```bash
make pre-commit-setup  # Install hooks
```

## Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Full deployment guide
- **[back-end/CLAUDE.md](back-end/CLAUDE.md)** - Django architecture
- **[front-end/CLAUDE.md](front-end/CLAUDE.md)** - Angular architecture
- **[front-end/docs/API.md](front-end/docs/API.md)** - REST API reference
- **[docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)** - Design system
- **[docs/SCREENSHOTS.md](docs/SCREENSHOTS.md)** - All app screenshots
- **docs/personas/** - User personas (mom, dad, caretaker)

## Technology Stack

**Backend:**

- Django 6.0
- Django REST Framework
- Djoser (API auth)
- django-allauth (web auth)
- PostgreSQL 14
- Redis (cache, sessions, Celery broker)
- Celery (background tasks)
- Python 3.13

**Frontend:**

- Angular 21
- TypeScript 5.9 (strict mode)
- Tailwind CSS v4
- Vitest (testing)
- Server-Side Rendering (SSR)

**DevOps:**

- Podman (default) or Docker
- Compose orchestration
- Multi-stage containers
- Pre-commit hooks
- Make automation

## License

<!-- Add license information -->
