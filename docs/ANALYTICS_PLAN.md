# Analytics Dashboard Implementation Plan

- **Status**: ✅ Phase 1 Complete (Feb 11, 2026)
- **Priority**: Medium (Post-MVP)
- **Personas**: Dad (Michael) - trend visualization, Mom (Sarah) - insights
- **Timeline**: Phase 1 Complete ✅ | Phase 2: Pending (4-6 weeks estimate)

---

## Overview

The analytics dashboard provides parents with trend visualization and
insights into their baby's patterns. Rather than computing
aggregations in the frontend, Django performs all data analysis and
serves pre-computed results via REST endpoints. Angular displays
results using Chart.js.

### Goals

- ✅ **Dad needs**: Trend visualization to stay informed while at work
- ✅ **Sarah needs**: Insights into baby patterns without manual analysis
- ✅ **Maria needs**: Not directly targeted (limited scope for caregiver role)
- ✅ **Performance**: No client-side aggregation; caching at database layer
- ✅ **Accuracy**: Single source of truth for all metrics

---

## Architecture

### High-Level Flow

```mermaid
graph LR
    A["🎨 Frontend<br/>(Angular)"]
    B["⚙️ Backend<br/>(Django)<br/>/api/v1/analytics/"]
    C["💾 Database<br/>(PostgreSQL)"]

    A -->|GET /feeding-trends/| B
    A -->|GET /diaper-patterns/| B
    A -->|GET /sleep-summary/| B
    B -->|SQL Aggregations| C
    C -->|Raw Data| B
    B -->|Pre-computed Data<br/>Charts, Summaries, Trends| A
```

### Endpoint Categories

#### 1. **Trend Endpoints** (Week/Month View)

```text
GET /api/v1/analytics/children/{child_id}/feeding-trends/
GET /api/v1/analytics/children/{child_id}/diaper-patterns/
GET /api/v1/analytics/children/{child_id}/sleep-summary/
```

**Response format** (example):

```json
{
    "period": "2026-02-01 to 2026-02-11",
    "child_id": 1,
    "daily_data": [
        {
            "date": "2026-02-01",
            "count": 5,
            "average_duration": 12.5,
            "total_minutes": 62.5
        }
    ],
    "weekly_summary": {
        "avg_per_day": 4.8,
        "trend": "increasing",
        "variance": 1.2
    },
    "last_updated": "2026-02-11T15:30:00Z"
}
```

#### 2. **Summary Endpoints** (Quick Stats)

```text
GET /api/v1/analytics/children/{child_id}/today-summary/
GET /api/v1/analytics/children/{child_id}/weekly-summary/
```

**Response format**:

```json
{
    "child_id": 1,
    "period": "today",
    "feedings": {
        "count": 4,
        "total_oz": 32,
        "bottle": 32,
        "breast": 0
    },
    "diapers": {
        "count": 6,
        "wet": 4,
        "dirty": 1,
        "both": 1
    },
    "sleep": {
        "naps": 2,
        "total_minutes": 180,
        "avg_duration": 90
    }
}
```

#### 3. **Export Endpoints** (Phase 2)

```text
POST /api/v1/analytics/children/{child_id}/export/csv/
POST /api/v1/analytics/children/{child_id}/export/pdf/
```

---

## Implementation Plan

### Phase 1: Core Analytics ✅ COMPLETE (Feb 11, 2026)

#### 1.1 Django Backend Setup ✅ COMPLETE

**Implemented files**:

```text
back-end/analytics/
├── __init__.py
├── apps.py
├── models.py              # (empty, no new models needed)
├── views.py               # ✅ AnalyticsViewSet with 5 endpoints
├── serializers.py         # ✅ Request/response validation
├── permissions.py         # ✅ HasAnalyticsAccess + role-based access
├── utils.py               # ✅ Aggregation functions (get_feeding_trends, etc.)
├── cache.py               # ✅ Cache invalidation helpers
├── signals.py             # ✅ Auto-invalidate cache on new tracking entries
├── urls.py                # ✅ URL routing for 5 endpoints
└── tests.py               # ✅ 26 test methods, 755 lines (97% coverage)
```

