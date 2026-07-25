using System.Data.Common;
using System.Globalization;
using Dapper;
using Microsoft.Data.SqlClient;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class TenantAreaService : ITenantAreaService
{
    private const int MaxShortTextLength = 100;
    private const int MaxWardIdLength = 40;
    private const int MaxPostTypeLength = 30;
    private const int MaxDetailsLength = 1000;
    private const int MaxLocationLabelLength = 200;
    private const int MaxPrivacyLength = 30;
    private const int MaxAttachmentFileNameLength = 150;
    private const int MaxAttachmentUrlLength = 500;
    private const int DefaultPage = 1;
    private const int DefaultLimit = 20;
    private const int MaxLimit = 100;
    private const string DefaultWardId = "ward-14";
    private const string BanglaMemberSuffix =
        "\u09b8\u09a6\u09b8\u09cd\u09af";
    private const string DefaultWardTitleBn =
        "\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u09e7\u09ea - \u09ae\u09bf\u09b0\u09aa\u09c1\u09b0";
    private const string DefaultWardRuleBn =
        "\u09b8\u09cd\u09aa\u09cd\u09af\u09be\u09ae \u0995\u09b0\u09be \u09af\u09be\u09ac\u09c7 \u09a8\u09be\u0964";

    private static readonly char[] BanglaDigits =
    {
        '\u09e6',
        '\u09e7',
        '\u09e8',
        '\u09e9',
        '\u09ea',
        '\u09eb',
        '\u09ec',
        '\u09ed',
        '\u09ee',
        '\u09ef',
    };

    private static readonly IReadOnlyList<TenantAreaWardRow> FallbackWards =
        new[]
        {
            new TenantAreaWardRow
            {
                Id = DefaultWardId,
                City = "dncc",
                WardNo = 14,
                TitleBn = DefaultWardTitleBn,
                TitleEn = "Ward 14 - Mirpur",
                Area = "Mirpur-10, Dhaka",
                MemberCount = 2386,
                Verified = true,
                DisplayOrder = 1,
            },
        };

    private readonly SqlConnectionFactory _connectionFactory;

    public TenantAreaService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<TenantAreaHomeResponse> GetHomeAsync(
        string? tenantId,
        CancellationToken cancellationToken = default)
    {
        var normalizedTenantId = NormalizeRequiredText(
            tenantId,
            "Tenant id",
            MaxShortTextLength);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var wards = await QueryWardsAsync(
            connection,
            city: null,
            search: null,
            cancellationToken);
        var activeWardId = await ResolveActiveWardIdAsync(
            connection,
            normalizedTenantId,
            wards,
            cancellationToken);
        var notificationUnreadCount = await GetUnreadNotificationCountAsync(
            connection,
            cancellationToken);
        var wardDtos = wards
            .Select(ward => ToWardDto(
                ward,
                string.Equals(
                    ward.Id,
                    activeWardId,
                    StringComparison.OrdinalIgnoreCase)))
            .ToList();
        var activeWard =
            wardDtos.FirstOrDefault(ward => ward.Selected)
            ?? wardDtos.FirstOrDefault()
            ?? ToWardDto(FallbackWards[0], selected: true);
        var feedPreview = await QueryPostsPageAsync(
            connection,
            activeWard.Id,
            category: null,
            page: 1,
            limit: 5,
            cancellationToken);
        var wardRules = await QueryWardRulesAsync(
            connection,
            activeWard.Id,
            cancellationToken);
        var locationOptions = await QueryLocationOptionsAsync(
            connection,
            normalizedTenantId,
            activeWard.Area,
            cancellationToken);

        return new TenantAreaHomeResponse
        {
            NotificationUnreadCount = notificationUnreadCount,
            ActiveWard = activeWard,
            Wards = wardDtos,
            FeedPreview = feedPreview.Posts,
            WardRules = wardRules,
            LocationOptions = locationOptions,
            EmergencyHelpline = new TenantAreaEmergencyHelplineDto
            {
                Label = "Emergency",
                Phone = "999",
            },
        };
    }

    public async Task<TenantAreaWardsResponse> GetWardsAsync(
        string? tenantId,
        string? city = null,
        string? search = null,
        CancellationToken cancellationToken = default)
    {
        var normalizedTenantId = NormalizeRequiredText(
            tenantId,
            "Tenant id",
            MaxShortTextLength);
        var normalizedCity = EmptyToNull(TrimOrEmpty(city).ToLowerInvariant());
        var normalizedSearch = EmptyToNull(TrimOrEmpty(search).ToLowerInvariant());

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var wards = await QueryWardsAsync(
            connection,
            normalizedCity,
            normalizedSearch,
            cancellationToken);
        var activeWardId = await ResolveActiveWardIdAsync(
            connection,
            normalizedTenantId,
            wards,
            cancellationToken);

        return new TenantAreaWardsResponse
        {
            Wards = wards
                .Select(ward => ToWardDto(
                    ward,
                    string.Equals(
                        ward.Id,
                        activeWardId,
                        StringComparison.OrdinalIgnoreCase)))
                .ToList(),
        };
    }

    public async Task<TenantAreaPostsResponse> GetPostsAsync(
        string? tenantId,
        string? wardId = null,
        string? category = null,
        int page = DefaultPage,
        int limit = DefaultLimit,
        CancellationToken cancellationToken = default)
    {
        var normalizedTenantId = NormalizeRequiredText(
            tenantId,
            "Tenant id",
            MaxShortTextLength);
        var normalizedWardId = EmptyToNull(TrimOrEmpty(wardId));
        var normalizedCategory = EmptyToNull(
            TrimOrEmpty(category).ToLowerInvariant());
        var normalizedPage = page <= 0 ? DefaultPage : page;
        var normalizedLimit = limit <= 0
            ? DefaultLimit
            : Math.Min(limit, MaxLimit);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        if (normalizedWardId is null)
        {
            var wards = await QueryWardsAsync(
                connection,
                city: null,
                search: null,
                cancellationToken);
            normalizedWardId = await ResolveActiveWardIdAsync(
                connection,
                normalizedTenantId,
                wards,
                cancellationToken);
        }

        var result = await QueryPostsPageAsync(
            connection,
            normalizedWardId,
            normalizedCategory,
            normalizedPage,
            normalizedLimit,
            cancellationToken);

        return new TenantAreaPostsResponse
        {
            Posts = result.Posts,
            Page = normalizedPage,
            Limit = normalizedLimit,
            TotalCount = result.TotalCount,
            TotalPages = CalculateTotalPages(result.TotalCount, normalizedLimit),
        };
    }

    public async Task<CreateTenantAreaPostResponse> CreatePostAsync(
        CreateTenantAreaPostRequest request,
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
            var wardExists = await connection.ExecuteScalarAsync<int>(
                new CommandDefinition(
                    """
                    SELECT COUNT(1)
                    FROM dbo.TenantAreaWards
                    WHERE Id = @WardId;
                    """,
                    new { normalizedRequest.WardId },
                    transaction: transaction,
                    cancellationToken: cancellationToken)) > 0;

            if (!wardExists)
            {
                throw new TenantAreaNotFoundException(
                    $"Ward '{normalizedRequest.WardId}' was not found.");
            }

            var postId = await GeneratePostIdAsync(
                connection,
                transaction,
                cancellationToken);
            var now = DateTime.UtcNow;

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    INSERT INTO dbo.TenantAreaPosts
                    (
                        Id,
                        TenantId,
                        WardId,
                        PostType,
                        Details,
                        LocationLabel,
                        Latitude,
                        Longitude,
                        Privacy,
                        CreatedAt,
                        UpdatedAt
                    )
                    VALUES
                    (
                        @Id,
                        @TenantId,
                        @WardId,
                        @PostType,
                        @Details,
                        @LocationLabel,
                        @Latitude,
                        @Longitude,
                        @Privacy,
                        @Now,
                        @Now
                    );
                    """,
                    new
                    {
                        Id = postId,
                        normalizedRequest.TenantId,
                        normalizedRequest.WardId,
                        normalizedRequest.PostType,
                        normalizedRequest.Details,
                        LocationLabel = normalizedRequest.Location.Label,
                        normalizedRequest.Location.Latitude,
                        normalizedRequest.Location.Longitude,
                        normalizedRequest.Privacy,
                        Now = now,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            foreach (var attachment in normalizedRequest.Attachments)
            {
                await connection.ExecuteAsync(
                    new CommandDefinition(
                        """
                        INSERT INTO dbo.TenantAreaPostAttachments
                            (PostId, FileName, Url, DisplayOrder)
                        VALUES
                            (@PostId, @FileName, @Url, @DisplayOrder);
                        """,
                        new
                        {
                            PostId = postId,
                            attachment.FileName,
                            Url = EmptyToNull(attachment.Url),
                            attachment.DisplayOrder,
                        },
                        transaction: transaction,
                        cancellationToken: cancellationToken));
            }

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    INSERT INTO dbo.Activities (Title, Subtitle, TimeLabel)
                    VALUES (@Title, @Subtitle, 'Today');
                    """,
                    new
                    {
                        Title = "Tenant area post created",
                        Subtitle =
                            $"{normalizedRequest.TenantId} posted in {normalizedRequest.WardId}.",
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            await transaction.CommitAsync(cancellationToken);

            return new CreateTenantAreaPostResponse
            {
                Post = ToDto(postId, normalizedRequest, now),
                Message = "Tenant area post created successfully.",
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
        CancellationToken cancellationToken)
    {
        var nextNumericId = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT ISNULL(MAX(TRY_CONVERT(int, SUBSTRING(Id, 11, LEN(Id) - 10))), 0) + 1
                FROM dbo.TenantAreaPosts WITH (UPDLOCK, HOLDLOCK)
                WHERE Id LIKE 'area_post[_]%';
                """,
                transaction: transaction,
                cancellationToken: cancellationToken));

        return $"area_post_{nextNumericId:D6}";
    }

    private static NormalizedTenantAreaPostRequest NormalizeRequest(
        CreateTenantAreaPostRequest request)
    {
        var location = request.Location ?? new TenantAreaPostLocationDto();
        var attachments =
            (request.Attachments ?? Array.Empty<TenantAreaPostAttachmentRequest>())
            .OfType<TenantAreaPostAttachmentRequest>()
            .Select((attachment, index) => new NormalizedTenantAreaPostAttachment
            {
                FileName = TrimOrEmpty(attachment.FileName),
                Url = TrimOrEmpty(attachment.Url),
                DisplayOrder = index + 1,
            })
            .ToList();

        return new NormalizedTenantAreaPostRequest
        {
            TenantId = TrimOrEmpty(request.TenantId),
            WardId = TrimOrEmpty(request.WardId),
            PostType = TrimOrEmpty(request.PostType).ToLowerInvariant(),
            Details = TrimOrEmpty(request.Details),
            Location = new TenantAreaPostLocationDto
            {
                Label = TrimOrEmpty(location.Label),
                Latitude = location.Latitude,
                Longitude = location.Longitude,
            },
            Privacy = TrimOrEmpty(request.Privacy).ToLowerInvariant(),
            Attachments = attachments,
        };
    }

    private static void ValidateRequest(NormalizedTenantAreaPostRequest request)
    {
        ValidateRequiredText(
            request.TenantId,
            "Tenant id",
            MaxShortTextLength);
        ValidateRequiredText(
            request.WardId,
            "Ward id",
            MaxWardIdLength);
        ValidateRequiredText(
            request.PostType,
            "Post type",
            MaxPostTypeLength);
        ValidateRequiredText(
            request.Details,
            "Details",
            MaxDetailsLength,
            minimumLength: 3);
        ValidateRequiredText(
            request.Location.Label,
            "Location label",
            MaxLocationLabelLength,
            minimumLength: 3);
        ValidateCoordinates(
            request.Location.Latitude,
            request.Location.Longitude);
        ValidateRequiredText(
            request.Privacy,
            "Privacy",
            MaxPrivacyLength);

        foreach (var attachment in request.Attachments)
        {
            ValidateRequiredText(
                attachment.FileName,
                "Attachment file name",
                MaxAttachmentFileNameLength);
            ValidateOptionalText(
                attachment.Url,
                "Attachment URL",
                MaxAttachmentUrlLength);

            if (attachment.Url.Length > 0 && !IsHttpUrl(attachment.Url))
            {
                throw new TenantAreaValidationException(
                    "Attachment URL must be a valid HTTP or HTTPS URL.");
            }
        }
    }

    private async Task<IReadOnlyList<TenantAreaWardRow>> QueryWardsAsync(
        SqlConnection connection,
        string? city,
        string? search,
        CancellationToken cancellationToken)
    {
        var searchPattern = search is null ? null : $"%{search}%";
        var rows = (await connection.QueryAsync<TenantAreaWardRow>(
            new CommandDefinition(
                """
                SELECT
                    Id,
                    City,
                    WardNo,
                    TitleBn,
                    TitleEn,
                    Area,
                    MemberCount,
                    IsVerified AS Verified,
                    DisplayOrder
                FROM dbo.TenantAreaWards
                WHERE (@City IS NULL OR LOWER(City) = @City)
                  AND
                  (
                      @SearchPattern IS NULL
                      OR LOWER(Id) LIKE @SearchPattern
                      OR LOWER(TitleEn) LIKE @SearchPattern
                      OR LOWER(Area) LIKE @SearchPattern
                      OR LOWER(TitleBn) LIKE @SearchPattern
                      OR CONVERT(NVARCHAR(20), WardNo) LIKE @SearchPattern
                  )
                ORDER BY DisplayOrder, WardNo, Id;
                """,
                new
                {
                    City = city,
                    SearchPattern = searchPattern,
                },
                cancellationToken: cancellationToken))).ToList();

        return rows.Count > 0
            ? rows
            : FilterFallbackWards(city, search);
    }

    private static IReadOnlyList<TenantAreaWardRow> FilterFallbackWards(
        string? city,
        string? search)
    {
        return FallbackWards
            .Where(ward =>
                city is null
                || string.Equals(ward.City, city, StringComparison.OrdinalIgnoreCase))
            .Where(ward => search is null || IsFallbackWardMatch(ward, search))
            .ToList();
    }

    private static bool IsFallbackWardMatch(TenantAreaWardRow ward, string search)
    {
        return ward.Id.Contains(search, StringComparison.OrdinalIgnoreCase)
            || ward.TitleEn.Contains(search, StringComparison.OrdinalIgnoreCase)
            || ward.TitleBn.Contains(search, StringComparison.OrdinalIgnoreCase)
            || ward.Area.Contains(search, StringComparison.OrdinalIgnoreCase)
            || ward.WardNo.ToString(CultureInfo.InvariantCulture).Contains(
                search,
                StringComparison.OrdinalIgnoreCase);
    }

    private static async Task<string> ResolveActiveWardIdAsync(
        SqlConnection connection,
        string tenantId,
        IReadOnlyList<TenantAreaWardRow> wards,
        CancellationToken cancellationToken)
    {
        if (wards.Count == 0)
        {
            return DefaultWardId;
        }

        var tenantWardNo = await connection.ExecuteScalarAsync<int?>(
            new CommandDefinition(
                """
                SELECT TOP (1) b.WardId
                FROM dbo.Tenants t
                LEFT JOIN dbo.Properties p ON p.Id = t.PropertyId
                LEFT JOIN dbo.Buildings b ON b.Id = p.BuildingId
                WHERE t.Id = @TenantId
                  AND b.WardId IS NOT NULL;
                """,
                new { TenantId = tenantId },
                cancellationToken: cancellationToken));
        var tenantWardId = tenantWardNo.HasValue
            ? $"ward-{tenantWardNo.Value}"
            : null;

        if (tenantWardId is not null &&
            wards.Any(ward => string.Equals(
                ward.Id,
                tenantWardId,
                StringComparison.OrdinalIgnoreCase)))
        {
            return tenantWardId;
        }

        return wards.FirstOrDefault(ward => string.Equals(
                ward.Id,
                DefaultWardId,
                StringComparison.OrdinalIgnoreCase))?.Id
            ?? wards[0].Id;
    }

    private static async Task<int> GetUnreadNotificationCountAsync(
        SqlConnection connection,
        CancellationToken cancellationToken)
    {
        return await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT COUNT(1)
                FROM dbo.Notifications
                WHERE IsUnread = 1;
                """,
                cancellationToken: cancellationToken));
    }

    private static async Task<IReadOnlyList<string>> QueryLocationOptionsAsync(
        SqlConnection connection,
        string tenantId,
        string fallbackLocation,
        CancellationToken cancellationToken)
    {
        var tenantLocations = await connection.QueryAsync<string?>(
            new CommandDefinition(
                """
                SELECT DISTINCT
                    COALESCE(
                        NULLIF(b.Address, ''),
                        NULLIF(p.Location, ''),
                        NULLIF(b.Location, '')
                    ) AS Label
                FROM dbo.Tenants t
                LEFT JOIN dbo.Properties p ON p.Id = t.PropertyId
                LEFT JOIN dbo.Buildings b ON b.Id = p.BuildingId
                WHERE t.Id = @TenantId;
                """,
                new { TenantId = tenantId },
                cancellationToken: cancellationToken));

        return tenantLocations
            .Append(fallbackLocation)
            .Select(TrimOrEmpty)
            .Where(value => value.Length > 0)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static async Task<TenantAreaLocalizedListDto> QueryWardRulesAsync(
        SqlConnection connection,
        string wardId,
        CancellationToken cancellationToken)
    {
        var rows = (await connection.QueryAsync<TenantAreaWardRuleRow>(
            new CommandDefinition(
                """
                SELECT Language, RuleText
                FROM dbo.TenantAreaWardRules
                WHERE WardId = @WardId OR WardId IS NULL
                ORDER BY
                    CASE WHEN WardId = @WardId THEN 0 ELSE 1 END,
                    DisplayOrder,
                    Id;
                """,
                new { WardId = wardId },
                cancellationToken: cancellationToken))).ToList();
        var bn = rows
            .Where(row => string.Equals(
                row.Language,
                "bn",
                StringComparison.OrdinalIgnoreCase))
            .Select(row => row.RuleText)
            .Where(rule => rule.Length > 0)
            .ToList();
        var en = rows
            .Where(row => string.Equals(
                row.Language,
                "en",
                StringComparison.OrdinalIgnoreCase))
            .Select(row => row.RuleText)
            .Where(rule => rule.Length > 0)
            .ToList();

        return new TenantAreaLocalizedListDto
        {
            Bn = bn.Count > 0 ? bn : new[] { DefaultWardRuleBn },
            En = en.Count > 0 ? en : new[] { "Do not post spam." },
        };
    }

    private static async Task<QueryPostsPageResult> QueryPostsPageAsync(
        SqlConnection connection,
        string? wardId,
        string? category,
        int page,
        int limit,
        CancellationToken cancellationToken)
    {
        var offset = (page - 1) * limit;
        var totalCount = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT COUNT(1)
                FROM dbo.TenantAreaPosts
                WHERE (@WardId IS NULL OR WardId = @WardId)
                  AND (@Category IS NULL OR LOWER(PostType) = @Category);
                """,
                new
                {
                    WardId = wardId,
                    Category = category,
                },
                cancellationToken: cancellationToken));
        var rows = (await connection.QueryAsync<TenantAreaPostRow>(
            new CommandDefinition(
                """
                SELECT
                    Id,
                    TenantId,
                    WardId,
                    PostType,
                    Details,
                    LocationLabel,
                    Latitude,
                    Longitude,
                    Privacy,
                    CreatedAt,
                    UpdatedAt
                FROM dbo.TenantAreaPosts
                WHERE (@WardId IS NULL OR WardId = @WardId)
                  AND (@Category IS NULL OR LOWER(PostType) = @Category)
                ORDER BY CreatedAt DESC, Id DESC
                OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
                """,
                new
                {
                    WardId = wardId,
                    Category = category,
                    Offset = offset,
                    Limit = limit,
                },
                cancellationToken: cancellationToken))).ToList();

        if (rows.Count == 0)
        {
            return new QueryPostsPageResult
            {
                Posts = Array.Empty<TenantAreaPostDto>(),
                TotalCount = totalCount,
            };
        }

        var attachments = await connection.QueryAsync<TenantAreaPostAttachmentRow>(
            new CommandDefinition(
                """
                SELECT
                    PostId,
                    FileName,
                    COALESCE(Url, '') AS Url
                FROM dbo.TenantAreaPostAttachments
                WHERE PostId IN @PostIds
                ORDER BY PostId, DisplayOrder, Id;
                """,
                new { PostIds = rows.Select(row => row.Id).ToArray() },
                cancellationToken: cancellationToken));
        var attachmentLookup = attachments.ToLookup(
            attachment => attachment.PostId,
            StringComparer.OrdinalIgnoreCase);

        return new QueryPostsPageResult
        {
            Posts = rows
                .Select(row => ToDto(row, attachmentLookup))
                .ToList(),
            TotalCount = totalCount,
        };
    }

    private static TenantAreaWardDto ToWardDto(
        TenantAreaWardRow ward,
        bool selected)
    {
        return new TenantAreaWardDto
        {
            Id = ward.Id,
            Title = new TenantAreaLocalizedTextDto
            {
                Bn = ward.TitleBn,
                En = ward.TitleEn,
            },
            TitleEn = ward.WardNo > 0
                ? $"Ward {ward.WardNo}"
                : ward.TitleEn,
            Area = ward.Area,
            MemberCount = ward.MemberCount,
            MemberLabel = new TenantAreaLocalizedTextDto
            {
                Bn = FormatMemberLabelBn(ward.MemberCount),
                En = FormatMemberLabelEn(ward.MemberCount),
            },
            Selected = selected,
            Verified = ward.Verified,
        };
    }

    private static TenantAreaPostDto ToDto(
        TenantAreaPostRow row,
        ILookup<string, TenantAreaPostAttachmentRow> attachmentLookup)
    {
        return new TenantAreaPostDto
        {
            Id = row.Id,
            TenantId = row.TenantId,
            WardId = row.WardId,
            PostType = row.PostType,
            Category = row.PostType,
            Details = row.Details,
            Location = new TenantAreaPostLocationDto
            {
                Label = row.LocationLabel,
                Latitude = row.Latitude,
                Longitude = row.Longitude,
            },
            Privacy = row.Privacy,
            Attachments = attachmentLookup[row.Id]
                .Select(attachment => new TenantAreaPostAttachmentDto
                {
                    FileName = attachment.FileName,
                    Url = attachment.Url,
                })
                .ToList(),
            CreatedAt = row.CreatedAt,
            UpdatedAt = row.UpdatedAt,
        };
    }

    private static TenantAreaPostDto ToDto(
        string postId,
        NormalizedTenantAreaPostRequest request,
        DateTime now)
    {
        return new TenantAreaPostDto
        {
            Id = postId,
            TenantId = request.TenantId,
            WardId = request.WardId,
            PostType = request.PostType,
            Category = request.PostType,
            Details = request.Details,
            Location = request.Location,
            Privacy = request.Privacy,
            Attachments = request.Attachments
                .Select(attachment => new TenantAreaPostAttachmentDto
                {
                    FileName = attachment.FileName,
                    Url = attachment.Url,
                })
                .ToList(),
            CreatedAt = now,
            UpdatedAt = now,
        };
    }

    private static int CalculateTotalPages(int totalCount, int limit)
    {
        return totalCount == 0
            ? 0
            : (int)Math.Ceiling(totalCount / (double)limit);
    }

    private static string FormatMemberLabelEn(int memberCount)
    {
        if (memberCount >= 1000)
        {
            var compactValue = Math.Floor(memberCount / 100.0) / 10.0;
            return string.Create(
                CultureInfo.InvariantCulture,
                $"{compactValue:0.#}k members");
        }

        return string.Create(
            CultureInfo.InvariantCulture,
            $"{memberCount} members");
    }

    private static string FormatMemberLabelBn(int memberCount)
    {
        if (memberCount >= 1000)
        {
            var compactValue = Math.Floor(memberCount / 100.0) / 10.0;
            var compactText = string.Create(
                CultureInfo.InvariantCulture,
                $"{compactValue:0.#}");
            return $"{ToBanglaDigits(compactText)}k {BanglaMemberSuffix}";
        }

        var countText = memberCount.ToString(CultureInfo.InvariantCulture);
        return $"{ToBanglaDigits(countText)} {BanglaMemberSuffix}";
    }

    private static string ToBanglaDigits(string value)
    {
        var characters = value.ToCharArray();
        for (var index = 0; index < characters.Length; index++)
        {
            if (characters[index] is >= '0' and <= '9')
            {
                characters[index] = BanglaDigits[characters[index] - '0'];
            }
        }

        return new string(characters);
    }

    private static void ValidateCoordinates(decimal? latitude, decimal? longitude)
    {
        if (latitude.HasValue != longitude.HasValue)
        {
            throw new TenantAreaValidationException(
                "Both latitude and longitude are required when sending coordinates.");
        }

        if (latitude is < -90m or > 90m)
        {
            throw new TenantAreaValidationException(
                "Latitude must be between -90 and 90.");
        }

        if (longitude is < -180m or > 180m)
        {
            throw new TenantAreaValidationException(
                "Longitude must be between -180 and 180.");
        }
    }

    private static void ValidateOptionalText(
        string value,
        string fieldName,
        int maximumLength)
    {
        if (value.Length > maximumLength)
        {
            throw new TenantAreaValidationException(
                $"{fieldName} cannot exceed {maximumLength} characters.");
        }
    }

    private static void ValidateRequiredText(
        string value,
        string fieldName,
        int maximumLength,
        int minimumLength = 1)
    {
        if (value.Length < minimumLength)
        {
            throw new TenantAreaValidationException(
                $"{fieldName} must contain at least {minimumLength} character(s).");
        }

        if (value.Length > maximumLength)
        {
            throw new TenantAreaValidationException(
                $"{fieldName} cannot exceed {maximumLength} characters.");
        }
    }

    private static string NormalizeRequiredText(
        string? value,
        string fieldName,
        int maximumLength)
    {
        var normalizedValue = TrimOrEmpty(value);
        ValidateRequiredText(normalizedValue, fieldName, maximumLength);
        return normalizedValue;
    }

    private static string TrimOrEmpty(string? value)
    {
        return value?.Trim() ?? string.Empty;
    }

    private static string? EmptyToNull(string value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value;
    }

    private static bool IsHttpUrl(string value)
    {
        return Uri.TryCreate(value, UriKind.Absolute, out var uri) &&
            (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps);
    }

    private sealed class TenantAreaWardRow
    {
        public string Id { get; init; } = string.Empty;
        public string City { get; init; } = string.Empty;
        public int WardNo { get; init; }
        public string TitleBn { get; init; } = string.Empty;
        public string TitleEn { get; init; } = string.Empty;
        public string Area { get; init; } = string.Empty;
        public int MemberCount { get; init; }
        public bool Verified { get; init; }
        public int DisplayOrder { get; init; }
    }

    private sealed class TenantAreaWardRuleRow
    {
        public string Language { get; init; } = string.Empty;
        public string RuleText { get; init; } = string.Empty;
    }

    private sealed class TenantAreaPostRow
    {
        public string Id { get; init; } = string.Empty;
        public string TenantId { get; init; } = string.Empty;
        public string WardId { get; init; } = string.Empty;
        public string PostType { get; init; } = string.Empty;
        public string Details { get; init; } = string.Empty;
        public string LocationLabel { get; init; } = string.Empty;
        public decimal? Latitude { get; init; }
        public decimal? Longitude { get; init; }
        public string Privacy { get; init; } = string.Empty;
        public DateTime CreatedAt { get; init; }
        public DateTime UpdatedAt { get; init; }
    }

    private sealed class TenantAreaPostAttachmentRow
    {
        public string PostId { get; init; } = string.Empty;
        public string FileName { get; init; } = string.Empty;
        public string Url { get; init; } = string.Empty;
    }

    private sealed class NormalizedTenantAreaPostRequest
    {
        public string TenantId { get; init; } = string.Empty;
        public string WardId { get; init; } = string.Empty;
        public string PostType { get; init; } = string.Empty;
        public string Details { get; init; } = string.Empty;
        public TenantAreaPostLocationDto Location { get; init; } = new();
        public string Privacy { get; init; } = string.Empty;
        public IReadOnlyList<NormalizedTenantAreaPostAttachment> Attachments { get; init; } =
            Array.Empty<NormalizedTenantAreaPostAttachment>();
    }

    private sealed class NormalizedTenantAreaPostAttachment
    {
        public string FileName { get; init; } = string.Empty;
        public string Url { get; init; } = string.Empty;
        public int DisplayOrder { get; init; }
    }

    private sealed class QueryPostsPageResult
    {
        public IReadOnlyList<TenantAreaPostDto> Posts { get; init; } =
            Array.Empty<TenantAreaPostDto>();
        public int TotalCount { get; init; }
    }
}

public sealed class TenantAreaValidationException : Exception
{
    public TenantAreaValidationException(string message)
        : base(message)
    {
    }
}

public sealed class TenantAreaNotFoundException : Exception
{
    public TenantAreaNotFoundException(string message)
        : base(message)
    {
    }
}
