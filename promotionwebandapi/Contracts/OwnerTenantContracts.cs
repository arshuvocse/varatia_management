namespace OrderProcessAPI.Contracts;

public sealed class OwnerTenantListResponse
{
    public IReadOnlyList<TenantProfileDto> Tenants { get; init; } =
        Array.Empty<TenantProfileDto>();
}

public sealed class CreateOwnerTenantRequest
{
    public string FullName { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public string Nid { get; init; } = string.Empty;
    public string PropertyId { get; init; } = string.Empty;
}

public sealed class CreateOwnerTenantResponse
{
    public TenantProfileDto Tenant { get; init; } = new();
    public string PropertyId { get; init; } = string.Empty;
    public string PropertyName { get; init; } = string.Empty;
    public string LoginPhoneNumber { get; init; } = string.Empty;
    public string TemporaryPassword { get; init; } = string.Empty;
    public bool CredentialSmsSent { get; init; }
    public string CredentialSmsError { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}

public sealed class UpdateOwnerTenantRequest
{
    public string FullName { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public string Nid { get; init; } = string.Empty;
}

public sealed class UpdateOwnerTenantResponse
{
    public TenantProfileDto Tenant { get; init; } = new();
    public string PropertyId { get; init; } = string.Empty;
    public string PropertyName { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}

public sealed class DeleteOwnerTenantResponse
{
    public string TenantId { get; init; } = string.Empty;
    public string PropertyId { get; init; } = string.Empty;
    public string PropertyName { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}

public sealed class MoveOutOwnerTenantResponse
{
    public TenantProfileDto Tenant { get; init; } = new();
    public string PreviousPropertyId { get; init; } = string.Empty;
    public string PreviousPropertyName { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}
