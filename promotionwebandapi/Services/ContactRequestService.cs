using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class ContactRequestService : IContactRequestService
{
    private readonly SqlConnectionFactory _connectionFactory;

    public ContactRequestService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<ContactAccessStatusResponse> CreateRequestAsync(
        CreateContactAccessRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        if (string.IsNullOrWhiteSpace(request.RequesterUserId))
        {
            throw new ArgumentException("Requester user ID is required.", nameof(request));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        string postOwnerUserId = string.Empty;
        if (string.Equals(request.PostType, "TutorPost", StringComparison.OrdinalIgnoreCase))
        {
            var tutorOwner = await connection.QuerySingleOrDefaultAsync<string>(
                new CommandDefinition(
                    "SELECT TOP 1 TenantId FROM dbo.TenantTutorPosts WHERE Id = CONVERT(NVARCHAR(50), @PostId)",
                    new { request.PostId },
                    cancellationToken: cancellationToken));

            postOwnerUserId = tutorOwner ?? string.Empty;
        }
        else
        {
            var generalOwner = await connection.QuerySingleOrDefaultAsync<string>(
                new CommandDefinition(
                    "SELECT TOP 1 UserId FROM dbo.GeneralPosts WHERE Id = @PostId",
                    new { request.PostId },
                    cancellationToken: cancellationToken));

            postOwnerUserId = generalOwner ?? string.Empty;
        }

        if (string.IsNullOrWhiteSpace(postOwnerUserId))
        {
            throw new InvalidOperationException("Post was not found or owner information is missing.");
        }

        if (string.Equals(request.RequesterUserId, postOwnerUserId, StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("You cannot request contact access for your own post.");
        }

        // Check if an existing request exists
        var existing = await connection.QuerySingleOrDefaultAsync<ContactRequestStatusRow>(
            new CommandDefinition(
                """
                SELECT TOP 1 Id, Status
                FROM dbo.ContactAccessRequests
                WHERE RequesterUserId = @RequesterUserId
                  AND PostType = @PostType
                  AND PostId = @PostId
                ORDER BY CreatedAt DESC
                """,
                new
                {
                    request.RequesterUserId,
                    request.PostType,
                    request.PostId
                },
                cancellationToken: cancellationToken));

        if (existing is not null)
        {
            if (string.Equals(existing.Status, "approved", StringComparison.OrdinalIgnoreCase))
            {
                return await GetStatusAsync(request.RequesterUserId, request.PostType, request.PostId, cancellationToken);
            }

            if (string.Equals(existing.Status, "pending", StringComparison.OrdinalIgnoreCase))
            {
                return new ContactAccessStatusResponse
                {
                    RequestId = existing.Id,
                    Status = "pending",
                    IsApproved = false,
                    Message = "Your contact access request is pending administrator review."
                };
            }
        }

        const string insertSql = """
            INSERT INTO dbo.ContactAccessRequests
            (
                RequesterUserId,
                PostType,
                PostId,
                PostOwnerUserId,
                Purpose,
                Status,
                CreatedAt,
                UpdatedAt
            )
            VALUES
            (
                @RequesterUserId,
                @PostType,
                @PostId,
                @PostOwnerUserId,
                @Purpose,
                'pending',
                SYSUTCDATETIME(),
                SYSUTCDATETIME()
            );
            SELECT CAST(SCOPE_IDENTITY() AS int);
            """;

        var newId = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                insertSql,
                new
                {
                    request.RequesterUserId,
                    request.PostType,
                    request.PostId,
                    postOwnerUserId,
                    request.Purpose
                },
                cancellationToken: cancellationToken));

        return new ContactAccessStatusResponse
        {
            RequestId = newId,
            Status = "pending",
            IsApproved = false,
            Message = "Contact access request submitted successfully. Awaiting admin review."
        };
    }

    public async Task<ContactAccessStatusResponse> GetStatusAsync(
        string requesterUserId,
        string postType,
        int postId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(requesterUserId))
        {
            return new ContactAccessStatusResponse { Status = "none", IsApproved = false };
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var requestRow = await connection.QuerySingleOrDefaultAsync<ContactRequestDetailRow>(
            new CommandDefinition(
                """
                SELECT TOP 1 Id, PostOwnerUserId, Status
                FROM dbo.ContactAccessRequests
                WHERE RequesterUserId = @requesterUserId
                  AND PostType = @postType
                  AND PostId = @postId
                ORDER BY CreatedAt DESC
                """,
                new { requesterUserId, postType, postId },
                cancellationToken: cancellationToken));

        if (requestRow is null)
        {
            return new ContactAccessStatusResponse { Status = "none", IsApproved = false };
        }

        if (string.Equals(requestRow.Status, "approved", StringComparison.OrdinalIgnoreCase))
        {
            string? revealedPhone = null;

            if (string.Equals(postType, "TutorPost", StringComparison.OrdinalIgnoreCase))
            {
                revealedPhone = await connection.QuerySingleOrDefaultAsync<string>(
                    new CommandDefinition(
                        "SELECT TOP 1 Phone FROM dbo.TenantTutorPosts WHERE Id = @postId",
                        new { postId },
                        cancellationToken: cancellationToken));
            }
            else
            {
                revealedPhone = await connection.QuerySingleOrDefaultAsync<string>(
                    new CommandDefinition(
                        """
                        SELECT TOP 1 PhoneNumber
                        FROM dbo.Users
                        WHERE Id = TRY_CAST(@PostOwnerUserId AS uniqueidentifier)
                           OR PhoneNumber = @PostOwnerUserId
                        """,
                        new { requestRow.PostOwnerUserId },
                        cancellationToken: cancellationToken));
            }

            return new ContactAccessStatusResponse
            {
                RequestId = requestRow.Id,
                Status = "approved",
                IsApproved = true,
                RevealedPhoneNumber = revealedPhone,
                Message = "Contact access approved."
            };
        }

        return new ContactAccessStatusResponse
        {
            RequestId = requestRow.Id,
            Status = requestRow.Status,
            IsApproved = false,
            Message = string.Equals(requestRow.Status, "rejected", StringComparison.OrdinalIgnoreCase)
                ? "Contact access request was rejected."
                : "Contact access request is pending administrator review."
        };
    }

    public async Task<IReadOnlyList<ContactAccessRequestDto>> GetAllRequestsAsync(
        string? statusFilter = null,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        const string sql = """
            SELECT
                car.Id,
                car.RequesterUserId,
                ISNULL(uReq.FullName, car.RequesterUserId) AS RequesterName,
                ISNULL(uReq.PhoneNumber, '') AS RequesterPhone,
                car.PostType,
                car.PostId,
                CASE
                    WHEN car.PostType = 'TutorPost' THEN ISNULL(tp.SubjectEn, 'Tutor Post')
                    ELSE ISNULL(gp.Title, 'General Post')
                END AS PostTitle,
                CASE
                    WHEN car.PostType = 'TutorPost' THEN ISNULL(tp.PostType, 'Tutor')
                    ELSE ISNULL(gp.Category, 'Rental')
                END AS PostCategory,
                car.PostOwnerUserId,
                ISNULL(uOwner.FullName, car.PostOwnerUserId) AS PostOwnerName,
                car.Purpose,
                car.Status,
                car.RejectionReason,
                car.CreatedAt,
                car.ReviewedAt
            FROM dbo.ContactAccessRequests car
            LEFT JOIN dbo.Users uReq
                ON uReq.Id = TRY_CAST(car.RequesterUserId AS uniqueidentifier)
                OR uReq.PhoneNumber = car.RequesterUserId
            LEFT JOIN dbo.Users uOwner
                ON uOwner.Id = TRY_CAST(car.PostOwnerUserId AS uniqueidentifier)
                OR uOwner.PhoneNumber = car.PostOwnerUserId
            LEFT JOIN dbo.GeneralPosts gp
                ON gp.Id = car.PostId AND car.PostType != 'TutorPost'
            LEFT JOIN dbo.TenantTutorPosts tp
                ON tp.Id = CONVERT(NVARCHAR(50), car.PostId) AND car.PostType = 'TutorPost'
            WHERE (@statusFilter IS NULL OR car.Status = @statusFilter)
            ORDER BY car.CreatedAt DESC;
            """;

        var rows = await connection.QueryAsync<ContactAccessRequestDto>(
            new CommandDefinition(
                sql,
                new { statusFilter },
                cancellationToken: cancellationToken));

        return rows.AsList();
    }

    public async Task<bool> ReviewRequestAsync(
        int requestId,
        bool approve,
        string adminId,
        string? reason = null,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var newStatus = approve ? "approved" : "rejected";

        var rowsAffected = await connection.ExecuteAsync(
            new CommandDefinition(
                """
                UPDATE dbo.ContactAccessRequests
                SET Status = @newStatus,
                    ReviewedByAdminId = @adminId,
                    ReviewedAt = SYSUTCDATETIME(),
                    RejectionReason = @reason,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE Id = @requestId
                """,
                new
                {
                    newStatus,
                    adminId,
                    reason,
                    requestId
                },
                cancellationToken: cancellationToken));

        return rowsAffected > 0;
    }

    private sealed class ContactRequestStatusRow
    {
        public int Id { get; set; }
        public string Status { get; set; } = string.Empty;
    }

    private sealed class ContactRequestDetailRow
    {
        public int Id { get; set; }
        public string PostOwnerUserId { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
    }
}
