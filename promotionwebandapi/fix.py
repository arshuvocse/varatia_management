import sys
import os

filepath = 'Views/FieldOfficer/Dashboard.cshtml'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

header = """@model FieldOfficerDashboardViewModel
@using System.Text.Json
@{
    ViewData["Title"] = "Field Force Dashboard";
    ViewData["ActivePage"] = "Dashboard";
    var totalShops = Model.Shops.Count;
    var activeShops = Model.Shops.Count;
    var monthSale = Model.Shops.Count * 125000;
    var commission = Model.Shops.Count * 650;
    var locationJson = JsonSerializer.Serialize(new
    {
        districts = Model.Locations.Districts.Select(x => new { x.Id, x.Name, x.ParentId }),
        thanas = Model.Locations.Thanas.Select(x => new { x.Id, x.Name, x.ParentId })
    });
}

<main class="app-page shop-theme shop-portal-page officer-portal-page">
    <div class="toast-stack" id="toast-stack" aria-live="polite" aria-atomic="true"></div>
    <div class="shop-portal-shell">
        <partial name="_Sidebar" model="Model" />
        <section class="shop-page-content">
            <header class="shop-page-header">
                <div>
                    <span>FIELD FORCE APP</span>
                    <h1>স্বাগতম, @Model.OfficerName</h1>
                    <p>দোকান রেজিস্ট্রেশন, পারফরম্যান্স এবং কমিশন এক জায়গায় দেখুন।</p>
                </div>
            </header>

            @if (!string.IsNullOrWhiteSpace(Model.SuccessMessage))
            {
                <div class="alert-success">@Model.SuccessMessage</div>
            }

            <section class="fieldforce-hero">
                <div class="performance-card fieldforce-summary">
                    <span>আমার পারফরম্যান্স</span>
                    <div><strong>@totalShops</strong><small>মোট দোকান</small></div>
                    <div><strong>@activeShops</strong><small>সক্রিয় দোকান</small></div>
                    <div><strong>৳ @monthSale.ToString("N0")</strong><small>মোট Sale</small></div>
                    <div><strong>৳ @commission.ToString("N0")</strong><small>আমার কমিশন</small></div>
                </div>

                <div class="fieldforce-actions">
                    <a href="#register-shop"><span>＋</span><strong>নতুন দোকান</strong></a>
                    <a href="/FieldForce/Shops"><span>▤</span><strong>দোকানসমূহ</strong></a>
"""

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(header + content)
