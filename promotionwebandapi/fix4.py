import sys

filename = 'd:/Shuvo/project Idea/Babu Project/Varatia_management/promotionwebandapi/wwwroot/landing.html'
with open(filename, 'r', encoding='utf-8') as f:
    lines = f.readlines()

logo_html = '''            <div class="ss-logo-block">
              <div class="ss-logo-icon">
                <svg viewBox="0 0 24 24" fill="white" stroke="white" stroke-width="1" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                  <polyline points="9 22 9 12 15 12 15 22"></polyline>
                  <circle cx="12" cy="7" r="2" fill="#28a745"></circle>
                </svg>
              </div>
              <div class="ss-logo-text">আমার ঠিকানা</div>
            </div>
'''

css_to_add = '''
    .ss-logo-block {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      margin-right: 15px;
    }
    .ss-logo-icon {
      background-color: #1a7138;
      width: 60px;
      height: 60px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 5px;
    }
    .ss-logo-icon svg {
      width: 32px;
      height: 32px;
    }
    .ss-logo-text {
      color: #1a7138;
      font-size: 14px;
      font-weight: bold;
    }
'''

for i, line in enumerate(lines):
    if '<img src="amar_thikanaa_icon.png" alt="Amar Thikana Logo">' in line:
        lines[i] = logo_html
        break

css_start = -1
for i, line in enumerate(lines):
    if '.ss-banner-header img { height: 50px; }' in line:
        lines[i] = css_to_add
        break

with open(filename, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print('Added logo block.')
