import sys

filename = 'd:/Shuvo/project Idea/Babu Project/Varatia_management/promotionwebandapi/wwwroot/landing.html'
with open(filename, 'r', encoding='utf-8') as f:
    lines = f.readlines()

html_code = '''          <div class="ss-banner-body" style="display:flex; justify-content:center; padding: 20px;">
            <img src="images/banner-img-2.jpg" alt="Smart Solutions Banner" style="max-width: 100%; border-radius: 12px; box-shadow: 0 10px 30px rgba(0,0,0,0.1);">
          </div>\n'''

start_idx = -1
end_idx = -1
for i, line in enumerate(lines):
    if '<div class="ss-banner-body ss-billboard-layout">' in line:
        start_idx = i
    if '<div class="ss-banner-footer">' in line and start_idx != -1:
        end_idx = i
        break

if start_idx != -1 and end_idx != -1:
    lines[start_idx:end_idx] = [html_code]
    with open(filename, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print('Replaced billboard layout with simple image tag.')
else:
    print('Could not find boundaries.')
