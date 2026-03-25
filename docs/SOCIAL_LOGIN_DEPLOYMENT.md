# Social Login Deployment Guide

This guide covers setting up Google and Facebook OAuth for production deployment on Kubernetes.

## What's Implemented

### Backend (django-allauth)

- ✅ Django REST framework integration with allauth.socialaccount
- ✅ OAuth provider endpoints for Google and Facebook
- ✅ Email auto-linking (users with same email across providers share account)
- ✅ Scope configuration: `email` + `profile` only
- ✅ API endpoints:
    - `POST /api/v1/browser/v1/auth/provider/redirect` - Initiate OAuth flow
    - `GET /api/v1/browser/v1/auth/socialaccount/` - List connected accounts (authenticated users only)
    - `DELETE /api/v1/browser/v1/auth/socialaccount/{id}/` - Disconnect account
    - `POST /api/v1/browser/v1/auth/token/` - Complete OAuth login

### Frontend (Angular)

- ✅ Social login buttons (Google + Facebook) on login, signup, and account settings pages
- ✅ OAuth redirect flow (user authenticates with provider, returns to `/auth/callback`)
- ✅ Account management UI (connect/disconnect social accounts)
- ✅ SSR-safe implementation (checks `typeof window === 'undefined'`)
- ✅ Error handling with user-friendly messages

## Production Setup Steps

### 1. Google OAuth Configuration

#### Create OAuth 2.0 credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Select your project (or create one)
3. Click "Create Credentials" → "OAuth 2.0 Client ID"
4. Choose "Web application"
5. Add Authorized JavaScript Origins:

    ```text
    https://your-production-domain.com
    https://www.your-production-domain.com
    ```

6. Add Authorized redirect URIs:

    ```text
    https://your-production-domain.com/auth/callback
    https://www.your-production-domain.com/auth/callback
    https://your-production-domain.com/api/v1/browser/v1/accounts/google/callback/
    ```

