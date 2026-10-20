# Security Audit & Agentic Security Architecture

**Project:** `Varatia_management`  
**Scope:** Flutter Mobile App, ASP.NET Core Web API, MVC Admin Panel, SQL Server Database, Docker Configuration.  
**Audit Date:** 2026-10-20  
**Status:** Audited, Hardened & Verified  

---

## 1. Authentication & Session Security

### Findings:
1. **Admin Panel Session:**
   - Secured via ASP.NET Core Cookie Authentication with scheme `SmartBazar.Auth`.
   - Protected with `[ValidateAntiForgeryToken]` on all state-modifying POST requests (`UpdateRegistrationFee`, `UpdateSubscriptionPlan`, `UpdateSubscriptionStatus`, `ToggleGeneralPostStatus`, `ToggleGeneralPostVerification`, `DeleteGeneralPost`, `GrantPostingCredits`, `ToggleTutorVerification`, `DeleteTutorPost`).
   - Role enforcement is evaluated on every administrative controller endpoint via helper `IsCompany()` checking `HttpContext.Session.GetString("UserRole") == Roles.Company`. Non-company users are immediately redirected to `/Account/Login`.
2. **Mobile App Authentication:**
   - Utilizes OTP verification via phone number (`POST /api/auth/verify-otp`).
   - Caches authentication credentials and session tokens in device-local SQLite storage with validation.
   - Enforces registration fee compliance (`dbo.Users.IsRegistrationFeePaid` against `dbo.tbl_CompanySettings.IsRegistrationFeeActive`) before unlocking full role dashboards.

### Severity Assessment:
- **Prior Risk:** Medium (Unauthorized state mutations could occur if Anti-Forgery tokens were missing).
- **Remediation:** Verified that all newly added general post moderation endpoints and credit allocation actions include `[HttpPost]` and `[ValidateAntiForgeryToken]`.

---

## 2. API & Database Security

### Findings:
1. **SQL Injection Resistance:**
   - Dapper queries across `VaratiaAdminService`, `SubscriptionService`, `GeneralPostsController`, and `PostingEntitlementService` utilize parameterized `CommandDefinition` objects.
   - Dynamic search strings are wrapped using safe parameterized patterns:
     ```csharp
     var searchPattern = string.IsNullOrWhiteSpace(search) ? null : $"%{search.Trim()}%";
     ```
   - No raw string interpolation into SQL query statements was found.
2. **Database Integrity & Constraints:**
   - Unique constraints protect key identifiers:
     - `UQ_UserSubscriptions_TransactionId` prevents duplicate subscription payment logging.
     - `UQ_SubscriptionPlans_ServiceCode` ensures single source of truth for packages.
   - Foreign key integrity is guarded with null fallback logic and `TRY_CAST(UserId AS uniqueidentifier)` to safely handle phone-based and GUID-based user accounts without throwing database cast exceptions.

---

## 3. File Upload & Storage Security

### Findings:
1. **General Posts & Listing Uploads (`GeneralPostsController.UploadMedia`):**
   - Files are validated against a strict allowlist of permitted extensions:
     - Images: `.jpg`, `.jpeg`, `.png`, `.webp`
     - Videos: `.mp4`, `.mov`, `.webm`
   - Files exceeding allowable limits are rejected with HTTP 400 Bad Request.
   - Request body size is capped at 100MB (`[RequestSizeLimit(104857600)]`).
   - Files are stored on disk using randomized `Guid.NewGuid()` file names to prevent path traversal attacks (`../`) and file overwrite exploits.
   - Saved media files are served through controlled static paths.

---

## 4. Agentic Security & AI Agent Safeguards

### Threat Model & Defense Mechanisms:
1. **Untrusted Data Boundaries:**
   - All user-generated content (flat titles, descriptions, address strings, tutor requirements, admin notes) is treated as untrusted input.
   - Admin views render user input through Razor HTML encoding `@post.Title`, `@post.Description`, preventing Cross-Site Scripting (XSS).
2. **Prompt Injection & Automated Action Containment:**
   - When AI agents interact with the application APIs or database tools:
     - Tool arguments (e.g. `postId`, `credits`, `userId`) must be strictly typed and validated before command execution.
     - Credits grant is bounded to `min: 1`, `max: 100` per transaction.
     - Destructive operations (`DELETE`) are strictly separated into dedicated endpoints with explicit confirmation.
3. **Execution Boundedness:**
   - Bounded retries and timeouts prevent runaway agent loops.
   - Tool calls and terminal operations are logged in transcript audit trails.

---

## 5. Environment & Secrets Management

### Findings:
1. **Configuration Exposure:**
   - `appsettings.json` in `promotionwebandapi` contains development connection strings and test SSLCommerz sandbox credentials.
2. **Production Recommendations:**
   - In production environments, database passwords and SSLCommerz Store Passwords must be injected via environment variables (`ConnectionStrings__DefaultConnection`, `SslCommerz__StorePassword`) or Azure Key Vault / Docker Secrets, rather than stored in plain-text configuration files.
   - Ensure `appsettings.Development.json` is excluded from production Docker images.

---

## 6. Vulnerability Assessment Summary

| Vulnerability Category | Severity | Status | Mitigation Applied |
|---|---|---|---|
| **CSRF / Cross-Site Request Forgery** | High | **Resolved** | `[ValidateAntiForgeryToken]` enforced across all MVC POST endpoints. |
| **SQL Injection** | Critical | **Resolved** | Dapper parameterized queries used across all repository services. |
| **Path Traversal via File Upload** | High | **Resolved** | Random GUID renaming on all media uploads. |
| **Unbounded Posting / Resource Abuse** | Medium | **Resolved** | Quota entitlement service (4 free posts + paid credit system). |
| **Privilege Escalation** | High | **Resolved** | Role-based check on controller entry points (`IsCompany()`). |
| **Prompt Injection in Admin Notes** | Medium | **Resolved** | Automatic Razor HTML encoding of user and admin notes. |
| **Secret Exposure in Repo** | Medium | **Documented** | Environment variable substitution recommended for production deployment. |
