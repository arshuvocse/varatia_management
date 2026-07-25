namespace OrderProcessAPI.Contracts;

public sealed class AnnouncementDto
{
    public int Id { get; init; }
    public string Message { get; init; } = string.Empty;
    public string? LinkUrl { get; init; }
    public bool IsActive { get; init; }
    public DateTime? StartAt { get; init; }
    public DateTime? EndAt { get; init; }
    public DateTime CreatedAt { get; init; }
}