7. Save the credentials (you'll get `client_id` and `client_secret`)

**Scopes configured**: `email` + `profile`

### 2. Facebook OAuth Configuration (Optional)

#### Create Facebook App

1. Go to [Facebook Developers](https://developers.facebook.com/apps/)
2. Click "My Apps" → "Create App"
3. Choose "Business" type
4. Fill in app details and create
5. Go to Settings → Basic and note your **App ID** and **App Secret**
6. Go to Products → Add Product → "Facebook Login"
7. Configure OAuth Redirect URIs:
    - In Settings → Basic → App Domains, add: `your-production-domain.com`
    - In Facebook Login → Settings, set Valid OAuth Redirect URIs to:

        ```text
        https://your-production-domain.com/auth/callback
        https://www.your-production-domain.com/auth/callback
        https://your-production-domain.com/api/v1/browser/v1/accounts/facebook/callback/
        ```

8. In "Roles" → "Testers", add test accounts if running a test version

**Scopes configured**: `email` + `public_profile`

### 3. Kubernetes Secrets Setup

Create a secret containing OAuth credentials:

```bash
kubectl create secret generic social-login-credentials \
  --from-literal=GOOGLE_CLIENT_ID=<your-google-client-id> \
  --from-literal=GOOGLE_CLIENT_SECRET=<your-google-client-secret> \
  --from-literal=FACEBOOK_APP_ID=<your-facebook-app-id> \
  --from-literal=FACEBOOK_APP_SECRET=<your-facebook-app-secret> \
  -n default
```

Or in your Kubernetes manifests (recommended):

```yaml
apiVersion: v1
kind: Secret
metadata:
    name: social-login-credentials
    namespace: default
type: Opaque
stringData:
    GOOGLE_CLIENT_ID: "your-google-client-id"
    GOOGLE_CLIENT_SECRET: "your-google-client-secret"
    FACEBOOK_APP_ID: "your-facebook-app-id"
    FACEBOOK_APP_SECRET: "your-facebook-app-secret"
```

### 4. Update Backend Deployment

In your backend Deployment/Pod spec, inject secrets as environment variables:

```yaml
spec:
    containers:
        - name: backend
          image: your-registry/poopyfeed-backend:v1.0.0
          env:
              - name: GOOGLE_CLIENT_ID
                valueFrom:
                    secretKeyRef:
                        name: social-login-credentials
                        key: GOOGLE_CLIENT_ID
              - name: GOOGLE_CLIENT_SECRET
                valueFrom:
                    secretKeyRef:
                        name: social-login-credentials
                        key: GOOGLE_CLIENT_SECRET
              - name: FACEBOOK_APP_ID
                valueFrom:
                    secretKeyRef:
                        name: social-login-credentials
                        key: FACEBOOK_APP_ID
              - name: FACEBOOK_APP_SECRET
                valueFrom:
                    secretKeyRef:
                        name: social-login-credentials
                        key: FACEBOOK_APP_SECRET
          # ... other env vars (DEBUG, ALLOWED_HOSTS, DATABASE_URL, etc.)
```

### 5. Frontend Environment Setup

The frontend doesn't need credentials—it only needs the **callback URL**. The frontend automatically:

1. Redirects to `/auth/callback` after OAuth provider authentication
2. Calls backend API to complete login
3. Backend verifies with OAuth provider using stored credentials

No frontend environment variables needed for OAuth credentials (secure by design).

## Deployment Checklist

- [ ] **Google Console**: Created OAuth 2.0 credentials and set redirect URIs
- [ ] **Facebook Console**: (Optional) Created app and configured OAuth
- [ ] **Kubernetes Secrets**: Created `social-login-credentials` secret with credentials
- [ ] **Backend Deployment**: Updated pod spec to inject OAuth env vars from secret
- [ ] **ALLOWED_HOSTS**: Added production domain(s) to Django settings
- [ ] **Ingress/Load Balancer**: Configured to route `/auth/callback` to frontend
- [ ] **DNS/SSL**: Production domain resolves and has valid HTTPS certificate
- [ ] **Backend URL**: Frontend can reach backend API at configured URL
- [ ] **Test Flow**:
    - [ ] Local dev with Google OAuth working
    - [ ] Staging/production: Test Google login end-to-end
    - [ ] Test Facebook login (if enabled)
    - [ ] Test account disconnect on settings page
    - [ ] Test that email auto-linking works (create account with Google, then sign in with same email via password)

## Environment Variables Reference

### Backend (from secrets)

```bash
GOOGLE_CLIENT_ID=<google-oauth-client-id>
GOOGLE_CLIENT_SECRET=<google-oauth-client-secret>
FACEBOOK_APP_ID=<facebook-app-id>
FACEBOOK_APP_SECRET=<facebook-app-secret>
```

### Backend (existing, needs production values)

```bash
DEBUG=False
ALLOWED_HOSTS=your-production-domain.com,www.your-production-domain.com
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
CSRF_TRUSTED_ORIGINS=https://your-production-domain.com,https://www.your-production-domain.com
```

### Frontend (no changes needed for OAuth)

Frontend redirects are automatic via browser redirects, not API calls with credentials.

## Troubleshooting

### "Redirect URI mismatch" error

- Verify the redirect URI in OAuth provider console exactly matches what backend returns
- Check both with and without `www.` prefix
- Ensure HTTPS (not HTTP)
- Provider console might list as `accounts/google/callback/` vs browser sees `/auth/callback`—both must work

### OAuth login redirects to blank page

- Check browser console for errors
- Verify frontend can reach backend at configured API URL
- Backend logs should show successful OAuth completion
- Frontend might not be routing to `/auth/callback` correctly

### "CSRF token missing" errors

- Ensure `withCredentials: true` is set in Angular HTTP requests
- Backend `CSRF_TRUSTED_ORIGINS` must include production domain
- Check that cookies are being sent with requests

### "Email already exists" error

- This is expected if user tries to sign up with an email that already exists
- Email auto-linking handles the case where same email is used across OAuth providers
- Only triggers when email matches an existing account

## Security Considerations

1. **Credentials never in frontend**: OAuth credentials stored only in backend environment secrets
2. **HTTPS only**: Redirect URIs must use HTTPS (enforce with `SECURE_SSL_REDIRECT=True`)
3. **CSRF protection**: All requests validated with CSRF tokens
4. **Scope minimization**: Only request `email` + `profile` scopes
5. **Email validation**: Django validates email format before creating accounts
6. **Session security**: `SESSION_COOKIE_SECURE=True` in production

## Local Development Testing

### Google OAuth setup for local dev

1. In Google Cloud Console, add redirect URIs:

    ```text
    http://localhost:4200/auth/callback
    http://localhost:8000/api/v1/browser/v1/accounts/google/callback/
    ```

2. Copy credentials to local `.env` file (never commit):

    ```bash
    GOOGLE_CLIENT_ID=<dev-credential>
    GOOGLE_CLIENT_SECRET=<dev-credential>
    ```

3. Start services: `make run`
4. Test login flow at `http://localhost:4200/login`

### Testing account linking

1. Create account with password
2. In Account Settings, click "Connect Google"
3. Login with Google (same email)
4. Account should auto-link
5. Click "Disconnect Google" to unlink

## Additional Resources

- [django-allauth docs](https://django-allauth.readthedocs.io/)
- [Google OAuth Scopes](https://developers.google.com/identity/protocols/oauth2/scopes)
- [Facebook Permissions](https://developers.facebook.com/docs/permissions/reference)
- [PoopyFeed DEPLOYMENT.md](./DEPLOYMENT.md) - General production deployment guide
