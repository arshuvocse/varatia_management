import sys

filename = 'd:/Shuvo/project Idea/Babu Project/Varatia_management/promotionwebandapi/wwwroot/landing.html'
with open(filename, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_css = '''    /* Smart Solutions Banner (Hubuhu Redesign) */
    .smart-solutions-banner {
      background: #fdfdfd;
      border: 1px solid #ddd;
      box-shadow: 0 10px 30px rgba(0,0,0,0.1);
      margin: 40px auto;
      max-width: 1200px;
      position: relative;
      overflow: hidden;
      font-family: 'Anek Bangla', sans-serif;
    }
    .ss-banner-header {
      display: flex;
      align-items: center;
      gap: 20px;
      padding: 30px;
      background: #fdfdfd;
    }
    .ss-logo-block {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
    }
    .ss-logo-icon {
      background-color: #1a7138;
      width: 70px;
      height: 70px;
      border-radius: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 5px;
    }
    .ss-logo-icon svg { width: 40px; height: 40px; }
    .ss-logo-text { color: #1a7138; font-size: 16px; font-weight: 800; text-align: center; line-height: 1.1; }
    .ss-banner-header h3 { margin: 0; font-size: 32px; font-weight: 800; color: #1a4a38; line-height: 1.2; }
    .ss-banner-header h3 span { color: #333; font-size: 22px; font-weight: 600; display: block; margin-top: 8px;}
    
    .ss-banner-body { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; padding: 0 15px 30px; }
    .ss-col { background: #fff; position: relative; display: flex; flex-direction: column; }
    
    /* Top Image Box */
    .ss-image-container { position: relative; width: 100%; height: 220px; border-radius: 4px; overflow: hidden; background: #e0e0e0; margin-bottom: 20px;}
    .ss-image-container img { width: 100%; height: 100%; object-fit: cover; }
    
    /* Colored Tags Overlapping */
    .ss-tab {
      position: absolute;
      top: -15px;
      left: -5px;
      z-index: 10;
      padding: 8px 16px;
      color: white;
      font-weight: bold;
      font-size: 16px;
      display: flex;
      align-items: center;
      gap: 8px;
      border-radius: 20px 20px 20px 0;
      box-shadow: 2px 4px 10px rgba(0,0,0,0.2);
    }
    .ss-tab svg { width: 20px; height: 20px; }
    .ss-tab-red { background: #b71c1c; }
    .ss-tab-blue { background: #1565c0; }
    .ss-tab-green { background: #1b5e20; }
    
    /* Speech Bubble */
    .ss-bubble {
      position: absolute;
      bottom: 20px;
      right: 20px;
      background: rgba(255, 255, 255, 0.95);
      padding: 10px 15px;
      border-radius: 12px;
      font-size: 13px;
      font-weight: 600;
      max-width: 160px;
      box-shadow: 0 4px 10px rgba(0,0,0,0.15);
      border: 1px solid #eee;
    }
    .ss-bubble::after {
      content: '';
      position: absolute;
      top: 50%;
      left: -8px;
      border-width: 8px 8px 8px 0;
      border-style: solid;
      border-color: transparent white transparent transparent;
      transform: translateY(-50%);
    }
    .ss-bubble-red { color: #b71c1c; }
    .ss-bubble-blue { color: #1565c0; }
    .ss-bubble-green { color: #1b5e20; }
    
    /* Bottom Section */
    .ss-bottom-section { display: flex; flex-direction: row; align-items: stretch; background: #f4f6f8; padding: 15px; border-radius: 8px; flex-grow: 1; border: 1px solid #e2e8f0; }
    
    /* Phone Mockup */
    .ss-app-mockup {
      width: 130px;
      background: white;
      border-radius: 20px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      overflow: hidden;
      border: 6px solid #111;
      margin-right: 15px;
      flex-shrink: 0;
      display: flex;
      flex-direction: column;
      position: relative;
    }
    .ss-app-mockup::before {
      content: '';
      position: absolute;
      top: 0; left: 50%; transform: translateX(-50%);
      width: 40%; height: 12px;
      background: #111;
      border-bottom-left-radius: 6px;
      border-bottom-right-radius: 6px;
      z-index: 2;
    }
    .ss-app-mockup-header { padding: 12px 8px 8px; color: white; font-size: 11px; font-weight: bold; position: relative; z-index: 1; }
    .ss-mockup-body { padding: 8px; font-size: 9px; color: #444; background: #fff; flex-grow: 1;}
    .ss-bg-red { background: #b71c1c; }
    .ss-bg-blue { background: #1565c0; }
    .ss-bg-green { background: #1b5e20; }
    
    .ss-inner-list { list-style: none; padding: 0; margin: 0; }
    .ss-inner-list li { margin-bottom: 6px; display: flex; align-items: flex-start; border-bottom: 1px solid #f0f0f0; padding-bottom: 4px; line-height: 1.2; }
    .ss-inner-list li:last-child { border-bottom: none; margin-bottom: 0; padding-bottom: 0; }
    .ss-inner-list li svg { width: 10px; height: 10px; margin-right: 4px; flex-shrink: 0; margin-top: 1px; }
    
    /* Features List */
    .ss-feature-list { list-style: none; padding: 0; margin: 0; font-size: 13px; font-weight: 600; display: flex; flex-direction: column; justify-content: center; }
    .ss-feature-list li { margin-bottom: 10px; display: flex; align-items: flex-start; line-height: 1.3; }
    .ss-feature-list li svg { width: 16px; height: 16px; margin-right: 8px; flex-shrink: 0; margin-top: 2px; }
    .ss-text-red { color: #b71c1c; }
    .ss-text-blue { color: #1565c0; }
    .ss-text-green { color: #1b5e20; }
    
    /* Footer Banner */
    .ss-banner-footer {
      background: #1a7138;
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 15px 30px;
      color: white;
      flex-wrap: wrap;
      gap: 15px;
    }
    .ss-footer-left { display: flex; align-items: center; gap: 15px; }
    .ss-footer-left-icon {
      background: white; width: 45px; height: 45px; border-radius: 8px; display: flex; align-items: center; justify-content: center;
    }
    .ss-footer-left-icon svg { width: 28px; height: 28px; }
    .ss-footer-left h4 { margin: 0; font-size: 22px; font-weight: bold; }
    .ss-footer-left p { margin: 0; font-size: 14px; opacity: 0.9; }
    .ss-footer-right { display: flex; gap: 15px; }
    .ss-footer-right img { height: 40px; cursor: pointer; border-radius: 6px; border: 1px solid rgba(255,255,255,0.2); }
    
    @media (max-width: 991px) {
      .ss-banner-body { grid-template-columns: 1fr; }
      .ss-bottom-section { flex-direction: row; }
      .ss-banner-header { flex-direction: column; text-align: center; }
      .ss-footer-left { flex-direction: column; text-align: center; }
      .ss-banner-footer { justify-content: center; }
    }
'''

new_html = '''        <div class="smart-solutions-banner">
          <div class="ss-banner-header">
            <div class="ss-logo-block">
              <div class="ss-logo-icon">
                <svg viewBox="0 0 24 24" fill="white" stroke="white" stroke-width="1" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                  <polyline points="9 22 9 12 15 12 15 22"></polyline>
                  <circle cx="12" cy="7" r="2" fill="#1a7138"></circle>
                </svg>
              </div>
              <div class="ss-logo-text">আমার<br>ঠিকানা</div>
            </div>
            <div>
              <h3>বাসা খোঁজা, ভাড়া দেওয়া আর লেনদেন সমস্যা?<br><span>সমাধান একটাই – আমার ঠিকানা অ্যাপ</span></h3>
            </div>
          </div>
          
          <div class="ss-banner-body">
            <!-- Column 1: Search -->
            <div class="ss-col ss-col-1">
              <div class="ss-image-container">
                <div class="ss-tab ss-tab-red">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                  বাসা খোঁজা
                </div>
                <img src="https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=400&q=80" alt="Thinking Man" class="person">
                <div class="ss-bubble ss-bubble-red">ভালো লোকেশন, সাশ্রয়ী ভাড়া, নির্ভরযোগ্য বাসা কোথায় পাবো?</div>
              </div>
              <div class="ss-bottom-section">
                <div class="ss-app-mockup">
                  <div class="ss-app-mockup-header ss-bg-red">
                    <span>&larr; বাসা খোঁজা</span>
                  </div>
                  <div class="ss-mockup-body">
                    <ul class="ss-inner-list">
                      <li><svg viewBox="0 0 24 24" fill="#b71c1c"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> মিরপুর <br> ২ রুম, ২ বাথ <br> ৳ ১২,০০০ / মাস</li>
                      <li><svg viewBox="0 0 24 24" fill="#b71c1c"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ধানমন্ডি <br> ৩ রুম, ২ বাথ <br> ৳ ২৫,০০০ / মাস</li>
                    </ul>
                  </div>
                </div>
                <ul class="ss-feature-list ss-text-red">
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> সহজে খুঁজে নিন আপনার পছন্দের বাসা</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> লোকেশন, বাজেট ও সুবিধা দিয়ে ফিল্টার</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ছবি, বিবরণ ও মালিকের তথ্য দেখুন</li>
                </ul>
              </div>
            </div>
            
            <!-- Column 2: Rent -->
            <div class="ss-col ss-col-2">
              <div class="ss-image-container">
                <div class="ss-tab ss-tab-blue">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>
                  ভাড়া দেওয়া
                </div>
                <img src="https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=400&q=80" alt="Happy Landlord" class="person">
                <div class="ss-bubble ss-bubble-blue">বিশ্বস্ত ভাড়াটে পাবো তো? ভাড়া আদায় হবে তো?</div>
              </div>
              <div class="ss-bottom-section">
                <div class="ss-app-mockup">
                  <div class="ss-app-mockup-header ss-bg-blue">
                    <span>&larr; ভাড়া দেওয়া</span>
                  </div>
                  <div class="ss-mockup-body">
                    <ul class="ss-inner-list">
                      <li><svg viewBox="0 0 24 24" fill="#1565c0"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> মাই প্রপার্টি</li>
                      <li><svg viewBox="0 0 24 24" fill="#1565c0"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ভাড়াটে খুঁজুন</li>
                      <li><svg viewBox="0 0 24 24" fill="#1565c0"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> চুক্তি ও ভাড়া</li>
                    </ul>
                  </div>
                </div>
                <ul class="ss-feature-list ss-text-blue">
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> সহজে প্রপার্টি লিস্ট করুন</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> বিশ্বস্ত ভাড়াটে খুঁজুন</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> চুক্তি ও ভাড়া ব্যবস্থাপনা করুন</li>
                </ul>
              </div>
            </div>
            
            <!-- Column 3: Security -->
            <div class="ss-col ss-col-3">
              <div class="ss-image-container">
                <div class="ss-tab ss-tab-green">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
                  লেনদেন সমস্যা
                </div>
                <img src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80" alt="Worried Woman" class="person">
                <div class="ss-bubble ss-bubble-green">অগ্রিম টাকা, চুক্তি, ভাড়া নিয়ে ঝামেলা... কী করবো?</div>
              </div>
              <div class="ss-bottom-section">
                <div class="ss-app-mockup">
                  <div class="ss-app-mockup-header ss-bg-green">
                    <span>&larr; লেনদেন সুরক্ষা</span>
                  </div>
                  <div class="ss-mockup-body">
                    <ul class="ss-inner-list">
                      <li><svg viewBox="0 0 24 24" fill="#1b5e20"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ডিজিটাল চুক্তি</li>
                      <li><svg viewBox="0 0 24 24" fill="#1b5e20"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> নিরাপদ পেমেন্ট</li>
                      <li><svg viewBox="0 0 24 24" fill="#1b5e20"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> পেমেন্ট হিস্ট্রি</li>
                    </ul>
                  </div>
                </div>
                <ul class="ss-feature-list ss-text-green">
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ডিজিটাল চুক্তি ও নিরাপদ লেনদেন</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ভাড়া ও পেমেন্ট ট্র্যাক করুন</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> সমস্যা হলে সাপোর্ট টিম পাশে আছে</li>
                </ul>
              </div>
            </div>
          </div>
          
          <div class="ss-banner-footer">
            <div class="ss-footer-left">
              <div class="ss-footer-left-icon">
                <svg viewBox="0 0 24 24" fill="#1a7138" stroke="#1a7138" stroke-width="1" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                  <polyline points="9 22 9 12 15 12 15 22"></polyline>
                </svg>
              </div>
              <div>
                <h4>আমার ঠিকানা</h4>
                <p>সহজে বাসা খুঁজুন, ভাড়া দিন, নিরাপদ লেনদেন করুন</p>
              </div>
            </div>
            <div class="ss-footer-right">
              <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" title="Google Play">
              <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt="Download on the App Store" title="App Store">
            </div>
          </div>
        </div>\n'''

# Replace CSS
start_css = -1
end_css = -1
for i, line in enumerate(lines):
    if '/* Smart Solutions Banner */' in line or '/* Smart Solutions Banner (Hubuhu Redesign) */' in line:
        start_css = i
    if '/* SOS Showcase Section */' in line and start_css != -1:
        end_css = i
        break

if start_css != -1 and end_css != -1:
    lines = lines[:start_css] + [new_css + '\n'] + lines[end_css:]

# Replace HTML
start_html = -1
end_html = -1
for i, line in enumerate(lines):
    if '<div class="smart-solutions-banner">' in line:
        start_html = i
    if '<div class="sos-showcase-section">' in line and start_html != -1:
        end_html = i
        break

if start_html != -1 and end_html != -1:
    lines = lines[:start_html] + [new_html + '\n'] + lines[end_html:]

with open(filename, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print('Hubuhu design injected successfully.')
