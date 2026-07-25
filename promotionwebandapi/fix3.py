import sys

filename = 'd:/Shuvo/project Idea/Babu Project/Varatia_management/promotionwebandapi/wwwroot/landing.html'
with open(filename, 'r', encoding='utf-8') as f:
    lines = f.readlines()

css_code = '''
    /* New Billboard Layout CSS */
    .ss-billboard-layout .ss-bottom-section {
      display: flex;
      flex-direction: row;
      align-items: center;
      background: #f8f9fa;
      margin: 15px;
      border-radius: 12px;
      padding: 15px;
      box-shadow: inset 0 2px 5px rgba(0,0,0,0.05);
    }
    .ss-billboard-layout .ss-app-mockup {
      width: 160px;
      background: white;
      border-radius: 12px;
      box-shadow: 0 4px 15px rgba(0,0,0,0.1);
      overflow: hidden;
      border: 3px solid #333;
      margin-right: 15px;
      flex-shrink: 0;
    }
    .ss-billboard-layout .ss-app-mockup-header {
      padding: 8px;
      color: white;
      font-size: 0.75rem;
      font-weight: bold;
    }
    .ss-billboard-layout .ss-mockup-body {
      padding: 10px;
      font-size: 0.65rem;
      color: #555;
    }
    .ss-billboard-layout .ss-bg-red { background: #d93025; }
    .ss-billboard-layout .ss-bg-blue { background: #1f6baf; }
    .ss-billboard-layout .ss-bg-green { background: #28a745; }
    
    .ss-billboard-layout .ss-inner-list {
      list-style: none;
      padding: 0;
      margin: 0;
    }
    .ss-billboard-layout .ss-inner-list li {
      margin-bottom: 6px;
      display: flex;
      align-items: flex-start;
      border-bottom: 1px solid #eee;
      padding-bottom: 4px;
    }
    .ss-billboard-layout .ss-inner-list li:last-child {
      border-bottom: none;
      margin-bottom: 0;
      padding-bottom: 0;
    }
    .ss-billboard-layout .ss-inner-list li svg {
      width: 12px;
      height: 12px;
      margin-right: 5px;
      flex-shrink: 0;
      margin-top: 2px;
    }
    
    .ss-billboard-layout .ss-feature-list {
      list-style: none;
      padding: 0;
      margin: 0;
      font-size: 0.8rem;
      font-weight: 500;
    }
    .ss-billboard-layout .ss-feature-list li {
      margin-bottom: 8px;
      display: flex;
      align-items: center;
    }
    .ss-billboard-layout .ss-feature-list li svg {
      width: 16px;
      height: 16px;
      margin-right: 8px;
      flex-shrink: 0;
    }
    .ss-billboard-layout .ss-text-red { color: #d93025; }
    .ss-billboard-layout .ss-text-blue { color: #1f6baf; }
    .ss-billboard-layout .ss-text-green { color: #28a745; }
    
    @media (max-width: 991px) {
      .ss-billboard-layout .ss-bottom-section {
        flex-direction: column;
      }
      .ss-billboard-layout .ss-app-mockup {
        width: 200px;
        margin-right: 0;
        margin-bottom: 15px;
      }
    }
'''

html_code = '''          <div class="ss-banner-body ss-billboard-layout">
            <!-- Column 1: Search -->
            <div class="ss-col ss-col-1">
              <div class="ss-badge">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                বাসা খোঁজা
              </div>
              <div class="ss-image-container">
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
                      <li><svg viewBox="0 0 24 24" fill="#d93025"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> মিরপুর <br> ২ রুম, ২ বাথ <br> ৳ ১২,০০০ / মাস</li>
                      <li><svg viewBox="0 0 24 24" fill="#d93025"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> মিরপুর <br> ২ রুম, ২ বাথ <br> ৳ ১৫,০০০ / মাস</li>
                      <li><svg viewBox="0 0 24 24" fill="#d93025"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> মিরপুর <br> ৩ রুম, ২ বাথ <br> ৳ ১৯,০০০ / মাস</li>
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
              <div class="ss-badge">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>
                ভাড়া দেওয়া
              </div>
              <div class="ss-image-container">
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
                      <li><svg viewBox="0 0 24 24" fill="#1f6baf"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> মাই প্রপার্টি</li>
                      <li><svg viewBox="0 0 24 24" fill="#1f6baf"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ভাড়াটে খুঁজুন</li>
                      <li><svg viewBox="0 0 24 24" fill="#1f6baf"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> চুক্তি ও ভাড়া</li>
                      <li><svg viewBox="0 0 24 24" fill="#1f6baf"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ধানমন্ডি, ঢাকা <br> ২ রুম, ২ বাথ <br> ৳ ১৫,০০০ / মাস</li>
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
              <div class="ss-badge">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
                লেনদেন সমস্যা
              </div>
              <div class="ss-image-container">
                <img src="https://images.unsplash.com/photo-1620608779956-621b34e56598?auto=format&fit=crop&w=400&q=80" alt="Worried Woman" class="person">
                <div class="ss-bubble ss-bubble-green">অগ্রিম টাকা, চুক্তি, ভাড়া নিয়ে ঝামেলা... কী করবো?</div>
              </div>
              <div class="ss-bottom-section">
                <div class="ss-app-mockup">
                  <div class="ss-app-mockup-header ss-bg-green">
                    <span>&larr; লেনদেন সুরক্ষা</span>
                  </div>
                  <div class="ss-mockup-body">
                    <ul class="ss-inner-list">
                      <li><svg viewBox="0 0 24 24" fill="#28a745"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ডিজিটাল চুক্তি</li>
                      <li><svg viewBox="0 0 24 24" fill="#28a745"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> নিরাপদ পেমেন্ট</li>
                      <li><svg viewBox="0 0 24 24" fill="#28a745"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> পেমেন্ট হিস্ট্রি</li>
                      <li><svg viewBox="0 0 24 24" fill="#1f6baf"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> সহায়তা ও সাপোর্ট</li>
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
          </div>\n'''

start_idx = -1
end_idx = -1
for i, line in enumerate(lines):
    if '<div class="ss-banner-body" style="display:flex; justify-content:center; padding: 20px;">' in line:
        start_idx = i
    if '<div class="ss-banner-footer">' in line and start_idx != -1:
        end_idx = i
        break

if start_idx != -1 and end_idx != -1:
    lines[start_idx:end_idx] = [html_code]
    
    # Check if css_code already exists
    css_exists = False
    for line in lines:
        if '/* New Billboard Layout CSS */' in line:
            css_exists = True
            break
            
    if not css_exists:
        css_start = -1
        for i, line in enumerate(lines):
            if '/* Smart Solutions Banner */' in line:
                css_start = i
                break
        if css_start != -1:
            lines.insert(css_start, css_code + '\n')
            
    with open(filename, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print('Restored HTML billboard layout successfully.')
else:
    print('Could not find boundaries to restore billboard layout.')
