# Back-end improvements plan

This document plans the four improvements identified in the Django-expert review of the `back-end` submodule. Each section includes scope, dependencies, tasks, and acceptance criteria.

---

## 1. CustomUser timezone index (assess only)

**Goal:** Decide whether to add a database index on `CustomUser.timezone` based on actual query patterns.

**Findings from codebase:**

- Timezone is **read** from `request.user.timezone` in analytics (today_summary), forms, views, and templatetags.
- There are **no queries** that filter or order by `User.timezone` (e.g. no `User.objects.filter(timezone=...)` or bulk operations by timezone).
- Future features that might justify an index: “notify all users in timezone X at 8am local” or analytics/reporting grouped by timezone.

**Decision:** Do **not** add an index in the current codebase. Revisit only if we add timezone-based filtering/grouping (e.g. bulk notifications or reporting by timezone).

**Tasks:**

- [x] **1.1** Add a short comment in `accounts/models.py` on `CustomUser.timezone` noting that an index is intentionally omitted until timezone-based queries exist (optional, for future maintainers).
- [x] **1.2** No migration. No code change required unless the comment is added.

**Acceptance criteria:**

- Decision is documented (this plan).
- Optional: Comment in model clarifies “no index by design.”

**Effort:** Minimal (comment only) or none.

---

## 2. Composite indexes for tracking models

**Goal:** Add composite indexes `(child_id, <datetime_field>)` on Feeding, DiaperChange, and Nap to speed up queries that filter by child and date/datetime range.

**Justification:**

- **analytics/utils.py** and **children/views.py** repeatedly use:
    - `filter(child_id=..., fed_at__date__gte=..., fed_at__date__lte=...)`
    - `filter(child_id=..., changed_at__date__gte=..., changed_at__date__lte=...)`
    - `filter(child_id=..., napped_at__date__gte=..., napped_at__date__lte=...)`
- Single-column indexes already exist on `fed_at`, `changed_at`, `napped_at`. A composite `(child_id, <datetime>)` allows the database to narrow by child first, then use the datetime column for the range scan.

**Scope:**

- **Feedings:** `Index(fields=["child", "fed_at"])` on `feedings.Feeding` (table `children_feeding`).
- **Diapers:** `Index(fields=["child", "changed_at"])` on `diapers.DiaperChange` (table `children_diaperchange`).
- **Naps:** `Index(fields=["child", "napped_at"])` on `naps.Nap` (table `children_nap`).

**Dependencies:** None. Migrations are additive and do not change application code.

**Tasks:**

- [x] **2.1** Add `indexes` in `Feeding.Meta`: `[models.Index(fields=["child", "fed_at"])]`. Run `makemigrations feedings` (migration name suggestion: `add_child_fed_at_index`).
- [x] **2.2** Add `indexes` in `DiaperChange.Meta`: `[models.Index(fields=["child", "changed_at"])]`. Run `makemigrations diapers` (e.g. `add_child_changed_at_index`).
- [x] **2.3** Add `indexes` in `Nap.Meta`: `[models.Index(fields=["child", "napped_at"])]`. Run `makemigrations naps` (e.g. `add_child_napped_at_index`).
- [x] **2.4** Run `migrate` and confirm no errors. Run full backend test suite (`make test-backend` or equivalent).
- [ ] **2.5** Optionally run `EXPLAIN ANALYZE` on a representative analytics query (e.g. feeding trends for one child) before/after to confirm index use (PostgreSQL).

**Acceptance criteria:**

- Three new migrations; each adds one composite index.
- All tests pass.
- No application code changes beyond model `Meta` (and migrations).

**Effort:** Small. One migration per app, then verify.

---

## 3. PDF download filename non-guessable component

**Goal:** Make analytics PDF download URLs non-enumerable by adding a random component to the filename, while keeping unauthenticated, time-limited download behavior.

**Current behavior:** In `analytics/tasks.py`, `generate_pdf_report` sets:

```python
filename = f"analytics-{child.name.replace(' ', '_')}-{int(timezone.now().timestamp())}.pdf"
```

The URL is `/api/v1/analytics/download/<filename>/`. A timestamp in seconds is somewhat guessable (e.g. many requests in the same second).

**Proposed change:** Include a short cryptographically random segment in the filename so the URL cannot be enumerated. Keep timestamp for readability and optional cleanup (e.g. “generated at” or TTL).

