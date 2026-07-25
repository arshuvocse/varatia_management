using Dapper;
using Microsoft.Data.SqlClient;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class OwnerPostService : IOwnerPostService
{
    private const int MaxShortTextLength = 100;
    private const int MaxLocationLength = 200;
    private const int MaxLatLongAddressLength = 250;
    private const int MaxDescriptionLength = 1000;
    private const int MaxRemarksLength = 500;
    private const string FulfillmentNotGot = "not_got";
    private const string FulfillmentGot = "got";
    private const string OwnerPostListQuery = """
        SELECT
            Id,
            OwnerId,
            PostType,
            Status,
            PropertyLocation AS Location,
            Latitude AS Lat,
            Longitude AS [Long],
            COALESCE(LatLongAddress, '') AS LatLongAddress,
            BuildingId,
            FloorId,
            PropertyId,
            PropertyTitle AS Title,
            TotalFloors,
            Bedrooms,
            Balconies,
            Dining,
            Drawing,
            Bathrooms,
            Kitchens,
            MonthlyRent,
            Advance,
            ServiceCharge,
            AreaSqft,
            ContactNumber,
            Description,
            FulfillmentStatus,
            Remarks,
            CreatedAt,
            UpdatedAt
        FROM dbo.OwnerPosts
        WHERE (@OwnerId IS NULL OR OwnerId = @OwnerId)
          AND (@Status IS NULL OR LOWER(Status) = @Status)
        ORDER BY CreatedAt DESC, Id DESC;

        SELECT
            photo.PostId,
            photo.FileName,
            photo.Url
        FROM dbo.OwnerPostPhotos photo
        INNER JOIN dbo.OwnerPosts post ON post.Id = photo.PostId
        WHERE (@OwnerId IS NULL OR post.OwnerId = @OwnerId)
          AND (@Status IS NULL OR LOWER(post.Status) = @Status)
        ORDER BY photo.PostId, photo.DisplayOrder, photo.Id;

        SELECT
            preference.PostId,
            preference.Preference
        FROM dbo.OwnerPostTenantPreferences preference
        INNER JOIN dbo.OwnerPosts post ON post.Id = preference.PostId
        WHERE (@OwnerId IS NULL OR post.OwnerId = @OwnerId)
          AND (@Status IS NULL OR LOWER(post.Status) = @Status)
        ORDER BY preference.PostId, preference.DisplayOrder, preference.Id;

        SELECT
            amenity.PostId,
            amenity.Amenity
        FROM dbo.OwnerPostAmenities amenity
        INNER JOIN dbo.OwnerPosts post ON post.Id = amenity.PostId
        WHERE (@OwnerId IS NULL OR post.OwnerId = @OwnerId)
          AND (@Status IS NULL OR LOWER(post.Status) = @Status)
        ORDER BY amenity.PostId, amenity.DisplayOrder, amenity.Id;
        """;

    private readonly SqlConnectionFactory _connectionFactory;

    public OwnerPostService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<OwnerPostListResponse> GetPostsAsync(
        string? ownerId = null,
        string? status = null,
        CancellationToken cancellationToken = default)
    {
        var normalizedOwnerId = EmptyToNull(TrimOrEmpty(ownerId));
        var normalizedStatus = EmptyToNull(
            TrimOrEmpty(status).ToLowerInvariant());

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        using var multi = await connection.QueryMultipleAsync(
            new CommandDefinition(
                OwnerPostListQuery,
                new
                {
                    OwnerId = normalizedOwnerId,
                    Status = normalizedStatus,
                },
                cancellationToken: cancellationToken));

        var posts = (await multi.ReadAsync<OwnerPostRow>()).ToList();
        var photoLookup = (await multi.ReadAsync<OwnerPostPhotoRow>())
            .ToLookup(photo => photo.PostId);
        var preferenceLookup =
            (await multi.ReadAsync<OwnerPostPreferenceRow>())
            .ToLookup(preference => preference.PostId);
        var amenityLookup = (await multi.ReadAsync<OwnerPostAmenityRow>())
            .ToLookup(amenity => amenity.PostId);

        return new OwnerPostListResponse
        {
            Posts = posts
                .Select(post => ToDto(
                    post,
                    photoLookup,
                    preferenceLookup,
                    amenityLookup))
                .ToList(),
        };
    }

    public async Task<CreateOwnerPostResponse> CreatePostAsync(
        CreateOwnerPostRequest request,
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
                cancellationToken);
            var now = DateTime.UtcNow;

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    INSERT INTO dbo.OwnerPosts
                    (
                        Id,
                        OwnerId,
                        PostType,
                        Status,
                        PropertyLocation,
                        Latitude,
                        Longitude,
                        LatLongAddress,
                        BuildingId,
                        FloorId,
                        PropertyId,
                        PropertyTitle,
                        TotalFloors,
                        Bedrooms,
                        Balconies,
                        Dining,
                        Drawing,
                        Bathrooms,
                        Kitchens,
                        MonthlyRent,
                        Advance,
                        ServiceCharge,
                        AreaSqft,
                        ContactNumber,
                        Description,
                        FulfillmentStatus,
                        Remarks,
                        CreatedAt,
                        UpdatedAt
                    )
                    VALUES
                    (
                        @Id,
                        @OwnerId,
                        @PostType,
                        @Status,
                        @PropertyLocation,
                        @Latitude,
                        @Longitude,
                        @LatLongAddress,
                        @BuildingId,
                        @FloorId,
                        @PropertyId,
                        @PropertyTitle,
                        @TotalFloors,
                        @Bedrooms,
                        @Balconies,
                        @Dining,
                        @Drawing,
                        @Bathrooms,
                        @Kitchens,
                        @MonthlyRent,
                        @Advance,
                        @ServiceCharge,
                        @AreaSqft,
                        @ContactNumber,
                        @Description,
                        @FulfillmentStatus,
                        @Remarks,
                        @Now,
                        @Now
                    );
                    """,
                    new
                    {
                        Id = postId,
                        normalizedRequest.OwnerId,
                        normalizedRequest.PostType,
                        normalizedRequest.Status,
                        PropertyLocation = normalizedRequest.Property.Location,
                        Latitude = normalizedRequest.Property.Lat,
                        Longitude = normalizedRequest.Property.Long,
                        LatLongAddress = EmptyToNull(
                            normalizedRequest.Property.LatLongAddress),
                        normalizedRequest.Property.BuildingId,
                        normalizedRequest.Property.FloorId,
                        normalizedRequest.Property.PropertyId,
                        PropertyTitle = normalizedRequest.Property.Title,
                        normalizedRequest.Rooms.TotalFloors,
                        normalizedRequest.Rooms.Bedrooms,
                        normalizedRequest.Rooms.Balconies,
                        normalizedRequest.Rooms.Dining,
                        normalizedRequest.Rooms.Drawing,
                        normalizedRequest.Rooms.Bathrooms,
                        normalizedRequest.Rooms.Kitchens,
                        normalizedRequest.Pricing.MonthlyRent,
                        normalizedRequest.Pricing.Advance,
                        normalizedRequest.Pricing.ServiceCharge,
                        normalizedRequest.AreaSqft,
                        normalizedRequest.ContactNumber,
                        Description = EmptyToNull(normalizedRequest.Description),
                        normalizedRequest.FulfillmentStatus,
                        Remarks = EmptyToNull(normalizedRequest.Remarks),
                        Now = now,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            foreach (var photo in normalizedRequest.Photos)
            {
                await connection.ExecuteAsync(
                    new CommandDefinition(
                        """
                        INSERT INTO dbo.OwnerPostPhotos
                            (PostId, FileName, Url, DisplayOrder)
                        VALUES
                            (@PostId, @FileName, @Url, @DisplayOrder);
                        """,
                        new
                        {
                            PostId = postId,
                            photo.FileName,
                            photo.Url,
                            photo.DisplayOrder,
                        },
                        transaction: transaction,
                        cancellationToken: cancellationToken));
            }

            foreach (var preference in normalizedRequest.TenantPreferences.Select(
                (value, index) => new { Value = value, DisplayOrder = index + 1 }))
            {
                await connection.ExecuteAsync(
                    new CommandDefinition(
                        """
                        INSERT INTO dbo.OwnerPostTenantPreferences
                            (PostId, Preference, DisplayOrder)
                        VALUES
                            (@PostId, @Preference, @DisplayOrder);
                        """,
                        new
                        {
                            PostId = postId,
                            Preference = preference.Value,
                            preference.DisplayOrder,
                        },
                        transaction: transaction,
                        cancellationToken: cancellationToken));
            }

            foreach (var amenity in normalizedRequest.Amenities.Select(
                (value, index) => new { Value = value, DisplayOrder = index + 1 }))
            {
                await connection.ExecuteAsync(
                    new CommandDefinition(
                        """
                        INSERT INTO dbo.OwnerPostAmenities
                            (PostId, Amenity, DisplayOrder)
                        VALUES
                            (@PostId, @Amenity, @DisplayOrder);
                        """,
                        new
                        {
                            PostId = postId,
                            Amenity = amenity.Value,
                            amenity.DisplayOrder,
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
                        Title = "Owner post created",
                        Subtitle =
                            $"{normalizedRequest.Property.Title} was posted for {normalizedRequest.PostType}.",
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            await transaction.CommitAsync(cancellationToken);

            return new CreateOwnerPostResponse
            {
                Post = ToDto(postId, normalizedRequest, now),
                Message = "Owner post created successfully.",
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
        System.Data.Common.DbTransaction transaction,
        CancellationToken cancellationToken)
    {
        var nextNumericId = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT ISNULL(MAX(TRY_CONVERT(int, SUBSTRING(Id, 6, LEN(Id) - 5))), 0) + 1
                FROM dbo.OwnerPosts WITH (UPDLOCK, HOLDLOCK)
                WHERE Id LIKE 'post[_]%';
                """,
                transaction: transaction,
                cancellationToken: cancellationToken));

        return $"post_{nextNumericId:D6}";
    }

    private static NormalizedOwnerPostRequest NormalizeRequest(
        CreateOwnerPostRequest request)
    {
        var property = request.Property ?? new OwnerPostPropertyRequest();
        var rooms = request.Rooms ?? new OwnerPostRoomsRequest();
        var pricing = request.Pricing ?? new OwnerPostPricingRequest();

        var photos = (request.Photos ?? Array.Empty<OwnerPostPhotoRequest>())
            .OfType<OwnerPostPhotoRequest>()
            .Select((photo, index) => new NormalizedOwnerPostPhoto
            {
                FileName = TrimOrEmpty(photo.FileName),
                Url = TrimOrEmpty(photo.Url),
                DisplayOrder = index + 1,
            })
            .ToList();

        return new NormalizedOwnerPostRequest
        {
            OwnerId = TrimOrEmpty(request.OwnerId),
            PostType = TrimOrEmpty(request.PostType).ToLowerInvariant(),
            Status = TrimOrEmpty(request.Status).ToLowerInvariant(),
            Property = new NormalizedOwnerPostProperty
            {
                Location = TrimOrEmpty(property.Location),
                Lat = property.Lat,
                Long = property.Long,
                LatLongAddress = TrimOrEmpty(property.LatLongAddress),
                BuildingId = TrimOrEmpty(property.BuildingId),
                FloorId = TrimOrEmpty(property.FloorId),
                PropertyId = TrimOrEmpty(property.PropertyId),
                Title = TrimOrEmpty(property.Title),
            },
            Photos = photos,
            TenantPreferences = NormalizeStringList(request.TenantPreferences),
            Rooms = new OwnerPostRoomsDto
            {
                TotalFloors = rooms.TotalFloors,
                Bedrooms = rooms.Bedrooms,
                Balconies = rooms.Balconies,
                Dining = rooms.Dining,
                Drawing = rooms.Drawing,
                Bathrooms = rooms.Bathrooms,
                Kitchens = rooms.Kitchens,
            },
            Amenities = NormalizeStringList(request.Amenities),
            Pricing = new OwnerPostPricingDto
            {
                MonthlyRent = pricing.MonthlyRent,
                Advance = pricing.Advance,
                ServiceCharge = pricing.ServiceCharge,
            },
            AreaSqft = request.AreaSqft,
            ContactNumber = TrimOrEmpty(request.ContactNumber),
            Description = TrimOrEmpty(request.Description),
            FulfillmentStatus = NormalizeFulfillmentStatus(
                request.FulfillmentStatus),
            Remarks = TrimOrEmpty(request.Remarks),
        };
    }

    private static IReadOnlyList<string> NormalizeStringList(
        IReadOnlyList<string>? values)
    {
        return (values ?? Array.Empty<string>())
            .Select(TrimOrEmpty)
            .Where(value => value.Length > 0)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static void ValidateRequest(NormalizedOwnerPostRequest request)
    {
        ValidateRequiredText(request.OwnerId, "Owner id", MaxShortTextLength);
        ValidateRequiredText(request.PostType, "Post type", 30);
        ValidateRequiredText(request.Status, "Status", 30);
        ValidateRequiredText(
            request.Property.Location,
            "Property location",
            MaxLocationLength,
            minimumLength: 3);
        ValidateCoordinates(request.Property.Lat, request.Property.Long);
        ValidateOptionalText(
            request.Property.LatLongAddress,
            "Lat-long address",
            MaxLatLongAddressLength);
        ValidateRequiredText(
            request.Property.BuildingId,
            "Building id",
            MaxShortTextLength);
        ValidateRequiredText(
            request.Property.FloorId,
            "Floor id",
            MaxShortTextLength);
        ValidateRequiredText(
            request.Property.PropertyId,
            "Property id",
            MaxShortTextLength);
        ValidateRequiredText(
            request.Property.Title,
            "Property title",
            150,
            minimumLength: 3);

        ValidateRooms(request.Rooms);
        ValidatePricing(request.Pricing);

        if (request.AreaSqft <= 0)
        {
            throw new OwnerPostValidationException(
                "Area square feet must be greater than zero.");
        }

        var contactNumberDigits = NormalizeDigits(request.ContactNumber);
        if (contactNumberDigits.Length < 10 || contactNumberDigits.Length > 15)
        {
            throw new OwnerPostValidationException(
                "Contact number must contain 10 to 15 digits.");
        }

        if (request.Description.Length > MaxDescriptionLength)
        {
            throw new OwnerPostValidationException(
                $"Description cannot exceed {MaxDescriptionLength} characters.");
        }

        ValidateFulfillmentStatus(request.FulfillmentStatus);
        ValidateOptionalText(request.Remarks, "Remarks", MaxRemarksLength);

        foreach (var photo in request.Photos)
        {
            ValidateRequiredText(photo.FileName, "Photo file name", 150);
            ValidateRequiredText(photo.Url, "Photo URL", 500);

            if (!IsHttpUrl(photo.Url))
            {
                throw new OwnerPostValidationException(
                    "Photo URL must be a valid HTTP or HTTPS URL.");
            }
        }

        foreach (var preference in request.TenantPreferences)
        {
            ValidateRequiredText(preference, "Tenant preference", 50);
        }

        foreach (var amenity in request.Amenities)
        {
            ValidateRequiredText(amenity, "Amenity", 50);
        }
    }

    private static void ValidateRooms(OwnerPostRoomsDto rooms)
    {
        if (rooms.TotalFloors <= 0)
        {
            throw new OwnerPostValidationException(
                "Total floors must be greater than zero.");
        }

        if (rooms.Bedrooms < 0 ||
            rooms.Balconies < 0 ||
            rooms.Dining < 0 ||
            rooms.Drawing < 0 ||
            rooms.Bathrooms < 0 ||
            rooms.Kitchens < 0)
        {
            throw new OwnerPostValidationException(
                "Room counts cannot be negative.");
        }
    }

    private static void ValidatePricing(OwnerPostPricingDto pricing)
    {
        if (pricing.MonthlyRent <= 0)
        {
            throw new OwnerPostValidationException(
                "Monthly rent must be greater than zero.");
        }

        if (pricing.Advance < 0 || pricing.ServiceCharge < 0)
        {
            throw new OwnerPostValidationException(
                "Advance and service charge cannot be negative.");
        }
    }

    private static void ValidateCoordinates(decimal? lat, decimal? longitude)
    {
        if (lat.HasValue != longitude.HasValue)
        {
            throw new OwnerPostValidationException(
                "Both lat and long are required when sending coordinates.");
        }

        if (lat is < -90m or > 90m)
        {
            throw new OwnerPostValidationException(
                "Lat must be between -90 and 90.");
        }

        if (longitude is < -180m or > 180m)
        {
            throw new OwnerPostValidationException(
                "Long must be between -180 and 180.");
        }
    }

    private static string NormalizeFulfillmentStatus(string? value)
    {
        var normalized = TrimOrEmpty(value).ToLowerInvariant()
            .Replace("-", "_")
            .Replace(" ", "_");

        return normalized switch
        {
            "got" or "found" or "rented" or "yes" => FulfillmentGot,
            _ => FulfillmentNotGot,
        };
    }

    private static void ValidateFulfillmentStatus(string value)
    {
        if (value is not FulfillmentNotGot and not FulfillmentGot)
        {
            throw new OwnerPostValidationException(
                "Fulfillment status must be either 'got' or 'not_got'.");
        }
    }

    private static void ValidateOptionalText(
        string value,
        string fieldName,
        int maximumLength)
    {
        if (value.Length > maximumLength)
        {
            throw new OwnerPostValidationException(
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
            throw new OwnerPostValidationException(
                $"{fieldName} must contain at least {minimumLength} character(s).");
        }

        if (value.Length > maximumLength)
        {
            throw new OwnerPostValidationException(
                $"{fieldName} cannot exceed {maximumLength} characters.");
        }
    }

    private static OwnerPostDto ToDto(
        OwnerPostRow post,
        ILookup<string, OwnerPostPhotoRow> photoLookup,
        ILookup<string, OwnerPostPreferenceRow> preferenceLookup,
        ILookup<string, OwnerPostAmenityRow> amenityLookup)
    {
        return new OwnerPostDto
        {
            Id = post.Id,
            OwnerId = post.OwnerId,
            PostType = post.PostType,
            Status = post.Status,
            Property = new OwnerPostPropertyDto
            {
                Location = post.Location,
                Lat = post.Lat,
                Long = post.Long,
                LatLongAddress = post.LatLongAddress,
                BuildingId = post.BuildingId,
                FloorId = post.FloorId,
                PropertyId = post.PropertyId,
                Title = post.Title,
            },
            Photos = photoLookup[post.Id]
                .Select(photo => new OwnerPostPhotoDto
                {
                    FileName = photo.FileName,
                    Url = photo.Url,
                })
                .ToList(),
            TenantPreferences = preferenceLookup[post.Id]
                .Select(preference => preference.Preference)
                .ToList(),
            Rooms = new OwnerPostRoomsDto
            {
                TotalFloors = post.TotalFloors,
                Bedrooms = post.Bedrooms,
                Balconies = post.Balconies,
                Dining = post.Dining,
                Drawing = post.Drawing,
                Bathrooms = post.Bathrooms,
                Kitchens = post.Kitchens,
            },
            Amenities = amenityLookup[post.Id]
                .Select(amenity => amenity.Amenity)
                .ToList(),
            Pricing = new OwnerPostPricingDto
            {
                MonthlyRent = post.MonthlyRent,
                Advance = post.Advance,
                ServiceCharge = post.ServiceCharge,
            },
            AreaSqft = post.AreaSqft,
            ContactNumber = post.ContactNumber,
            Description = post.Description ?? string.Empty,
            FulfillmentStatus = post.FulfillmentStatus,
            Remarks = post.Remarks ?? string.Empty,
            CreatedAt = post.CreatedAt,
            UpdatedAt = post.UpdatedAt,
        };
    }

    private static OwnerPostDto ToDto(
        string postId,
        NormalizedOwnerPostRequest request,
        DateTime now)
    {
        return new OwnerPostDto
        {
            Id = postId,
            OwnerId = request.OwnerId,
            PostType = request.PostType,
            Status = request.Status,
            Property = new OwnerPostPropertyDto
            {
                Location = request.Property.Location,
                Lat = request.Property.Lat,
                Long = request.Property.Long,
                LatLongAddress = request.Property.LatLongAddress,
                BuildingId = request.Property.BuildingId,
                FloorId = request.Property.FloorId,
                PropertyId = request.Property.PropertyId,
                Title = request.Property.Title,
            },
            Photos = request.Photos
                .Select(photo => new OwnerPostPhotoDto
                {
                    FileName = photo.FileName,
                    Url = photo.Url,
                })
                .ToList(),
            TenantPreferences = request.TenantPreferences,
            Rooms = request.Rooms,
            Amenities = request.Amenities,
            Pricing = request.Pricing,
            AreaSqft = request.AreaSqft,
            ContactNumber = request.ContactNumber,
            Description = request.Description,
            FulfillmentStatus = request.FulfillmentStatus,
            Remarks = request.Remarks,
            CreatedAt = now,
            UpdatedAt = now,
        };
    }

    private static string TrimOrEmpty(string? value)
    {
        return value?.Trim() ?? string.Empty;
    }

    private static string NormalizeDigits(string value)
    {
        return new string(value.Where(char.IsDigit).ToArray());
    }

    private static bool IsHttpUrl(string value)
    {
        return Uri.TryCreate(value, UriKind.Absolute, out var uri) &&
            (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps);
    }

    private static string? EmptyToNull(string value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value;
    }

    private sealed class NormalizedOwnerPostRequest
    {
        public string OwnerId { get; init; } = string.Empty;
        public string PostType { get; init; } = string.Empty;
        public string Status { get; init; } = string.Empty;
        public NormalizedOwnerPostProperty Property { get; init; } = new();
        public IReadOnlyList<NormalizedOwnerPostPhoto> Photos { get; init; } =
            Array.Empty<NormalizedOwnerPostPhoto>();
        public IReadOnlyList<string> TenantPreferences { get; init; } =
            Array.Empty<string>();
        public OwnerPostRoomsDto Rooms { get; init; } = new();
        public IReadOnlyList<string> Amenities { get; init; } =
            Array.Empty<string>();
        public OwnerPostPricingDto Pricing { get; init; } = new();
        public int AreaSqft { get; init; }
        public string ContactNumber { get; init; } = string.Empty;
        public string Description { get; init; } = string.Empty;
        public string FulfillmentStatus { get; init; } = string.Empty;
        public string Remarks { get; init; } = string.Empty;
    }

    private sealed class NormalizedOwnerPostProperty
    {
        public string Location { get; init; } = string.Empty;
        public decimal? Lat { get; init; }
        public decimal? Long { get; init; }
        public string LatLongAddress { get; init; } = string.Empty;
        public string BuildingId { get; init; } = string.Empty;
        public string FloorId { get; init; } = string.Empty;
        public string PropertyId { get; init; } = string.Empty;
        public string Title { get; init; } = string.Empty;
    }

    private sealed class OwnerPostRow
    {
        public string Id { get; init; } = string.Empty;
        public string OwnerId { get; init; } = string.Empty;
        public string PostType { get; init; } = string.Empty;
        public string Status { get; init; } = string.Empty;
        public string Location { get; init; } = string.Empty;
        public decimal? Lat { get; init; }
        public decimal? Long { get; init; }
        public string LatLongAddress { get; init; } = string.Empty;
        public string BuildingId { get; init; } = string.Empty;
        public string FloorId { get; init; } = string.Empty;
        public string PropertyId { get; init; } = string.Empty;
        public string Title { get; init; } = string.Empty;
        public int TotalFloors { get; init; }
        public int Bedrooms { get; init; }
        public int Balconies { get; init; }
        public int Dining { get; init; }
        public int Drawing { get; init; }
        public int Bathrooms { get; init; }
        public int Kitchens { get; init; }
        public int MonthlyRent { get; init; }
        public int Advance { get; init; }
        public int ServiceCharge { get; init; }
        public int AreaSqft { get; init; }
        public string ContactNumber { get; init; } = string.Empty;
        public string? Description { get; init; }
        public string FulfillmentStatus { get; init; } = string.Empty;
        public string? Remarks { get; init; }
        public DateTime CreatedAt { get; init; }
        public DateTime UpdatedAt { get; init; }
    }

    private sealed class OwnerPostPhotoRow
    {
        public string PostId { get; init; } = string.Empty;
        public string FileName { get; init; } = string.Empty;
        public string Url { get; init; } = string.Empty;
    }

    private sealed class OwnerPostPreferenceRow
    {
        public string PostId { get; init; } = string.Empty;
        public string Preference { get; init; } = string.Empty;
    }

    private sealed class OwnerPostAmenityRow
    {
        public string PostId { get; init; } = string.Empty;
        public string Amenity { get; init; } = string.Empty;
    }

    private sealed class NormalizedOwnerPostPhoto
    {
        public string FileName { get; init; } = string.Empty;
        public string Url { get; init; } = string.Empty;
        public int DisplayOrder { get; init; }
    }
}

public sealed class OwnerPostValidationException : Exception
{
    public OwnerPostValidationException(string message)
        : base(message)
    {
    }
}
