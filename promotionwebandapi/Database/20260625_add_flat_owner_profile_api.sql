SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_FlatOwner_GetProfile
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Role NVARCHAR(20);

    SELECT @Role = NULLIF(LTRIM(RTRIM(Role)), N'')
    FROM dbo.Users
    WHERE Id = @UserId;

    IF @@ROWCOUNT = 0
    BEGIN
        THROW 51050, N'Flat owner was not found.', 1;
    END;

    IF LOWER(COALESCE(@Role, N'')) NOT IN
       (N'owner', N'propertyowner', N'property owner', N'flat owner')
    BEGIN
        THROW 51051, N'The requested user is not a flat owner.', 1;
    END;

    DECLARE @BangladeshNow DATETIME2 = DATEADD(HOUR, 6, SYSUTCDATETIME());
    DECLARE @PaymentMonth CHAR(7) = CONVERT(CHAR(7), @BangladeshNow, 126);

    ;WITH PostSummary AS
    (
        SELECT
            COUNT_BIG(1) AS TotalPosts,
            SUM(CASE WHEN LOWER(Status) IN (N'active', N'published') THEN 1 ELSE 0 END)
                AS ActivePosts
        FROM dbo.OwnerPosts
        WHERE OwnerId = CONVERT(NVARCHAR(36), @UserId)
    ),
    CurrentPayment AS
    (
        SELECT TOP (1)
            Status
        FROM dbo.MonthlyPayments
        WHERE UserId = CONVERT(NVARCHAR(36), @UserId)
          AND MonthYear = @PaymentMonth
        ORDER BY
            CASE Status
                WHEN N'success' THEN 1
                WHEN N'pending' THEN 2
                WHEN N'failed' THEN 3
                WHEN N'cancelled' THEN 4
                ELSE 5
            END,
            UpdatedOn DESC,
            Id DESC
    )
    SELECT
        CONVERT(NVARCHAR(36), u.Id) AS UserId,
        u.FullName,
        u.PhoneNumber,
        N'owner' AS Role,
        u.IsPhoneVerified,
        u.CreatedAt,
        u.UpdatedAt,
        CONVERT(INT, COALESCE(ps.TotalPosts, 0)) AS TotalPosts,
        CONVERT(INT, COALESCE(ps.ActivePosts, 0)) AS ActivePosts,
        @PaymentMonth AS PaymentMonth,
        CASE
            WHEN cp.Status = N'success' THEN N'paid'
            WHEN cp.Status = N'pending' THEN N'pending'
            ELSE N'unpaid'
        END AS PaymentStatus,
        CONVERT(BIT, CASE WHEN cp.Status = N'success' THEN 1 ELSE 0 END)
            AS AccessAllowed
    FROM dbo.Users AS u
    CROSS JOIN PostSummary AS ps
    LEFT JOIN CurrentPayment AS cp ON 1 = 1
    WHERE u.Id = @UserId;
END;
GO

-- Example:
-- EXEC dbo.sp_FlatOwner_GetProfile
--     @UserId = '00000000-0000-0000-0000-000000000000';
