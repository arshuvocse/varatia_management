# API Integration Audit: Flutter App, Backend & Admin Panel

**Repository:** `Varatia_management`  
**Components:** ASP.NET Core Web API (`promotionwebandapi`), Flutter Network Services (`varatia_management_apps`), SQL Server (`SmartBazarDbmssql`).  
**Audit Date:** 2026-10-20  
**Status:** 100% Tested & Verified  

---

## 1. Overview & Verification Strategy

All API endpoints supporting the mobile application and administrative portal were inspected, tested via unit tests (`PromotionWeb.Tests`), and verified against live HTTP endpoints running on `http://localhost:28457`.

---

## 2. API Endpoints Inventory & Contracts

### A. General Rental & Listing Posts (`/api/general-posts`)

| Endpoint | Method | Auth | Description | Request Body / Query | Expected Response | Verified Status |
|---|---|---|---|---|---|---|
| `/api/general-posts` | `GET` | Public | Retrieve active rental and service posts with optional filters | `category`, `tenantType`, `divisionId`, `areaId`, `search`, `page`, `pageSize` | `200 OK` (Array of `GeneralPostDto`) | **Verified Live** (Returns flats, rooms, mess posts) |
| `/api/general-posts` | `POST` | User | Create a new listing post within entitlement quota | `CreatePostDto` (Title, Price, Location, Amenities, MediaInfo) | `201 Created` / `402 Payment Required` (if quota exceeded) | **Verified** |
| `/api/general-posts/upload` | `POST` | User | Upload image/video media files for a post | `IFormFileCollection` (multipart/form-data) | `200 OK` (`fileUrls: string[]`) | **Verified** |
| `/api/general-posts/entitlement` | `GET` | User | Check user's remaining free and paid post quota | Query: `userId` | `200 OK` (`freeAllowed`, `freeUsed`, `paidBalance`) | **Verified** |
| `/api/general-posts/purchase-credits` | `POST` | User | Initiate SSLCommerz checkout to buy additional listing credits | `PurchasePostCreditsRequest` (Credits, UserId) | `200 OK` (`paymentUrl`, `transactionId`) | **Verified** |

### B. Subscriptions & Matchmaking Packages (`/api/subscriptions`)

| Endpoint | Method | Auth | Description | Request Body / Query | Expected Response | Verified Status |
|---|---|---|---|---|---|---|
| `/api/subscriptions/plans` | `GET` | Public | Retrieve active subscription packages for owners, tenants, tutors | Query: `activeOnly=true` | `200 OK` (List of 4 packages: `find_flat`, `find_tenant`, `find_tutor`, `find_student`) | **Verified Live** (Returns JSON list from DB) |
| `/api/subscriptions/initiate` | `POST` | User | Initiate SSLCommerz checkout for a subscription service | `InitiateSubscriptionPaymentRequest` (ServiceCode, UserId, Phone, Requirements) | `200 OK` (`paymentUrl`, `transactionId`) | **Verified** |
| `/api/subscriptions/user-subscriptions` | `GET` | User | Get current user's active and historical subscriptions | Query: `userId` | `200 OK` (List of `UserSubscriptionDto` with remaining delivery days) | **Verified** |
| `/api/subscriptions/all` | `GET` | Admin | Administrative listing of all matchmaking requests | Query: `search`, `status` | `200 OK` (Complete list with customer requirements and deadline) | **Verified** |
| `/api/subscriptions/update-plan` | `POST` | Admin | Modify fee, title, description, or delivery days of a package | `UpdateSubscriptionPlanRequest` | `200 OK` (`message`) | **Verified** |
| `/api/subscriptions/update-status` | `POST` | Admin | Update fulfillment status (`in_progress`, `matched`, `cancelled`) and notes | `UpdateSubscriptionStatusRequest` | `200 OK` (`message`) | **Verified** |

### C. Teach & Learn / Tutor Matching (`/api/teach-learn`)

| Endpoint | Method | Auth | Description | Request Body / Query | Expected Response | Verified Status |
|---|---|---|---|---|---|---|
| `/api/teach-learn/posts` | `GET` | Public | List tutor and student tuition postings | Query: `postType`, `classGrade`, `medium`, `subject`, `division`, `area` | `200 OK` (Array of tutor posts) | **Verified** |
| `/api/teach-learn/posts` | `POST` | User | Submit a new tutor availability or student tuition request | `TenantTutorPost` model | `200 OK` (`postId`) | **Verified** |
| `/api/teach-learn/request-contact` | `POST` | User | Request direct phone contact of tutor or student | `RequestContactInput` (PostId, RequesterPhone) | `200 OK` (`contactPhone`) | **Verified** |
| `/api/teach-learn/admin/posts` | `GET` | Admin | Administrative feed of all tutor posts with verification flag | Query: `postType`, `verification`, `search` | `200 OK` (Admin tutor list) | **Verified** |
| `/api/teach-learn/admin/posts/{id}/verify` | `POST` | Admin | Toggle verification badge on tutor post | Route: `id` | `200 OK` (`isVerified: bool`) | **Verified** |
| `/api/teach-learn/admin/posts/{id}` | `DELETE` | Admin | Remove inappropriate or expired tutor post | Route: `id` | `200 OK` | **Verified** |

### D. Administrative Management MVC Endpoints (`/Account/*`)

| Endpoint | Method | Auth | Description | Parameters | Result | Verified Status |
|---|---|---|---|---|---|---|
| `/Account/VaratiaManagement` | `GET` | Company | Unified dashboard for tenants, properties, payments, SSLCommerz, users, subscriptions, and general posts | `tab`, `search`, `status`, `category` | `ViewResult` with `AdminVaratiaManagementViewModel` | **Verified** |
| `/Account/ToggleGeneralPostStatus` | `POST` | Company | Toggle general listing active/inactive | Form: `postId`, Anti-Forgery Token | Redirect to `VaratiaManagement?tab=generalposts` | **Verified** (Unit tested) |
| `/Account/ToggleGeneralPostVerification` | `POST` | Company | Toggle verification badge on general listing | Form: `postId`, Anti-Forgery Token | Redirect to `VaratiaManagement?tab=generalposts` | **Verified** (Unit tested) |
| `/Account/DeleteGeneralPost` | `POST` | Company | Permanently remove general listing | Form: `postId`, Anti-Forgery Token | Redirect to `VaratiaManagement?tab=generalposts` | **Verified** |
| `/Account/GrantPostingCredits` | `POST` | Company | Allocate paid posting credits to a user | Form: `userId`, `credits`, Anti-Forgery Token | Redirect to `VaratiaManagement?tab=generalposts` | **Verified** (Unit tested) |
| `/Account/UpdateRegistrationFee` | `POST` | Company | Update global user registration fee (BDT) & active switch | Form: `registrationFee`, `isRegistrationFeeActive` | Redirect to `VaratiaManagement?tab=settings` | **Verified** |

---

## 3. Data Integrity & Concurrency

1. **Transaction Safety:**
   - Multi-step payment confirmations run inside database operations to prevent partial writes.
   - Entitlement allocations use `MERGE` statements in SQL Server to atomically update existing balances or insert new user quota records.
2. **Error Handling & HTTP Status Codes:**
   - Validation failures return `400 Bad Request` with structured error messages.
   - Authentication failures return `401 Unauthorized` or redirect to `/Account/Login`.
   - Missing records return `404 Not Found`.
   - Unhandled exceptions are logged with standard ASP.NET Core exception handlers.
