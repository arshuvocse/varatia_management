using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;
using System.Text.Json;

namespace OrderProcessAPI.Services;

public sealed class GeneralPostService : IGeneralPostService
{
    private readonly SqlConnectionFactory _connectionFactory;

    public GeneralPostService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<CreateGeneralPostResponse> CreatePostAsync(
        CreateGeneralPostRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        const string sql = """
            INSERT INTO dbo.GeneralPosts
            (
                UserId,
                Category,
                TenantType,
                Title,
                Price,
                Advance,
                UtilityIncluded,
                DivisionId,
                AreaId,
                FullAddress,
                Street,
                Latitude,
                Longitude,
                Bedrooms,
                Bathrooms,
                Kitchens,
                Balconies,
                HasGas,
                HasLift,
                HasGenerator,
                HasParking,
                Description,
                MediaInfo,
                Status,
                CreatedOn,
                UpdatedOn
            )
            VALUES
            (
                @UserId,
                @Category,
                @TenantType,
                @Title,
                @Price,
                @Advance,
                @UtilityIncluded,
                @DivisionId,
                @AreaId,
                @FullAddress,
                @Street,
                @Latitude,
                @Longitude,
                @Bedrooms,
                @Bathrooms,
                @Kitchens,
                @Balconies,
                @HasGas,
                @HasLift,
                @HasGenerator,
                @HasParking,
                @Description,
                @MediaInfo,
                'active',
                SYSUTCDATETIME(),
                SYSUTCDATETIME()
            );
            SELECT CAST(SCOPE_IDENTITY() as int);
            """;

        var insertedId = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                sql,
                new
                {
                    request.UserId,
                    request.Category,
                    request.TenantType,
                    request.Title,
                    request.Price,
                    request.Advance,
                    request.UtilityIncluded,
                    request.DivisionId,
                    request.AreaId,
                    request.FullAddress,
                    request.Street,
                    request.Latitude,
                    request.Longitude,
                    request.Bedrooms,
                    request.Bathrooms,
                    request.Kitchens,
                    request.Balconies,
                    request.HasGas,
                    request.HasLift,
                    request.HasGenerator,
                    request.HasParking,
                    request.Description,
                    request.MediaInfo
                },
                cancellationToken: cancellationToken));

        return new CreateGeneralPostResponse
        {
            Id = insertedId,
            Message = "General post created successfully."
        };
    }

    public async Task<IReadOnlyList<GeneralPostDto>> GetActivePostsAsync(
        string? viewerUserId = null,
        string? publicBaseUrl = null,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSocialTablesAsync(connection, cancellationToken);

        const string selectSql = """
            SELECT
                gp.Id,
                gp.UserId,
                gp.Category,
                gp.TenantType,
                gp.Title,
                gp.Price,
                gp.Advance,
                gp.UtilityIncluded,
                gp.DivisionId,
                dd.NameBn AS DivisionNameBn,
                gp.AreaId,
                da.NameBn AS AreaNameBn,
                gp.FullAddress,
                gp.Street,
                gp.Latitude,
                gp.Longitude,
                gp.Bedrooms,
                gp.Bathrooms,
                gp.Kitchens,
                gp.Balconies,
                gp.HasGas,
                gp.HasLift,
                gp.HasGenerator,
                gp.HasParking,
                gp.Description,
                gp.MediaInfo,
                ISNULL(likes.LikeCount, 0) AS LikeCount,
                ISNULL(comments.CommentCount, 0) AS CommentCount,
                CAST(CASE WHEN viewerLike.PostId IS NULL THEN 0 ELSE 1 END AS bit) AS IsLikedByViewer,
                gp.Status,
                gp.CreatedOn,
                gp.UpdatedOn
            FROM dbo.GeneralPosts gp
            LEFT JOIN dbo.DhakaDivisions dd ON gp.DivisionId = dd.Id
            LEFT JOIN dbo.DhakaAreas da ON gp.AreaId = da.Id
            LEFT JOIN
            (
                SELECT PostId, COUNT(1) AS LikeCount
                FROM dbo.GeneralPostLikes
                GROUP BY PostId
            ) likes ON gp.Id = likes.PostId
            LEFT JOIN
            (
                SELECT PostId, COUNT(1) AS CommentCount
                FROM dbo.GeneralPostComments
                WHERE IsDeleted = 0
                GROUP BY PostId
            ) comments ON gp.Id = comments.PostId
            LEFT JOIN dbo.GeneralPostLikes viewerLike
                ON gp.Id = viewerLike.PostId
                AND viewerLike.UserId = @ViewerUserId
            WHERE gp.Status = 'active'
            ORDER BY gp.CreatedOn DESC;
            """;

        var posts = (await connection.QueryAsync<GeneralPostDto>(
            new CommandDefinition(
                selectSql,
                new { ViewerUserId = NormalizeUserId(viewerUserId) },
                cancellationToken: cancellationToken))).ToList();

        if (posts.Count == 0)
        {
            // Seed default general posts
            const string insertSql = """
                INSERT INTO dbo.GeneralPosts
                (
                    UserId, Category, TenantType, Title, Price, Advance, UtilityIncluded,
                    DivisionId, AreaId, FullAddress, Street, Latitude, Longitude,
                    Bedrooms, Bathrooms, Kitchens, Balconies, HasGas, HasLift, HasGenerator, HasParking,
                    Description, MediaInfo, Status, CreatedOn, UpdatedOn
                )
                VALUES
                (
                    @UserId, @Category, @TenantType, @Title, @Price, @Advance, @UtilityIncluded,
                    @DivisionId, @AreaId, @FullAddress, @Street, @Latitude, @Longitude,
                    @Bedrooms, @Bathrooms, @Kitchens, @Balconies, @HasGas, @HasLift, @HasGenerator, @HasParking,
                    @Description, @MediaInfo, 'active', SYSUTCDATETIME(), SYSUTCDATETIME()
                );
                """;

            var seedList = new[]
            {
                new { UserId = "seed-user", Category = "rent", TenantType = "family", Title = "Mirpur DOHS, 2 Bed Flat", Price = 15000m, Advance = (decimal?)30000m, UtilityIncluded = false, DivisionId = "mirpur", AreaId = "mirpur-12", FullAddress = "Mirpur DOHS, Dhaka", Street = "Road 5", Latitude = (decimal?)23.8067m, Longitude = (decimal?)90.3686m, Bedrooms = 2, Bathrooms = 2, Kitchens = 1, Balconies = 1, HasGas = true, HasLift = false, HasGenerator = true, HasParking = true, Description = "Beautiful living room with ample light, near the park.", MediaInfo = "{\"artworkStyle\": \"livingRoom\", \"photoCount\": 6, \"areaSqft\": 1200, \"isNew\": true, \"imageUrl\": \"https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600&auto=format&fit=crop&q=60\"}" },
                new { UserId = "seed-user", Category = "sale", TenantType = "family", Title = "Gulshan 2, 3 Bed Flat", Price = 18500000m, Advance = (decimal?)0m, UtilityIncluded = false, DivisionId = "gulshan", AreaId = "gulshan-2", FullAddress = "Gulshan 2, Dhaka", Street = "Road 72", Latitude = (decimal?)23.7946m, Longitude = (decimal?)90.4143m, Bedrooms = 3, Bathrooms = 3, Kitchens = 1, Balconies = 2, HasGas = true, HasLift = true, HasGenerator = true, HasParking = true, Description = "Premium flat in the heart of Gulshan with modern fittings.", MediaInfo = "{\"artworkStyle\": \"bedroom\", \"photoCount\": 8, \"areaSqft\": 1600, \"imageUrl\": \"https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=600&auto=format&fit=crop&q=60\"}" },
                new { UserId = "seed-user", Category = "rent", TenantType = "family", Title = "Uttara Sector 7, 3 Bed Flat", Price = 22000m, Advance = (decimal?)44000m, UtilityIncluded = false, DivisionId = "uttara", AreaId = "uttara-sector-07", FullAddress = "Sector 7, Uttara, Dhaka", Street = "Road 12", Latitude = (decimal?)23.8759m, Longitude = (decimal?)90.3795m, Bedrooms = 3, Bathrooms = 3, Kitchens = 1, Balconies = 2, HasGas = true, HasLift = true, HasGenerator = true, HasParking = false, Description = "Spacious flat, close to schools, hospitals, and parks.", MediaInfo = "{\"artworkStyle\": \"diningRoom\", \"photoCount\": 5, \"areaSqft\": 1500, \"imageUrl\": \"https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=600&auto=format&fit=crop&q=60\"}" },
                new { UserId = "seed-user", Category = "sale", TenantType = "family", Title = "Banani Premium 4 Bed Flat", Price = 32500000m, Advance = (decimal?)0m, UtilityIncluded = false, DivisionId = "gulshan", AreaId = "banani", FullAddress = "Banani, Dhaka", Street = "Road 11", Latitude = (decimal?)23.7937m, Longitude = (decimal?)90.4043m, Bedrooms = 4, Bathrooms = 4, Kitchens = 1, Balconies = 3, HasGas = true, HasLift = true, HasGenerator = true, HasParking = true, Description = "Luxury apartment with smart home features and 24/7 security.", MediaInfo = "{\"artworkStyle\": \"building\", \"photoCount\": 7, \"areaSqft\": 2200, \"imageUrl\": \"https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=600&auto=format&fit=crop&q=60\"}" },
                new { UserId = "seed-user", Category = "rent", TenantType = "family", Title = "Mohammadpur Family 2 Bed Flat", Price = 18500m, Advance = (decimal?)37000m, UtilityIncluded = true, DivisionId = "tejgaon", AreaId = "mohammadpur", FullAddress = "Mohammadpur, Dhaka", Street = "Kaderabad Housing", Latitude = (decimal?)23.7658m, Longitude = (decimal?)90.3584m, Bedrooms = 2, Bathrooms = 2, Kitchens = 1, Balconies = 1, HasGas = true, HasLift = false, HasGenerator = false, HasParking = true, Description = "Cozy family flat in Mohammadpur with all amenities included.", MediaInfo = "{\"artworkStyle\": \"livingRoom\", \"photoCount\": 9, \"areaSqft\": 1100, \"isNew\": true, \"imageUrl\": \"https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600&auto=format&fit=crop&q=60\"}" },
                new { UserId = "seed-user", Category = "rent", TenantType = "bachelor_male", Title = "Badda Bachelor Seat Rent", Price = 6500m, Advance = (decimal?)6500m, UtilityIncluded = true, DivisionId = "gulshan", AreaId = "niketon", FullAddress = "Merul Badda, Dhaka", Street = "DIT Road", Latitude = (decimal?)23.7788m, Longitude = (decimal?)90.4244m, Bedrooms = 1, Bathrooms = 1, Kitchens = 1, Balconies = 0, HasGas = true, HasLift = false, HasGenerator = false, HasParking = false, Description = "Single seat for male bachelor, utilities and internet included.", MediaInfo = "{\"artworkStyle\": \"bedroom\", \"photoCount\": 4, \"areaSqft\": 450, \"imageUrl\": \"https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=600&auto=format&fit=crop&q=60\"}" },
                new { UserId = "seed-user", Category = "sale", TenantType = "family", Title = "Bashundhara Residential 3 Bed Flat", Price = 14500000m, Advance = (decimal?)0m, UtilityIncluded = false, DivisionId = "gulshan", AreaId = "baridhara", FullAddress = "Bashundhara R/A, Dhaka", Street = "Block C, Road 4", Latitude = (decimal?)23.8164m, Longitude = (decimal?)90.4264m, Bedrooms = 3, Bathrooms = 3, Kitchens = 1, Balconies = 2, HasGas = true, HasLift = true, HasGenerator = true, HasParking = true, Description = "Brand new flat in Bashundhara residential area with premium fittings.", MediaInfo = "{\"artworkStyle\": \"diningRoom\", \"photoCount\": 12, \"areaSqft\": 1450, \"isNew\": true, \"imageUrl\": \"https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600&auto=format&fit=crop&q=60\"}" }
            };

            foreach (var item in seedList)
            {
                await connection.ExecuteAsync(insertSql, item);
            }

            // Fetch again after seeding
            posts = (await connection.QueryAsync<GeneralPostDto>(
                new CommandDefinition(
                    selectSql,
                    new { ViewerUserId = NormalizeUserId(viewerUserId) },
                    cancellationToken: cancellationToken))).ToList();
        }

        foreach (var post in posts)
        {
            HydrateMediaUrls(post, publicBaseUrl);
        }

        return posts;
    }

    public async Task<GeneralPostDto?> GetPostByIdAsync(
        int postId,
        string? viewerUserId = null,
        string? publicBaseUrl = null,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSocialTablesAsync(connection, cancellationToken);

        const string selectSql = """
            SELECT
                gp.Id,
                gp.UserId,
                gp.Category,
                gp.TenantType,
                gp.Title,
                gp.Price,
                gp.Advance,
                gp.UtilityIncluded,
                gp.DivisionId,
                dd.NameBn AS DivisionNameBn,
                gp.AreaId,
                da.NameBn AS AreaNameBn,
                gp.FullAddress,
                gp.Street,
                gp.Latitude,
                gp.Longitude,
                gp.Bedrooms,
                gp.Bathrooms,
                gp.Kitchens,
                gp.Balconies,
                gp.HasGas,
                gp.HasLift,
                gp.HasGenerator,
                gp.HasParking,
                gp.Description,
                gp.MediaInfo,
                ISNULL(likes.LikeCount, 0) AS LikeCount,
                ISNULL(comments.CommentCount, 0) AS CommentCount,
                CAST(CASE WHEN viewerLike.PostId IS NULL THEN 0 ELSE 1 END AS bit) AS IsLikedByViewer,
                gp.Status,
                gp.CreatedOn,
                gp.UpdatedOn
            FROM dbo.GeneralPosts gp
            LEFT JOIN dbo.DhakaDivisions dd ON gp.DivisionId = dd.Id
            LEFT JOIN dbo.DhakaAreas da ON gp.AreaId = da.Id
            LEFT JOIN
            (
                SELECT PostId, COUNT(1) AS LikeCount
                FROM dbo.GeneralPostLikes
                GROUP BY PostId
            ) likes ON gp.Id = likes.PostId
            LEFT JOIN
            (
                SELECT PostId, COUNT(1) AS CommentCount
                FROM dbo.GeneralPostComments
                WHERE IsDeleted = 0
                GROUP BY PostId
            ) comments ON gp.Id = comments.PostId
            LEFT JOIN dbo.GeneralPostLikes viewerLike
                ON gp.Id = viewerLike.PostId
                AND viewerLike.UserId = @ViewerUserId
            WHERE gp.Id = @PostId
              AND gp.Status = 'active';
            """;

        var post = await connection.QuerySingleOrDefaultAsync<GeneralPostDto>(
            new CommandDefinition(
                selectSql,
                new { PostId = postId, ViewerUserId = NormalizeUserId(viewerUserId) },
                cancellationToken: cancellationToken));

        if (post is not null)
        {
            HydrateMediaUrls(post, publicBaseUrl);
        }

        return post;
    }

    public async Task<GeneralPostLikeResponse> LikePostAsync(
        int postId,
        string userId,
        CancellationToken cancellationToken = default)
    {
        var normalizedUserId = RequireUserId(userId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSocialTablesAsync(connection, cancellationToken);
        await EnsurePostExistsAsync(connection, postId, cancellationToken);

        const string sql = """
            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.GeneralPostLikes
                WHERE PostId = @PostId AND UserId = @UserId
            )
            BEGIN
                INSERT INTO dbo.GeneralPostLikes (PostId, UserId, CreatedOn)
                VALUES (@PostId, @UserId, SYSUTCDATETIME());
            END;

            SELECT COUNT(1)
            FROM dbo.GeneralPostLikes
            WHERE PostId = @PostId;
            """;

        var likeCount = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                sql,
                new { PostId = postId, UserId = normalizedUserId },
                cancellationToken: cancellationToken));

        return new GeneralPostLikeResponse
        {
            PostId = postId,
            IsLiked = true,
            LikeCount = likeCount
        };
    }

    public async Task<GeneralPostLikeResponse> UnlikePostAsync(
        int postId,
        string userId,
        CancellationToken cancellationToken = default)
    {
        var normalizedUserId = RequireUserId(userId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSocialTablesAsync(connection, cancellationToken);
        await EnsurePostExistsAsync(connection, postId, cancellationToken);

        const string sql = """
            DELETE FROM dbo.GeneralPostLikes
            WHERE PostId = @PostId AND UserId = @UserId;

            SELECT COUNT(1)
            FROM dbo.GeneralPostLikes
            WHERE PostId = @PostId;
            """;

        var likeCount = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                sql,
                new { PostId = postId, UserId = normalizedUserId },
                cancellationToken: cancellationToken));

        return new GeneralPostLikeResponse
        {
            PostId = postId,
            IsLiked = false,
            LikeCount = likeCount
        };
    }

    public async Task<IReadOnlyList<GeneralPostCommentDto>> GetCommentsAsync(
        int postId,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSocialTablesAsync(connection, cancellationToken);
        await EnsurePostExistsAsync(connection, postId, cancellationToken);

        const string sql = """
            SELECT Id, PostId, UserId, CommentText, CreatedOn, UpdatedOn
            FROM dbo.GeneralPostComments
            WHERE PostId = @PostId
              AND IsDeleted = 0
            ORDER BY CreatedOn DESC;
            """;

        var comments = await connection.QueryAsync<GeneralPostCommentDto>(
            new CommandDefinition(
                sql,
                new { PostId = postId },
                cancellationToken: cancellationToken));

        return comments.ToList();
    }

    public async Task<GeneralPostCommentDto> AddCommentAsync(
        int postId,
        CreateGeneralPostCommentRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var normalizedUserId = RequireUserId(request.UserId);
        var commentText = request.CommentText?.Trim();
        if (string.IsNullOrWhiteSpace(commentText))
        {
            throw new ArgumentException("Comment text is required.", nameof(request));
        }

        if (commentText.Length > 1000)
        {
            throw new ArgumentException("Comment text must be 1000 characters or shorter.", nameof(request));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSocialTablesAsync(connection, cancellationToken);
        await EnsurePostExistsAsync(connection, postId, cancellationToken);

        const string sql = """
            INSERT INTO dbo.GeneralPostComments
            (
                PostId,
                UserId,
                CommentText,
                IsDeleted,
                CreatedOn,
                UpdatedOn
            )
            OUTPUT INSERTED.Id, INSERTED.PostId, INSERTED.UserId, INSERTED.CommentText, INSERTED.CreatedOn, INSERTED.UpdatedOn
            VALUES
            (
                @PostId,
                @UserId,
                @CommentText,
                0,
                SYSUTCDATETIME(),
                SYSUTCDATETIME()
            );
            """;

        return await connection.QuerySingleAsync<GeneralPostCommentDto>(
            new CommandDefinition(
                sql,
                new { PostId = postId, UserId = normalizedUserId, CommentText = commentText },
                cancellationToken: cancellationToken));
    }

    private static void HydrateMediaUrls(GeneralPostDto post, string? publicBaseUrl)
    {
        var urls = ExtractMediaUrls(post.MediaInfo)
            .Select(url => ToPublicUrl(url, publicBaseUrl))
            .Where(url => !string.IsNullOrWhiteSpace(url))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        post.MediaUrls = urls;
        post.ImageUrl = urls.FirstOrDefault();
        post.PhotoCount = Math.Max(ExtractPhotoCount(post.MediaInfo), urls.Count);
    }

    private static IEnumerable<string> ExtractMediaUrls(string? mediaInfo)
    {
        if (string.IsNullOrWhiteSpace(mediaInfo))
        {
            yield break;
        }

        var trimmed = mediaInfo.Trim();
        if (trimmed.StartsWith("{", StringComparison.Ordinal) || trimmed.StartsWith("[", StringComparison.Ordinal))
        {
            using var document = ParseJsonOrNull(trimmed);
            if (document is null)
            {
                yield break;
            }

            foreach (var url in ExtractMediaUrls(document.RootElement))
            {
                yield return url;
            }

            yield break;
        }

        foreach (var item in trimmed.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            yield return item;
        }
    }

    private static int ExtractPhotoCount(string? mediaInfo)
    {
        if (string.IsNullOrWhiteSpace(mediaInfo))
        {
            return 0;
        }

        var trimmed = mediaInfo.Trim();
        if (!trimmed.StartsWith("{", StringComparison.Ordinal) && !trimmed.StartsWith("[", StringComparison.Ordinal))
        {
            return trimmed.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries).Length;
        }

        using var document = ParseJsonOrNull(trimmed);
        if (document is null)
        {
            return 0;
        }

        return ExtractPhotoCount(document.RootElement);
    }

    private static int ExtractPhotoCount(JsonElement element)
    {
        if (element.ValueKind == JsonValueKind.Object
            && element.TryGetProperty("photoCount", out var photoCount)
            && photoCount.TryGetInt32(out var count))
        {
            return count;
        }

        if (element.ValueKind == JsonValueKind.Array)
        {
            return element.GetArrayLength();
        }

        return 0;
    }

    private static JsonDocument? ParseJsonOrNull(string value)
    {
        try
        {
            return JsonDocument.Parse(value);
        }
        catch (JsonException)
        {
            return null;
        }
    }

    private static IEnumerable<string> ExtractMediaUrls(JsonElement element)
    {
        switch (element.ValueKind)
        {
            case JsonValueKind.Object:
                if (element.TryGetProperty("imageUrl", out var imageUrl) && imageUrl.ValueKind == JsonValueKind.String)
                {
                    yield return imageUrl.GetString() ?? string.Empty;
                }

                if (element.TryGetProperty("url", out var url) && url.ValueKind == JsonValueKind.String)
                {
                    yield return url.GetString() ?? string.Empty;
                }

                if (element.TryGetProperty("mediaUrls", out var mediaUrls))
                {
                    foreach (var childUrl in ExtractMediaUrls(mediaUrls))
                    {
                        yield return childUrl;
                    }
                }

                if (element.TryGetProperty("images", out var images))
                {
                    foreach (var childUrl in ExtractMediaUrls(images))
                    {
                        yield return childUrl;
                    }
                }

                if (element.TryGetProperty("files", out var files))
                {
                    foreach (var childUrl in ExtractMediaUrls(files))
                    {
                        yield return childUrl;
                    }
                }

                break;
            case JsonValueKind.Array:
                foreach (var child in element.EnumerateArray())
                {
                    foreach (var childUrl in ExtractMediaUrls(child))
                    {
                        yield return childUrl;
                    }
                }

                break;
            case JsonValueKind.String:
                yield return element.GetString() ?? string.Empty;
                break;
        }
    }

    private static string ToPublicUrl(string url, string? publicBaseUrl)
    {
        var trimmed = url.Trim();
        if (Uri.TryCreate(trimmed, UriKind.Absolute, out _))
        {
            return trimmed;
        }

        if (string.IsNullOrWhiteSpace(publicBaseUrl))
        {
            return trimmed;
        }

        return $"{publicBaseUrl.TrimEnd('/')}/{trimmed.TrimStart('/')}";
    }

    private static string? NormalizeUserId(string? userId)
    {
        return string.IsNullOrWhiteSpace(userId) ? null : userId.Trim();
    }

    private static string RequireUserId(string? userId)
    {
        var normalizedUserId = NormalizeUserId(userId);
        if (normalizedUserId is null)
        {
            throw new ArgumentException("User ID is required.", nameof(userId));
        }

        return normalizedUserId;
    }

    private static async Task EnsurePostExistsAsync(
        System.Data.IDbConnection connection,
        int postId,
        CancellationToken cancellationToken)
    {
        var exists = await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(
                """
                SELECT CAST(CASE WHEN EXISTS
                (
                    SELECT 1
                    FROM dbo.GeneralPosts
                    WHERE Id = @PostId AND Status = 'active'
                ) THEN 1 ELSE 0 END AS bit);
                """,
                new { PostId = postId },
                cancellationToken: cancellationToken));

        if (!exists)
        {
            throw new InvalidOperationException("General post was not found.");
        }
    }

    private static Task EnsureSocialTablesAsync(
        System.Data.IDbConnection connection,
        CancellationToken cancellationToken)
    {
        const string sql = """
            IF OBJECT_ID(N'dbo.GeneralPostLikes', N'U') IS NULL
            BEGIN
                CREATE TABLE dbo.GeneralPostLikes
                (
                    Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                    PostId INT NOT NULL,
                    UserId NVARCHAR(100) NOT NULL,
                    CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_GeneralPostLikes_CreatedOn DEFAULT (SYSUTCDATETIME()),
                    CONSTRAINT FK_GeneralPostLikes_GeneralPosts
                        FOREIGN KEY (PostId) REFERENCES dbo.GeneralPosts(Id) ON DELETE CASCADE,
                    CONSTRAINT UQ_GeneralPostLikes_Post_User
                        UNIQUE (PostId, UserId)
                );
            END;

            IF OBJECT_ID(N'dbo.GeneralPostComments', N'U') IS NULL
            BEGIN
                CREATE TABLE dbo.GeneralPostComments
                (
                    Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                    PostId INT NOT NULL,
                    UserId NVARCHAR(100) NOT NULL,
                    CommentText NVARCHAR(1000) NOT NULL,
                    IsDeleted BIT NOT NULL CONSTRAINT DF_GeneralPostComments_IsDeleted DEFAULT(0),
                    CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_GeneralPostComments_CreatedOn DEFAULT (SYSUTCDATETIME()),
                    UpdatedOn DATETIME2 NOT NULL CONSTRAINT DF_GeneralPostComments_UpdatedOn DEFAULT (SYSUTCDATETIME()),
                    CONSTRAINT FK_GeneralPostComments_GeneralPosts
                        FOREIGN KEY (PostId) REFERENCES dbo.GeneralPosts(Id) ON DELETE CASCADE
                );
            END;

            IF NOT EXISTS
            (
                SELECT 1
                FROM sys.indexes
                WHERE name = N'IX_GeneralPostComments_PostId_CreatedOn'
                  AND object_id = OBJECT_ID(N'dbo.GeneralPostComments')
            )
            BEGIN
                CREATE INDEX IX_GeneralPostComments_PostId_CreatedOn
                ON dbo.GeneralPostComments (PostId, CreatedOn DESC)
                INCLUDE (IsDeleted);
            END;
            """;

        return connection.ExecuteAsync(new CommandDefinition(sql, cancellationToken: cancellationToken));
    }
}
