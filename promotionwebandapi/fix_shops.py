import sys

filepath = 'Views/FieldOfficer/Shops.cshtml'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

lines = content.splitlines(True)
new_content = []
i = 0
while i < len(lines):
    if '<main class="app-page officer-theme">' in lines[i]:
        new_content.append('<main class="app-page shop-theme shop-portal-page officer-portal-page">\n')
        new_content.append('    <div class="shop-portal-shell">\n')
        new_content.append('        <partial name="_Sidebar" model=\'new FieldOfficerDashboardViewModel { Shops = Model as List<Shopkeeper> ?? new List<Shopkeeper>(), OfficerName = Context.Session.GetString("UserName") ?? "ফিল্ড ফোর্স" }\' />\n')
        new_content.append('        <section class="shop-page-content">\n')
        new_content.append('            <header class="shop-page-header">\n')
        new_content.append('                <div>\n')
        new_content.append('                    <span>FIELD FORCE APP</span>\n')
        new_content.append('                    <h1>রেজিস্টার্ড দোকানসমূহ</h1>\n')
        new_content.append('                    <p>সব দোকানের তথ্য সার্চ, সর্ট এবং পেজিনেশনসহ দেখুন।</p>\n')
        new_content.append('                </div>\n')
        new_content.append('            </header>\n')
        while i < len(lines) and '</header>' not in lines[i]:
            i += 1
        i += 1
        continue
    new_content.append(lines[i])
    i += 1

final_content = ''.join(new_content)
final_content = final_content.replace('    </section>\n</main>', '        </section>\n    </div>\n</main>')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(final_content)
