namespace PromotionWeb.Models;

public sealed class AppUser
{
    public int Id { get; init; }
    public string Name { get; init; } = "";
    public string Phone { get; init; } = "";
    public string Password { get; init; } = "";
    public string Role { get; init; } = "";
    public string? ShopCode { get; init; }
    public int? ParentUserId { get; init; }
    public bool IsActive { get; init; } = true;
    public DateTime CreatedAt { get; init; } = DateTime.Now;
    public string? ProfilePictureUrl { get; init; }
}

public static class RoleLabels
{
    public static string GetDisplayName(string role) => UiText.Role(role);
}
