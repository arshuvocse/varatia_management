namespace PromotionWeb.Models;

public static class UiText
{
    public static string Role(string value) => value switch
    {
        Roles.Company => "কোম্পানি",
        Roles.Agent => "এজেন্ট",
        Roles.FieldOfficer => "ফিল্ড কর্মী",
        Roles.Shopkeeper => "দোকানদার",
        Roles.Customer => "ক্রেতা",
        Roles.DeliveryMan => "ডেলিভারি কর্মী",
        _ => value
    };

    public static string Status(string value) => value switch
    {
        "Active" => "সক্রিয়",
        "Inactive" => "নিষ্ক্রিয়",
        "Available" => "কাজের জন্য প্রস্তুত",
        "Busy" => "ব্যস্ত",
        "Offline" => "অফলাইন",
        "Pending" => "অপেক্ষমাণ",
        "Approved" => "অনুমোদিত",
        "Assigned" => "দায়িত্ব দেওয়া হয়েছে",
        "Accepted" => "গ্রহণ করা হয়েছে",
        "Picked Up" => "পণ্য সংগ্রহ করা হয়েছে",
        "Out for Delivery" => "ডেলিভারির পথে",
        "Delivered" => "ডেলিভারি সম্পন্ন",
        "Rejected" => "বাতিল করা হয়েছে",
        "Failed Delivery" => "ডেলিভারি ব্যর্থ",
        "Cancelled" => "বাতিল",
        "Returned" => "ফেরত এসেছে",
        "Paid" => "পরিশোধিত",
        "Failed" => "ব্যর্থ",
        "New" => "নতুন",
        "Contacted" => "যোগাযোগ করা হয়েছে",
        "Completed" => "সম্পন্ন",
        "Paused" => "স্থগিত",
        _ => value
    };
}