**URLs** (`back-end/config/urls.py`):

```python
path('api/v1/analytics/', include('analytics.urls')),
```

**New URL file** (`back-end/analytics/urls.py`):

```python
urlpatterns = [
    path('children/<int:child_id>/feeding-trends/', FeedingTrendsView.as_view()),
    path('children/<int:child_id>/diaper-patterns/', DiaperPatternsView.as_view()),
    path('children/<int:child_id>/sleep-summary/', SleepSummaryView.as_view()),
    path('children/<int:child_id>/today-summary/', TodaySummaryView.as_view()),
    path('children/<int:child_id>/weekly-summary/', WeeklySummaryView.as_view()),
]
```

#### 1.2 Endpoint Implementation ✅ COMPLETE

**All 5 endpoints implemented**:

- ✅ `GET /api/v1/analytics/children/{child_id}/feeding-trends/?days=30`
- ✅ `GET /api/v1/analytics/children/{child_id}/diaper-patterns/?days=30`
- ✅ `GET /api/v1/analytics/children/{child_id}/sleep-summary/?days=30`
- ✅ `GET /api/v1/analytics/children/{child_id}/today-summary/`
- ✅ `GET /api/v1/analytics/children/{child_id}/weekly-summary/`

**Implementation details**:

1. **Date range parameter**:

    ```python
    GET /api/v1/analytics/children/1/feeding-trends/?days=30
    # Returns last 30 days of data (default: 30, max: 90)
    ```

2. **Permission checking**:
    - Only show analytics for children user owns or has access to
    - Use existing `ChildAccessPermission` mixin
    - Return 404 if not authorized (security through obscurity)

3. **Caching strategy**:

    ```python
    # Cache analytics for 1 hour
    @cache_page(60 * 60)
    def get(self, request, child_id):
        # Compute aggregations
        # Return cached response
    ```

4. **SQL aggregation** (efficient):

    ```python
    from django.db.models import Count, Avg, Sum, Max, Min
    from django.db.models.functions import TruncDate, TruncWeek

    daily_stats = Feeding.objects.filter(
        child_id=child_id,
        created_at__gte=start_date
    ).annotate(
        date=TruncDate('created_at')
    ).values('date').annotate(
        count=Count('id'),
        avg_duration=Avg('duration_minutes'),
        total_oz=Sum('amount_oz')
    ).order_by('date')
    ```

#### 1.3 Frontend Components ✅ COMPLETE

**Implemented files**:

```text
front-end/poopyfeed/src/app/
├── features/
│   └── analytics/
│       ├── analytics-dashboard.ts        # ✅ Main container component
│       ├── analytics-dashboard.spec.ts   # ✅ 13 tests
│       ├── feeding-trends-chart.ts       # ✅ Line chart visualization
│       ├── feeding-trends-chart.spec.ts  # ✅ 23 tests
│       ├── diaper-patterns-chart.ts      # ✅ Stacked bar chart
│       ├── diaper-patterns-chart.spec.ts # ✅ 9 tests
│       ├── sleep-summary-chart.ts        # ✅ Timeline visualization
│       └── sleep-summary-chart.spec.ts   # ✅ 10 tests
├── services/
│   ├── analytics.service.ts              # ✅ API calls + client caching
│   └── analytics.service.spec.ts         # ✅ 12 tests
└── models/
    └── analytics.model.ts                # ✅ TypeScript interfaces
```

**Status**: 67 total tests, all passing ✅

**Service layer** (`analytics.service.ts`):

