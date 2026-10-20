using System.Data.Common;
using Dapper;
using Microsoft.Data.SqlClient;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class TenantTutorService : ITenantTutorService
{
    private const int DefaultPage = 1;
    private const int DefaultLimit = 50;
    private const int MaxLimit = 100;
    private const int MaxShortTextLength = 100;
    private const int MaxNameLength = 150;
    private const int MaxLocalizedShortLength = 150;
    private const int MaxDescriptionLength = 1000;
    private const int MaxRemarksLength = 500;
    private const string FulfillmentNotGot = "not_got";
    private const string FulfillmentGot = "got";
    private const string TutorType = "tutor";
    private const string RequestType = "request";
    private const string DefaultRating = "5.0";
    private const string TutorRoleBn =
        "\u09b6\u09bf\u0995\u09cd\u09b7\u0995 \u09aa\u09cb\u09b8\u09cd\u099f";
    private const string RequestRoleBn =
        "\u09b6\u09bf\u0995\u09cd\u09b7\u0995 \u09a6\u09b0\u0995\u09be\u09b0";
    private const string TutorBadgeBn =
        "\u09b6\u09bf\u0995\u09cd\u09b7\u0995";
    private const string RequestBadgeBn =
        "\u0985\u09a8\u09c1\u09b0\u09cb\u09a7";

    private readonly SqlConnectionFactory _connectionFactory;

    public TenantTutorService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<TenantTutorPostListResponse> GetPostsAsync(
        string? tenantId = null,
        string? type = null,
        string? subject = null,
        string? area = null,
        bool verifiedOnly = false,
        int page = DefaultPage,
        int limit = DefaultLimit,
        CancellationToken cancellationToken = default)
    {
        var normalizedTenantId = EmptyToNull(TrimOrEmpty(tenantId));
        ValidateOptionalText(normalizedTenantId, "Tenant id", MaxShortTextLength);
        var normalizedType = NormalizeOptionalType(type);
        var normalizedSubject = NormalizeOptionalFilter(subject, "Subject");
        var normalizedArea = NormalizeOptionalFilter(area, "Area");
        var normalizedPage = page <= 0 ? DefaultPage : page;
        var normalizedLimit = limit <= 0
            ? DefaultLimit
            : Math.Min(limit, MaxLimit);
        var offset = (normalizedPage - 1) * normalizedLimit;
        var fetchLimit = normalizedLimit + 1;

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var rows = (await connection.QueryAsync<TenantTutorPostRow>(
            new CommandDefinition(
                """
                SELECT
                    Id,
                    TenantId,
                    PostType,
                    Name,
                    RoleBn,
                    RoleEn,
                    SubjectBn,
                    SubjectEn,
                    AreaBn,
                    AreaEn,
                    PriceBn,
                    PriceEn,
                    AvailabilityBn,
                    AvailabilityEn,
                    BadgeBn,
                    BadgeEn,
                    Rating,
                    CAST('' AS nvarchar(50)) AS Phone,
                    DescriptionBn,
                    DescriptionEn,
                    ExperienceBn,
                    ExperienceEn,
                    FulfillmentStatus,
                    Remarks,
                    IsVerified AS Verified,
                    CreatedAt,
                    UpdatedAt
                FROM dbo.TenantTutorPosts
                WHERE (@TenantId IS NULL OR TenantId = @TenantId)
                  AND (@PostType IS NULL OR PostType = @PostType)
                  AND
                  (
                      @Subject IS NULL
                      OR LOWER(SubjectBn) = @Subject
                      OR LOWER(SubjectEn) = @Subject
                  )
                  AND
                  (
                      @Area IS NULL
                      OR LOWER(AreaBn) = @Area
                      OR LOWER(AreaEn) = @Area
                  )
                  AND (@VerifiedOnly = 0 OR IsVerified = 1)
                ORDER BY CreatedAt DESC, Id DESC
                OFFSET @Offset ROWS FETCH NEXT @FetchLimit ROWS ONLY;
                """,
                new
                {
                    TenantId = normalizedTenantId,
                    PostType = normalizedType,
                    Subject = normalizedSubject,
                    Area = normalizedArea,
                    VerifiedOnly = verifiedOnly,
                    Offset = offset,
                    FetchLimit = fetchLimit,
                },
                cancellationToken: cancellationToken))).ToList();

        var hasMore = rows.Count > normalizedLimit;

        return new TenantTutorPostListResponse
        {
            Posts = rows
                .Take(normalizedLimit)
                .Select(ToDto)
                .ToList(),
            Page = normalizedPage,
            HasMore = hasMore,
        };
    }

    public async Task<CreateTenantTutorPostResponse> CreatePostAsync(
        CreateTenantTutorPostRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var normalizedRequest = NormalizeRequest(request);
        ValidateRequest(normalizedRequest);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        try
        {
            var postId = await GeneratePostIdAsync(
                connection,
                transaction,
                normalizedRequest.Type,
                cancellationToken);
            var now = DateTime.UtcNow;

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    INSERT INTO dbo.TenantTutorPosts
                    (
                        Id,
                        TenantId,
                        PostType,
                        Name,
                        RoleBn,
                        RoleEn,
                        SubjectBn,
                        SubjectEn,
                        AreaBn,
                        AreaEn,
                        PriceBn,
                        PriceEn,
                        AvailabilityBn,
                        AvailabilityEn,
                        BadgeBn,
                        BadgeEn,
                        Rating,
                        Phone,
                        DescriptionBn,
                        DescriptionEn,
                        ExperienceBn,
                        ExperienceEn,
                        FulfillmentStatus,
                        Remarks,
                        IsVerified,
                        CreatedAt,
                        UpdatedAt
                    )
                    VALUES
                    (
                        @Id,
                        @TenantId,
                        @PostType,
                        @Name,
                        @RoleBn,
                        @RoleEn,
                        @SubjectBn,
                        @SubjectEn,
                        @AreaBn,
                        @AreaEn,
                        @PriceBn,
                        @PriceEn,
                        @AvailabilityBn,
                        @AvailabilityEn,
                        @BadgeBn,
                        @BadgeEn,
                        @Rating,
                        @Phone,
                        @DescriptionBn,
                        @DescriptionEn,
                        @ExperienceBn,
                        @ExperienceEn,
                        @FulfillmentStatus,
                        @Remarks,
                        @IsVerified,
                        @Now,
                        @Now
                    );
                    """,
                    new
                    {
                        Id = postId,
                        normalizedRequest.TenantId,
                        PostType = normalizedRequest.Type,
                        normalizedRequest.Name,
                        RoleBn = normalizedRequest.Role.Bn,
                        RoleEn = normalizedRequest.Role.En,
                        SubjectBn = normalizedRequest.Subject.Bn,
                        SubjectEn = normalizedRequest.Subject.En,
                        AreaBn = normalizedRequest.Area.Bn,
                        AreaEn = normalizedRequest.Area.En,
                        PriceBn = normalizedRequest.Price.Bn,
                        PriceEn = normalizedRequest.Price.En,
                        AvailabilityBn = normalizedRequest.Availability.Bn,
                        AvailabilityEn = normalizedRequest.Availability.En,
                        BadgeBn = normalizedRequest.Badge.Bn,
                        BadgeEn = normalizedRequest.Badge.En,
                        normalizedRequest.Rating,
                        normalizedRequest.Phone,
                        DescriptionBn = normalizedRequest.Description.Bn,
                        DescriptionEn = normalizedRequest.Description.En,
                        ExperienceBn = normalizedRequest.Experience.Bn,
                        ExperienceEn = normalizedRequest.Experience.En,
                        normalizedRequest.FulfillmentStatus,
                        Remarks = EmptyToNull(normalizedRequest.Remarks),
                        IsVerified = normalizedRequest.Verified,
                        Now = now,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    INSERT INTO dbo.Activities (Title, Subtitle, TimeLabel)
                    VALUES (@Title, @Subtitle, 'Today');
                    """,
                    new
                    {
                        Title = "Tenant tutor post created",
                        Subtitle =
                            $"{normalizedRequest.Name} created a {normalizedRequest.Type} post for {normalizedRequest.Subject.En}.",
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            await transaction.CommitAsync(cancellationToken);

            return new CreateTenantTutorPostResponse
            {
                Message = "Tutor post created successfully.",
                Post = new TenantTutorCreatedPostDto
                {
                    Id = postId,
                    Type = normalizedRequest.Type,
                    Name = normalizedRequest.Name,
                },
            };
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    private static async Task<string> GeneratePostIdAsync(
        SqlConnection connection,
        DbTransaction transaction,
        string postType,
        CancellationToken cancellationToken)
    {
        var nextNumericId = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT
                    ISNULL(
                        MAX(TRY_CONVERT(int, SUBSTRING(Id, LEN(@Prefix) + 2, LEN(Id)))),
                        0) + 1
                FROM dbo.TenantTutorPosts WITH (UPDLOCK, HOLDLOCK)
                WHERE Id LIKE @Prefix + '-%';
                """,
                new { Prefix = postType },
                transaction: transaction,
                cancellationToken: cancellationToken));

        return $"{postType}-{nextNumericId}";
    }

    private static NormalizedTenantTutorPostRequest NormalizeRequest(
        CreateTenantTutorPostRequest request)
    {
        var postType = FirstNonEmpty(request.Type, request.PostType)
            .ToLowerInvariant();
        var role = NormalizeLocalizedText(request.Role);
        var subject = NormalizeLocalizedText(
            request.Subject,
            request.SubjectBn,
            request.SubjectEn);
        var area = NormalizeArea(request.Area, request.Location);
        var price = NormalizePrice(request.Price, request.Fee);
        var availability = NormalizeLocalizedText(request.Availability);
        var description = NormalizeLocalizedText(request.Description);
        var experience = NormalizeLocalizedText(request.Experience);

        if (role.Bn.Length == 0 && role.En.Length == 0)
        {
            role = GetDefaultRole(postType);
        }

        return new NormalizedTenantTutorPostRequest
        {
            TenantId = TrimOrEmpty(request.TenantId),
            Type = postType,
            Name = TrimOrEmpty(request.Name),
            Role = role,
            Subject = subject,
            Area = area,
            Price = price,
            Availability = availability,
            Badge = GetDefaultBadge(postType),
            Rating = FirstNonEmpty(request.Rating, DefaultRating),
            Phone = FirstNonEmpty(request.Phone, request.ContactNumber),
            Description = description,
            Experience = experience,
            FulfillmentStatus = NormalizeFulfillmentStatus(
                request.FulfillmentStatus),
            Remarks = TrimOrEmpty(request.Remarks),
            Verified = request.Verified ?? true,
        };
    }

    private static void ValidateRequest(NormalizedTenantTutorPostRequest request)
    {
        ValidateRequiredText(request.TenantId, "Tenant id", MaxShortTextLength);
        ValidatePostType(request.Type);
        ValidateRequiredText(request.Name, "Name", MaxNameLength, minimumLength: 2);
        ValidateLocalizedRequired(request.Role, "Role", MaxLocalizedShortLength);
        ValidateLocalizedRequired(request.Subject, "Subject", MaxLocalizedShortLength);
        ValidateLocalizedRequired(request.Area, "Area", MaxLocalizedShortLength);
        ValidateLocalizedOptional(request.Price, "Price", MaxLocalizedShortLength);
        ValidateLocalizedOptional(
            request.Availability,
            "Availability",
            MaxLocalizedShortLength);
        ValidateLocalizedRequired(
            request.Description,
            "Description",
            MaxDescriptionLength,
            minimumLength: 3);
        ValidateLocalizedOptional(
            request.Experience,
            "Experience",
            MaxLocalizedShortLength);
        ValidateLocalizedRequired(request.Badge, "Badge", MaxLocalizedShortLength);
        ValidateRequiredText(request.Rating, "Rating", 20);
        ValidateFulfillmentStatus(request.FulfillmentStatus);
        ValidateOptionalText(request.Remarks, "Remarks", MaxRemarksLength);

        var phoneDigits = NormalizeDigits(request.Phone);
        if (phoneDigits.Length < 10 || phoneDigits.Length > 15)
        {
            throw new TenantTutorValidationException(
                "Phone must contain 10 to 15 digits.");
        }
    }

    private static string? NormalizeOptionalType(string? type)
    {
        var normalizedType = EmptyToNull(TrimOrEmpty(type).ToLowerInvariant());
        if (normalizedType is not null)
        {
            ValidatePostType(normalizedType);
        }

        return normalizedType;
    }

    private static string? NormalizeOptionalFilter(
        string? value,
        string fieldName)
    {
        var normalizedValue = EmptyToNull(TrimOrEmpty(value).ToLowerInvariant());
        ValidateOptionalText(normalizedValue, fieldName, MaxLocalizedShortLength);
        return normalizedValue;
    }

    private static void ValidatePostType(string postType)
    {
        if (postType is not TutorType and not RequestType)
        {
            throw new TenantTutorValidationException(
                "Type must be either 'tutor' or 'request'.");
        }
    }

    private static string NormalizeFulfillmentStatus(string? value)
    {
        var normalized = TrimOrEmpty(value).ToLowerInvariant()
            .Replace("-", "_")
            .Replace(" ", "_");

        return normalized switch
        {
            "got" or "found" or "matched" or "yes" => FulfillmentGot,
            _ => FulfillmentNotGot,
        };
    }

    private static void ValidateFulfillmentStatus(string value)
    {
        if (value is not FulfillmentNotGot and not FulfillmentGot)
        {
            throw new TenantTutorValidationException(
                "Fulfillment status must be either 'got' or 'not_got'.");
        }
    }

    private static void ValidateLocalizedRequired(
        TenantTutorLocalizedTextDto value,
        string fieldName,
        int maximumLength,
        int minimumLength = 1)
    {
        ValidateRequiredText(
            value.Bn,
            $"{fieldName} bn",
            maximumLength,
            minimumLength);
        ValidateRequiredText(
            value.En,
            $"{fieldName} en",
            maximumLength,
            minimumLength);
    }

    private static void ValidateLocalizedOptional(
        TenantTutorLocalizedTextDto value,
        string fieldName,
        int maximumLength)
    {
        ValidateOptionalText(value.Bn, $"{fieldName} bn", maximumLength);
        ValidateOptionalText(value.En, $"{fieldName} en", maximumLength);
    }

    private static void ValidateRequiredText(
        string value,
        string fieldName,
        int maximumLength,
        int minimumLength = 1)
    {
        if (value.Length < minimumLength)
        {
            throw new TenantTutorValidationException(
                $"{fieldName} must contain at least {minimumLength} character(s).");
        }

        if (value.Length > maximumLength)
        {
            throw new TenantTutorValidationException(
                $"{fieldName} cannot exceed {maximumLength} characters.");
        }
    }

    private static void ValidateOptionalText(
        string? value,
        string fieldName,
        int maximumLength)
    {
        if (value is not null && value.Length > maximumLength)
        {
            throw new TenantTutorValidationException(
                $"{fieldName} cannot exceed {maximumLength} characters.");
        }
    }

    private static TenantTutorPostDto ToDto(TenantTutorPostRow row)
    {
        return new TenantTutorPostDto
        {
            Id = row.Id,
            Type = row.PostType,
            Name = row.Name,
            Role = new TenantTutorLocalizedTextDto
            {
                Bn = row.RoleBn,
                En = row.RoleEn,
            },
            Subject = new TenantTutorLocalizedTextDto
            {
                Bn = row.SubjectBn,
                En = row.SubjectEn,
            },
            Area = new TenantTutorLocalizedTextDto
            {
                Bn = row.AreaBn,
                En = row.AreaEn,
            },
            Price = new TenantTutorLocalizedTextDto
            {
                Bn = row.PriceBn,
                En = row.PriceEn,
            },
            Availability = new TenantTutorLocalizedTextDto
            {
                Bn = row.AvailabilityBn,
                En = row.AvailabilityEn,
            },
            Badge = new TenantTutorLocalizedTextDto
            {
                Bn = row.BadgeBn,
                En = row.BadgeEn,
            },
            Rating = row.Rating,
            Phone = row.Phone,
            Description = new TenantTutorLocalizedTextDto
            {
                Bn = row.DescriptionBn,
                En = row.DescriptionEn,
            },
            Experience = new TenantTutorLocalizedTextDto
            {
                Bn = row.ExperienceBn,
                En = row.ExperienceEn,
            },
            FulfillmentStatus = row.FulfillmentStatus,
            Remarks = row.Remarks ?? string.Empty,
            Verified = row.Verified,
        };
    }

    private static TenantTutorLocalizedTextDto NormalizeLocalizedText(
        TenantTutorLocalizedTextDto? value,
        string? explicitBn = null,
        string? explicitEn = null)
    {
        var bn = FirstNonEmpty(explicitBn, value?.Bn, value?.En);
        var en = FirstNonEmpty(explicitEn, value?.En, value?.Bn);

        if (bn.Length == 0)
        {
            bn = en;
        }

        if (en.Length == 0)
        {
            en = bn;
        }

        return new TenantTutorLocalizedTextDto
        {
            Bn = bn,
            En = en,
        };
    }

    private static TenantTutorLocalizedTextDto NormalizeArea(
        TenantTutorLocalizedTextDto? area,
        TenantTutorLocationDto? location)
    {
        var bn = FirstNonEmpty(
            area?.Bn,
            location?.Bn,
            location?.Label,
            area?.En,
            location?.En);
        var en = FirstNonEmpty(
            area?.En,
            location?.En,
            location?.Label,
            area?.Bn,
            location?.Bn);

        return new TenantTutorLocalizedTextDto
        {
            Bn = bn,
            En = en,
        };
    }

    private static TenantTutorLocalizedTextDto NormalizePrice(
        TenantTutorLocalizedTextDto? price,
        TenantTutorLocalizedTextDto? fee)
    {
        var bn = FirstNonEmpty(price?.Bn, fee?.Bn, price?.En, fee?.En);
        var en = FirstNonEmpty(price?.En, fee?.En, price?.Bn, fee?.Bn);

        return new TenantTutorLocalizedTextDto
        {
            Bn = bn,
            En = en,
        };
    }

    private static TenantTutorLocalizedTextDto GetDefaultRole(string postType)
    {
        return string.Equals(postType, RequestType, StringComparison.Ordinal)
            ? new TenantTutorLocalizedTextDto
            {
                Bn = RequestRoleBn,
                En = "Tutor request",
            }
            : new TenantTutorLocalizedTextDto
            {
                Bn = TutorRoleBn,
                En = "Tutor post",
            };
    }

    private static TenantTutorLocalizedTextDto GetDefaultBadge(string postType)
    {
        return string.Equals(postType, RequestType, StringComparison.Ordinal)
            ? new TenantTutorLocalizedTextDto
            {
                Bn = RequestBadgeBn,
                En = "Request",
            }
            : new TenantTutorLocalizedTextDto
            {
                Bn = TutorBadgeBn,
                En = "Tutor",
            };
    }

    private static string FirstNonEmpty(params string?[] values)
    {
        foreach (var value in values)
        {
            var trimmedValue = TrimOrEmpty(value);
            if (trimmedValue.Length > 0)
            {
                return trimmedValue;
            }
        }

        return string.Empty;
    }

    private static string TrimOrEmpty(string? value)
    {
        return value?.Trim() ?? string.Empty;
    }

    private static string? EmptyToNull(string value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value;
    }

    private static string NormalizeDigits(string value)
    {
        return new string(value.Where(char.IsDigit).ToArray());
    }

    private sealed class TenantTutorPostRow
    {
        public string Id { get; init; } = string.Empty;
        public string TenantId { get; init; } = string.Empty;
        public string PostType { get; init; } = string.Empty;
        public string Name { get; init; } = string.Empty;
        public string RoleBn { get; init; } = string.Empty;
        public string RoleEn { get; init; } = string.Empty;
        public string SubjectBn { get; init; } = string.Empty;
        public string SubjectEn { get; init; } = string.Empty;
        public string AreaBn { get; init; } = string.Empty;
        public string AreaEn { get; init; } = string.Empty;
        public string PriceBn { get; init; } = string.Empty;
        public string PriceEn { get; init; } = string.Empty;
        public string AvailabilityBn { get; init; } = string.Empty;
        public string AvailabilityEn { get; init; } = string.Empty;
        public string BadgeBn { get; init; } = string.Empty;
        public string BadgeEn { get; init; } = string.Empty;
        public string Rating { get; init; } = string.Empty;
        public string Phone { get; init; } = string.Empty;
        public string DescriptionBn { get; init; } = string.Empty;
        public string DescriptionEn { get; init; } = string.Empty;
        public string ExperienceBn { get; init; } = string.Empty;
        public string ExperienceEn { get; init; } = string.Empty;
        public string FulfillmentStatus { get; init; } = string.Empty;
        public string? Remarks { get; init; }
        public bool Verified { get; init; }
        public DateTime CreatedAt { get; init; }
        public DateTime UpdatedAt { get; init; }
    }

    private sealed class NormalizedTenantTutorPostRequest
    {
        public string TenantId { get; init; } = string.Empty;
        public string Type { get; init; } = string.Empty;
        public string Name { get; init; } = string.Empty;
        public TenantTutorLocalizedTextDto Role { get; init; } = new();
        public TenantTutorLocalizedTextDto Subject { get; init; } = new();
        public TenantTutorLocalizedTextDto Area { get; init; } = new();
        public TenantTutorLocalizedTextDto Price { get; init; } = new();
        public TenantTutorLocalizedTextDto Availability { get; init; } = new();
        public TenantTutorLocalizedTextDto Badge { get; init; } = new();
        public string Rating { get; init; } = string.Empty;
        public string Phone { get; init; } = string.Empty;
        public TenantTutorLocalizedTextDto Description { get; init; } = new();
        public TenantTutorLocalizedTextDto Experience { get; init; } = new();
        public string FulfillmentStatus { get; init; } = string.Empty;
        public string Remarks { get; init; } = string.Empty;
        public bool Verified { get; init; }
    }
}

public sealed class TenantTutorValidationException : Exception
{
    public TenantTutorValidationException(string message)
        : base(message)
    {
    }
}
