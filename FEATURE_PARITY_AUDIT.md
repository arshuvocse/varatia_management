# Feature Parity Audit: Flutter Mobile Application vs. Web Admin Panel

**Repository:** `Varatia_management`  
**Components Audited:** Flutter Mobile App (`varatia_management_apps`), ASP.NET Core Backend & Web Admin (`promotionwebandapi`), Database (`SmartBazarDbmssql` / `dbo.*`).  
**Audit Date:** 2026-10-20  
**Audit Status:** Complete & Verified  

---

## 1. Executive Summary

This audit assesses the functional parity between the end-user Flutter mobile application and the web-based Admin Panel. The primary objective is to verify that every user-facing record, request, post, entitlement, and workflow initiated in the Flutter application has an administrative counterpart in the web Admin Panel for monitoring, moderation, approval, verification, reporting, and management.

### Status Key:
- **A**: Available and working in Flutter and Admin Panel
- **B**: Available in Flutter but missing from Admin Panel *(Remediated in this audit cycle)*
- **C**: Present in both but broken in one or both
- **D**: Present in Admin Panel but missing from Flutter
- **E**: Available in the UI but not connected to the backend
- **F**: Connected to the backend but not persisted correctly
- **G**: Blocked by a role or permission configuration
- **H**: Not applicable to Admin Panel (Intentionally user-private / device-local)

---

## 2. Feature Parity Matrix

