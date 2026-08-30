namespace PromotionWeb.Models;

public sealed class TeamMemberDirectoryItem
{
    public int Id { get; init; }
    public string Name { get; init; } = "";
    public string Phone { get; init; } = "";
    public string Role { get; init; } = ""; // "Agent" or "FieldOfficer"
    public string RoleTitle { get; init; } = ""; // "এরিয়া এজেন্ট" or "ফিল্ড অফিসার"
    public string? ProfilePictureUrl { get; init; }
    public int? DistrictId { get; init; }
    public string DistrictName { get; init; } = "";
    public int ConnectedCount { get; init; }
    public string ConnectedLabel { get; init; } = "";
    public string? ParentName { get; init; }
    public bool IsActive { get; init; } = true;
    public double Rating { get; init; } = 4.9;
    public DateTime CreatedAt { get; init; }
}