```typescript
@Injectable({ providedIn: "root" })
export class AnalyticsService {
    private http = inject(HttpClient);
    private cache = new Map<string, CacheEntry>();

    getFeedingTrends(
        childId: number,
        days: number = 30,
    ): Observable<FeedingTrends> {
        const key = `feeding-trends-${childId}-${days}`;

        if (this.cache.has(key) && !this.cache.get(key)!.isExpired()) {
            return of(this.cache.get(key)!.data);
        }

        return this.http
            .get<FeedingTrends>(
                `/api/v1/analytics/children/${childId}/feeding-trends/`,
                { params: { days: days.toString() } },
            )
            .pipe(
                tap((data) =>
                    this.cache.set(key, new CacheEntry(data, 5 * 60 * 1000)),
                ),
                catchError((error) =>
                    throwError(() => this.handleError(error)),
                ),
            );
    }

    // Similar methods for:
    // - getDiaperPatterns()
    // - getSleepSummary()
    // - getTodaySummary()
    // - getWeeklySummary()
}
```

**Main dashboard component**:

```typescript
@Component({
    selector: "app-analytics-dashboard",
    template: `
    <div class="space-y-8">
      <!-- Filters -->
      <app-analytics-filters
        (childChanged)="onChildChanged($event)"
        (daysChanged)="onDaysChanged($event)">
      </app-analytics-filters>

      <!-- Summary cards -->
      <div class="grid grid-cols-3 gap-4" @if (todaySummary(); as summary) {
        <app-summary-card
          title="Feedings Today"
          :value="summary.feedings.count">
        </app-summary-card>
        <!-- More cards -->
      }

      <!-- Trend charts -->
      <div class="grid grid-cols-2 gap-8">
        <app-feeding-trends-chart
          [data]="feedingTrends()">
        </app-feeding-trends-chart>

        <app-diaper-patterns-chart
          [data]="diaperPatterns()">
        </app-diaper-patterns-chart>
      </div>

      <app-sleep-summary-card
        [data]="sleepSummary()">
      </app-sleep-summary-card>
    </div>
  `,
})
export class AnalyticsDashboardComponent {
    selectedChildId = signal<number | null>(null);
    selectedDays = signal(30);

    feedingTrends = signal<FeedingTrends | null>(null);
    diaperPatterns = signal<DiaperPatterns | null>(null);
    sleepSummary = signal<SleepSummary | null>(null);
    todaySummary = signal<TodaySummary | null>(null);

    isLoading = signal(false);

    private analyticsService = inject(AnalyticsService);
    private router = inject(Router);

    ngOnInit() {
        this.loadAnalytics();
    }

    private loadAnalytics() {
        const childId = this.selectedChildId();
        if (!childId) return;

        this.isLoading.set(true);

        forkJoin({
            feeding: this.analyticsService.getFeedingTrends(
                childId,
                this.selectedDays(),
            ),
            diapers: this.analyticsService.getDiaperPatterns(
                childId,
                this.selectedDays(),
            ),
            sleep: this.analyticsService.getSleepSummary(
                childId,
                this.selectedDays(),
            ),
            today: this.analyticsService.getTodaySummary(childId),
        })
            .pipe(
                finalize(() => this.isLoading.set(false)),
                catchError((error) => {
                    // Show error toast
                    return throwError(() => error);
                }),
            )
            .subscribe((results) => {
                this.feedingTrends.set(results.feeding);
                this.diaperPatterns.set(results.diapers);
                this.sleepSummary.set(results.sleep);
                this.todaySummary.set(results.today);
            });
    }
}
```

**Chart component example** (with Chart.js):