| Feature | Flutter Screen | Admin Page | API Endpoint | Database Entity | Status | Evidence | Required Fix / Remediation |
|---|---|---|---|---|---|---|---|
| **User Registration Fee Configuration** | `RoleSelectionScreen`, `RegistrationPaymentPage` | `/Account/VaratiaManagement?tab=settings` | `GET /api/company/varatia-management`, `POST /Account/UpdateRegistrationFee` | `dbo.tbl_CompanySettings` (`RegistrationFee`, `IsRegistrationFeeActive`) | **A** | Dynamic fee loaded from DB; Admin can toggle active and change fee amount (e.g. ৳50). | None. Working as intended. |
| **User Registration Fee Status & Tracking** | `SplashFlowScreen`, `LoginScreen` | `/Account/VaratiaManagement?tab=users` | `GET /api/users/{id}/registration-status` | `dbo.Users` (`IsRegistrationFeePaid`, `RegistrationFeeTransactionId`, `RegistrationFeePaidAt`) | **A** | Admin sees user phone, registration date, fee payment status, transaction ID, and SSLCommerz trace. | None. Verified in Admin Users tab. |
| **General Rental & Service Posts (Flats, Rooms, Sublet, Mess, Tuition, Sale)** | `GeneralPostComposerPage`, `TenantMarketplaceWelcomePage`, `SocialFeedScreen` | `/Account/VaratiaManagement?tab=generalposts` | `GET/POST /api/general-posts`, `POST /Account/ToggleGeneralPostStatus`, `POST /Account/ToggleGeneralPostVerification`, `POST /Account/DeleteGeneralPost` | `dbo.GeneralPosts` | **A** *(Upgraded from B)* | Flutter users create posts with media, location, amenities. Admin previously lacked a general post moderation tab. Added dedicated tab with filters, moderation toggles, and deletion. | Implemented `generalposts` tab in `VaratiaManagement.cshtml` with status toggle, verification badge toggle, and delete. |
| **User Posting Entitlements & Paid Credits** | `GeneralPostComposerPage`, `EntitlementNoticeDialog` | `/Account/VaratiaManagement?tab=generalposts` | `GET /api/general-posts/entitlement`, `POST /Account/GrantPostingCredits` | `dbo.UserPostingEntitlements` (`FreePostsAllowed`, `FreePostsUsed`, `PaidCreditsBalance`) | **A** *(Upgraded from B)* | Users get 4 free posts. Admin now has a quick grant bar to allocate additional paid credits to any user phone/ID. | Implemented `GrantPostingCredits` action in `AccountController.cs` and `VaratiaAdminService.cs`. |
| **Teach & Learn: Tutor & Tuition Posts** | `TenantTutorTeachLearnPage`, `TenantTutorPostComposerPage` | `/Account/TeachAndLearn` | `GET/POST /api/teach-learn/posts`, `POST /Account/ToggleTutorVerification`, `POST /Account/DeleteTutorPost` | `dbo.TenantTutorPosts` | **A** | Flutter users post tutor/student listings. Admin has dedicated `TeachAndLearn` view with verification toggle, stats KPI cards, and delete actions. | None. Verified in `TeachAndLearn.cshtml` and unit tests. |
| **Teach & Learn: Contact Access Requests** | `TenantTutorTeachLearnPage` | `/Account/TeachAndLearn` | `POST /api/teach-learn/request-contact` | `dbo.ContactAccessRequests` | **A** | Users unlock tutor contact info; audited in Admin. | None. Persisted and displayed. |
| **Subscription & Matchmaking Packages (Tenant/Owner/Tutor/Student)** | `TenantSubscriptionPlanPage`, `OwnerSubscriptionPlanPage` | `/Account/VaratiaManagement?tab=subscriptions` | `GET /api/subscriptions/plans`, `POST /Account/UpdateSubscriptionPlan`, `POST /Account/UpdateSubscriptionStatus` | `dbo.SubscriptionPlans`, `dbo.UserSubscriptions` | **A** | 4 subscription services (find_flat, find_tenant, find_tutor, find_student). Admin can edit fees, delivery days, active toggle, and track fulfillment notes. | None. Fully synchronized with SSLCommerz payment callback. |
| **Property Management (Buildings, Floors, Units)** | `OwnerPropertiesScreen`, `AddPropertyScreen`, `FloorManagementScreen` | `/Account/VaratiaManagement?tab=properties` | `GET /api/properties`, `POST /api/properties` | `dbo.Buildings`, `dbo.Floors`, `dbo.Properties` | **A** | Admin monitors all registered buildings, total units, rented vs available status, and rental dues. | None. Filterable by rented/available in Admin. |
| **Tenant Records & Move-in/Move-out** | `OwnerTenantsScreen`, `AddTenantScreen` | `/Account/VaratiaManagement?tab=tenants` | `GET /api/tenants`, `POST /api/tenants` | `dbo.Tenants`, `dbo.Properties` | **A** | Tenant NID, phone, assigned property/unit, monthly rent, and current due amounts are displayed in Admin. | None. Fully synchronized. |
| **Offline Rent Payments & Receipts** | `PaymentReceiptScreen`, `CollectRentDialog` | `/Account/VaratiaManagement?tab=payments` | `GET /api/payments` | `dbo.RentPayments`, `dbo.Properties` | **A** | Cash and bank rent receipts generated by owners appear in Admin with invoice dates, amounts, and note remarks. | None. Fully functional. |
| **Online Payment Gateway Transactions (SSLCommerz)** | `PaymentCheckoutScreen` | `/Account/VaratiaManagement?tab=sslpayments` | `POST /api/payment/initiate`, `POST /api/payment/sslcommerz/success` | `dbo.MonthlyPayments` | **A** | All registration fees, posting credit purchases, and subscription payments tracked with transaction IDs and validation status. | None. Verified in Admin SSLCommerz tab. |
| **Maintenance & Service Requests** | `TenantServiceRequestsPage`, `ServiceRequestComposer` | `/Account/ServiceRequests` | `GET/POST /api/service-requests`, `POST /Account/UpdateServiceRequestStatus` | `dbo.ServiceRequests` | **A** | Tenants submit plumbing, electrical, or cleaning issues. Admin can triage, assign workers, and update progress status. | None. Working with SQLite store and Admin panel. |
| **Property Expenses & Expense Categories** | `OwnerExpensesScreen`, `AddExpenseDialog` | `/Account/VaratiaManagement` | `GET/POST /api/expenses` | `dbo.Expenses` | **A** | Owners track utility, repair, and operational expenses. | None. Persisted in SQL Server. |
| **Pickup & Moving Service Welcome & Eligibility** | `TenantPickupServiceWelcomePage` | `/Account/ServiceRequests` | Local eligibility rule (3 months) + `/api/service-requests` | `dbo.ServiceRequests` | **A** | 3-month tenant tenure rule enforced in Flutter; resulting logistics requests flow to Admin Service Requests. | None. Verified in Flutter unit tests. |
| **Local App Cache & Session Security** | `EntryFlowScreen`, `SplashScreen` | N/A | Device-local SQLite `app_cache.db` | Local SQLite | **H** | Device-specific token and session caching. Not applicable to Admin Panel. | None. Properly scoped. |

---

## 3. Detailed Parity Status Breakdown

- **Total Features Audited:** 15 distinct functional areas.
- **Available and Working in Both (Status A):** 14 features (100% of required administrative capabilities).
- **Remediated Gaps During This Audit:**
  1. **General Posts & Listings Management:** Added `generalposts` tab, KPI counters, category/status filters, moderation toggle actions, and deletion capability in Admin Panel.
  2. **Posting Entitlements & Credit Allocation:** Added admin capability to allocate paid posting credits directly to any user ID or phone number.
  3. **General Posts Verification Flag:** Added schema self-healing migration for `dbo.GeneralPosts.IsVerified` and verification toggle in Admin.
- **Intentionally User-Only (Status H):** 1 feature (Device-local session cache).
- **Broken / Blocked Features:** 0 remaining.
