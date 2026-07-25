using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Models;

public class SosAlertDto
{
    public int Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public DateTime TriggeredAt { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class SosAlertTriggerModel
{
    [Required]
    public string UserId { get; set; } = string.Empty;
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

public class SosEmergencyContactDto
{
    public int Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Relation { get; set; }
    public string? ImageUrl { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class SosEmergencyContactInputModel
{
    [Required]
    public string UserId { get; set; } = string.Empty;
    [Required]
    public string Name { get; set; } = string.Empty;
    [Required]
    public string Phone { get; set; } = string.Empty;
    public string? Relation { get; set; }
    public string? ImageUrl { get; set; }
}

public class SosLocationUpdateModel
{
    [Required]
    public string UserId { get; set; } = string.Empty;
    [Required]
    public double Latitude { get; set; }
    [Required]
    public double Longitude { get; set; }
}

public class SosEmergencyServiceDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
}

public class SosSafetyTipDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class SosEvidenceInputModel
{
    [Required]
    public string UserId { get; set; } = string.Empty;
    [Required]
    public string FileUrl { get; set; } = string.Empty;
    [Required]
    public string FileType { get; set; } = string.Empty;
}