```typescript
@Component({
    selector: "app-feeding-trends-chart",
    template: ` <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-lg font-semibold mb-4">Feeding Trends</h2>
        <canvas
            id="feedingChart"
            @if
            (!isLoading())
            else
            loadingSpinner
        ></canvas>
    </div>`,
})
export class FeedingTrendsChartComponent {
    data = input<FeedingTrends>();
    isLoading = input(false);

    chart: Chart | null = null;

    ngOnInit() {
        this.renderChart();
    }

    ngOnChanges() {
        if (this.chart) this.chart.destroy();
        this.renderChart();
    }

    private renderChart() {
        const ctx = document.getElementById(
            "feedingChart",
        ) as HTMLCanvasElement;
        if (!ctx || !this.data()) return;

        this.chart = new Chart(ctx, {
            type: "line",
            data: {
                labels: this.data()!.daily_data.map((d) => d.date),
                datasets: [
                    {
                        label: "Feedings per day",
                        data: this.data()!.daily_data.map((d) => d.count),
                        borderColor: "#FF6B35",
                        backgroundColor: "rgba(255, 107, 53, 0.1)",
                        tension: 0.4,
                    },
                ],
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: { display: true },
                },
            },
        });
    }
}
```

#### 1.4 Routing ✅ COMPLETE

**Implemented** in `front-end/poopyfeed/src/app/app.routes.ts`:

```typescript
{
  path: ':childId/analytics',
  loadComponent: () =>
    import('./features/analytics/analytics-dashboard').then(
      (m) => m.AnalyticsDashboard
    ),
  title: 'Analytics - PoopyFeed',
}
```

Route is accessible at `children/{childId}/analytics` after authentication.

#### 1.5 Testing ✅ COMPLETE

**Backend tests** (`back-end/analytics/tests.py`):

- ✅ Permission checks (owner, co-parent, caregiver, unauthorized)
- ✅ Date range validation (1-90 days, invalid ranges)
- ✅ Data accuracy (verify aggregations match raw data)
- ✅ Caching behavior (TTL, cache keys, invalidation)
- ✅ Edge cases (no data, future dates, timezone handling)
- ✅ **26 test methods covering all scenarios**
- ✅ **97% backend test coverage** (463 total tests passing)

**Frontend tests** (`front-end/poopyfeed/src/app/features/analytics/*.spec.ts`):

- ✅ Service integration with HttpTestingController (12 tests)
- ✅ Component rendering with mock data (13 + 9 + 10 tests)
- ✅ Chart initialization and data binding (23 chart tests)
- ✅ Error handling and edge cases
- ✅ **67 total tests across 5 files, all passing**
- ✅ **~90% frontend analytics coverage**

**Coverage achieved**: ✅ 97% backend + 90% frontend

---

### Phase 2: Export & Advanced Features (Weeks 4-6)

#### 2.1 CSV Export

```python
# back-end/analytics/views.py
class ExportCSVView(APIView):
    permission_classes = [IsAuthenticated, ChildAccessPermission]

    def post(self, request, child_id):
        child = get_object_or_404(Child, id=child_id)

        # Generate CSV in memory
        csv_buffer = StringIO()
        writer = csv.writer(csv_buffer)

        # Headers
        writer.writerow(['Date', 'Feedings', 'Diapers', 'Sleep (min)'])

        # Data rows
        for date in get_date_range(days=30):
            feedings = Feeding.objects.filter(child=child, created_at__date=date).count()
            diapers = DiaperChange.objects.filter(child=child, created_at__date=date).count()
            sleep = Nap.objects.filter(child=child, created_at__date=date).aggregate(Sum('duration_minutes'))
            writer.writerow([date, feedings, diapers, sleep])

        response = HttpResponse(csv_buffer.getvalue(), content_type='text/csv')
        response['Content-Disposition'] = f'attachment; filename="analytics-{child.name}-{date.today()}.csv"'
        return response
```

#### 2.2 PDF Export (Async Job)