**Scope:**

- **File:** `back-end/analytics/tasks.py`
- **Change:** Build filename with an extra segment from `secrets.token_urlsafe(8)` (or similar). Example format: `analytics-Child_Name-<timestamp>-<random>.pdf` so that the full path remains unique and non-guessable.
- **Download view:** No change to validation logic; existing checks (no `/`, `\`, leading `.`) remain. New format still passes.

**Dependencies:** None. Only the task that generates the filename and the returned `filename` in the task result are affected. Frontend uses `result.filename` / `download_url` from the export-status response; URL format change is backward-incompatible only for in-flight exports (acceptable).

**Tasks:**

- [x] **3.1** In `analytics/tasks.py`, add `import secrets` if not present. Replace the filename line with something like:
      `token = secrets.token_urlsafe(8)`
      `filename = f"analytics-{sanitized_name}-{int(timezone.now().timestamp())}-{token}.pdf"`
      Ensure `child.name` is sanitized (e.g. replace spaces with `_`, strip or replace other unsafe chars) so the filename stays safe for storage and `Content-Disposition`.
- [x] **3.2** Ensure `download_url` in the task return dict uses the same `filename`.
- [x] **3.3** Run analytics tests (e.g. `generate_pdf_report` and `download_pdf` tests). Update any test that asserts exact filename format to accept the new pattern (e.g. regex or suffix).
- [x] **3.4** Optionally document in `analytics/tasks.py` or this plan that the random component is for unguessable download URLs.

**Acceptance criteria:**

- Filename includes a cryptographically random segment.
- Existing path validation in `download_pdf` still applies; no new security regressions.
- All relevant tests pass; tests that check filename format are updated if needed.

**Effort:** Small. Single file change and test updates.

---

## 4. cache_utils annotated queryset order_by

**Goal:** Add an explicit `.order_by("id")` to the annotated queryset in `get_child_last_activities` so the query is deterministic and any future use with pagination would not trigger Django’s `UnorderedObjectListWarning`.

**Current behavior:** In `children/cache_utils.py`, the queryset is:

```python
missing_data = (
    Child.objects.filter(id__in=missing_child_ids)
    .annotate(...)
    .values("id", "last_diaper_change", "last_nap", "last_feeding")
)
```

Results are iterated with `for item in missing_data`; there is no pagination. Order does not affect the current logic because results are merged into a dict by `child_id`.

**Proposed change:** Add `.order_by("id")` before iterating (or when building the queryset) so that:

- The query has a well-defined order (deterministic, stable).
- If this queryset or a similar one is ever paginated elsewhere, it won’t rely on undefined ordering.

**Scope:**

- **File:** `back-end/children/cache_utils.py`
- **Change:** Add `.order_by("id")` to the `missing_data` queryset (after `.values(...)`).

**Dependencies:** None. No API or behavior change; only internal query order.

**Tasks:**

- [x] **4.1** In `get_child_last_activities`, add `.order_by("id")` to the `missing_data` queryset.
- [x] **4.2** Run backend tests (especially cache-related tests, e.g. `test_cache_invalidation.py`, `test_cache.py`) to ensure nothing breaks.

**Acceptance criteria:**

- Annotated queryset in `get_child_last_activities` includes `.order_by("id")`.
- All tests pass.

**Effort:** Trivial. One-line change.

---

## Implementation order

1. **4. cache_utils order_by** — One line, no migrations, low risk.
2. **3. PDF filename random segment** — Single file, clear security benefit.
3. **2. Composite indexes** — Three migrations; run together and verify.
4. **1. Timezone index (assess)** — Comment only or skip; no functional change.

---

## Summary

| Improvement             | Action                                      | Effort  |
| ----------------------- | ------------------------------------------- | ------- |
| 1. CustomUser timezone  | Document “no index”; optional model comment | Minimal |
| 2. Composite indexes    | 3 migrations (feedings, diapers, naps)      | Small   |
| 3. PDF filename         | Add random segment in `analytics/tasks.py`  | Small   |
| 4. cache_utils order_by | Add `.order_by("id")` in cache_utils        | Trivial |

All items are backward-compatible and additive except the PDF filename format (only affects new exports; in-flight exports may use the old format until they complete).
