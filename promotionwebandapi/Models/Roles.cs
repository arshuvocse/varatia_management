namespace PromotionWeb.Models;

public static class Roles
{
    public const string FieldOfficer = "FieldOfficer";
    public const string Company = "Company";
    public const string Shopkeeper = "Shopkeeper";
    public const string Agent = "Agent";
    public const string Customer = "Customer";
    public const string DeliveryMan = "DeliveryMan";
    public const string SupportAgent = "SupportAgent";

    public static readonly IReadOnlySet<string> All = new HashSet<string>
    {
        FieldOfficer,
        Company,
        Shopkeeper,
        Agent,
        Customer,
        DeliveryMan,
        SupportAgent
    };
}