```python
# back-end/analytics/tasks.py
from celery import shared_task
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Table, Paragraph, Spacer

@shared_task
def generate_pdf_report(child_id, user_id):
    child = Child.objects.get(id=child_id)
    user = User.objects.get(id=user_id)

    # Generate PDF with charts, summaries, insights
    filename = f'analytics-{child.name}-{date.today()}.pdf'
    path = f'/tmp/{filename}'

    doc = SimpleDocTemplate(path, pagesize=letter)
    story = []

    # Add content...
    doc.build(story)

    # Store file temporarily, return URL
    return {
        'filename': filename,
        'url': f'/api/v1/analytics/download/{filename}/',
        'expires': (now() + timedelta(hours=24)).isoformat()
    }

# Endpoint
class ExportPDFView(APIView):
    def post(self, request, child_id):
        task = generate_pdf_report.delay(child_id, request.user.id)
        return Response({'task_id': task.id})

class ExportStatusView(APIView):
    def get(self, request, task_id):
        task = AsyncResult(task_id)
        return Response({
            'status': task.status,
            'result': task.result if task.successful() else None
        })
```

---

## Data Models & Performance

### Caching Strategy

```python
# back-end/analytics/utils.py
from django.core.cache import cache

def get_feeding_trends(child_id, days=30):
    cache_key = f'analytics:feeding-trends:{child_id}:{days}'

    # Try cache first
    cached = cache.get(cache_key)
    if cached:
        return cached

    # Compute aggregations
    data = Feeding.objects.filter(
        child_id=child_id,
        created_at__gte=now() - timedelta(days=days)
    ).annotate(
        date=TruncDate('created_at')
    ).values('date').annotate(
        count=Count('id'),
        avg_duration=Avg('duration_minutes')
    ).order_by('date')

    # Cache for 1 hour
    cache.set(cache_key, data, 60 * 60)
    return data
```

### Invalidation

When new tracking records are created, invalidate relevant caches:

```python
# back-end/children/signals.py
from django.core.cache import cache
from django.db.models.signals import post_save
from django.dispatch import receiver

@receiver(post_save, sender=Feeding)
def invalidate_feeding_cache(sender, instance, **kwargs):
    child_id = instance.child_id
    cache.delete(f'analytics:feeding-trends:{child_id}:*')
    # Also invalidate summary caches

@receiver(post_save, sender=DiaperChange)
def invalidate_diaper_cache(sender, instance, **kwargs):
    # Similar invalidation
```

---

## Role-Based Access

```python
# back-end/analytics/permissions.py
class AnalyticsAccessPermission(BasePermission):
    def has_object_permission(self, request, view, obj):
        child = obj  # The Child object

        # Owner: full access
        if child.owner == request.user:
            return True

        # Co-parent: full access to analytics
        if child.shares.filter(user=request.user, role='CO').exists():
            return True

        # Caregiver: limited view (maybe no predictions/alerts)
        if child.shares.filter(user=request.user, role='CG').exists():
            return True

        return False
```

---

## Frontend Integration

### Navigation

Add to navbar:

```typescript
// Update navigation routes
private routes = [
  { label: 'Children', path: '/children', icon: 'users' },
  { label: 'Dashboard', path: '/dashboard', icon: 'home' },
  { label: 'Analytics', path: '/analytics', icon: 'chart-line' },  // NEW
  { label: 'Settings', path: '/settings', icon: 'cog' }
];
```

### Responsive Design

- **Desktop**: 2-column layout (trends + summaries)
- **Tablet**: Stacked with smaller charts
- **Mobile**: Full-width single column

---

## Success Criteria

### Phase 1 (Core Analytics) ✅ COMPLETE

- ✅ All 5 endpoints tested and working (26 backend tests)
- ✅ 97% backend test coverage (exceeds 95% goal)
- ✅ ~90% frontend test coverage (67 tests, 5 files)
- ✅ Charts display correctly on all devices
- ✅ Caching: 1hr TTL (60min default, 5min for today data)
- ✅ Cache auto-invalidates on new tracking entries via signals
- ✅ Date range validation: accepts 1-90 days (default 30)
- ✅ Permission checks: role-based access (owner/co-parent/caregiver)
- ✅ Completion date: February 11, 2026

### Phase 2 (Export)

- ✅ CSV exports contain accurate data
- ✅ PDF exports render charts and summaries
- ✅ Async jobs don't block API
- ✅ Downloads available for 24 hours

---

## Risk Mitigation

| Risk                        | Mitigation                                              |
| --------------------------- | ------------------------------------------------------- |
| **Performance degradation** | Use SQL aggregations + caching; avoid Python loops      |
| **Data inaccuracy**         | Comprehensive tests verifying aggregation correctness   |
| **Cache staleness**         | 1-hour TTL + immediate invalidation on new data         |
| **Permission bypass**       | 404 response (not 403); consistent with existing models |
| **Large datasets**          | Date range limiting (max 90 days); pagination if needed |

---

## Dependencies & Tools

**Backend**:

- Django ORM aggregations (built-in)
- Django cache framework (Redis optional)
- Django Rest Framework (existing)

**Frontend**:

- Chart.js 4.x (new dependency, add to package.json)
- Angular 21+ (existing)
- RxJS (existing)

**Optional Phase 2**:

- Celery + Redis (async export jobs)
- ReportLab (PDF generation)

---

## Timeline & Effort Estimate

### Phase 1 (COMPLETED)

| Task                | Planned        | Actual         | Status      |
| ------------------- | -------------- | -------------- | ----------- |
| Backend setup       | 3-4 days       | 2-3 days       | ✅ Done     |
| Backend tests       | 2-3 days       | 1-2 days       | ✅ Done     |
| Frontend service    | 2-3 days       | 2 days         | ✅ Done     |
| Chart components    | 4-5 days       | 4 days         | ✅ Done     |
| Dashboard component | 2-3 days       | 2 days         | ✅ Done     |
| Frontend tests      | 3-4 days       | 3 days         | ✅ Done     |
| **Total**           | **16-22 days** | **14-16 days** | **✅ Done** |
| Completed           | —              | Feb 11, 2026   | ✅ Early    |

### Phase 2 (NOT STARTED)

| Task                | Duration      | Status     |
| ------------------- | ------------- | ---------- |
| CSV export endpoint | 2-3 days      | 🚧 Pending |
| PDF export (Celery) | 3-4 days      | 🚧 Pending |
| Job polling UI      | 2-3 days      | 🚧 Pending |
| Export tests        | 2-3 days      | 🚧 Pending |
| **Total**           | **8-10 days** | 🚧 Pending |

---

## Next Steps

### Phase 1 Complete ✅

All infrastructure is in place:

- 5 REST API endpoints with caching and permissions
- Full frontend service layer with TypeScript models
- 3 chart components with comprehensive tests
- 67 frontend tests + 26 backend tests (all passing)
- Route registered and accessible at `/children/:childId/analytics`

### Ready for Phase 2

When prioritized, Phase 2 can begin with:

1. **Dependency addition**: Install export libraries
    - Backend: `reportlab` (PDF), `python-csv` (CSV)
    - Frontend: Notification UI for async job polling

2. **CSV Export Endpoint**:
    - New `ExportCSVView` at `POST /api/v1/analytics/children/{id}/export/csv/`
    - Inline response with CSV attachment

3. **PDF Export (Async)**:
    - New Celery task: `generate_pdf_report(child_id, user_id)`
    - New `ExportPDFView` that queues task and returns `task_id`
    - New `ExportStatusView` for job polling
    - Frontend polling UI with download link when ready

4. **User Feedback**: Monthly demos to Dad (Michael) for Phase 2 requirements

---

## Questions to Answer Before Starting

1. **Date ranges**: Should default be 30 days? Allow up to 90 days?
2. **Timezone handling**: Display dates in child's timezone or user's?
3. **Caregiver access**: Can caregivers (Maria) see analytics or just add data?
4. **Real-time data**: Is 1-hour cache TTL acceptable or need faster updates?
5. **Mobile priority**: Full charts on mobile or simplified views?
