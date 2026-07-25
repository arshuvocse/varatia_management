import sys

html_code = """          <div class="ss-banner-body ss-billboard-layout">
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
                    <span><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg></span>
                  </div>
                  <div class="ss-mockup-body">
                    <div class="ss-prop-card">
                      <div class="ss-prop-img" style="background-image: url('https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=100&q=80')"></div>
                      <div class="ss-prop-details">
                        <strong>মিরপুর</strong>
                        <span>৩ রুম, ২ বাথ</span>
                        <span class="price">৳ ১২,০০০/মাস</span>
                      </div>
                    </div>
                    <div class="ss-prop-card">
                      <div class="ss-prop-img" style="background-image: url('https://images.unsplash.com/photo-1502672260266-1c1de2d93688?auto=format&fit=crop&w=100&q=80')"></div>
                      <div class="ss-prop-details">
                        <strong>মিরপুর</strong>
                        <span>২ রুম, ১ বাথ</span>
                        <span class="price">৳ ১০,০০০/মাস</span>
                      </div>
                    </div>
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
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path></svg>
                ভাড়া দেওয়া
              </div>
              <div class="ss-image-container">
                <img src="https://images.unsplash.com/photo-1556157382-97eda2d62296?auto=format&fit=crop&w=400&q=80" alt="Smiling Man" class="person">
                <div class="ss-bubble ss-bubble-blue">বিশ্বস্ত ভাড়াটে পাবো তো? ভাড়া আদায় হবে তো?</div>
              </div>
              <div class="ss-bottom-section">
                <div class="ss-app-mockup">
                  <div class="ss-app-mockup-header ss-bg-blue">
                    <span>&larr; ভাড়া দেওয়া</span>
                  </div>
                  <div class="ss-mockup-body">
                    <div class="ss-prop-card">
                      <div class="ss-prop-img" style="background-image: url('https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=100&q=80')"></div>
                      <div class="ss-prop-details">
                        <strong>ধানমন্ডি</strong>
                        <span>২ রুম, ২ বাথ</span>
                        <span class="price">৳ ১৬,০০০/মাস</span>
                      </div>
                    </div>
                    <div class="ss-prop-card">
                      <div class="ss-prop-img" style="background-image: url('https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=100&q=80')"></div>
                      <div class="ss-prop-details">
                        <strong>মিরপুর</strong>
                        <span>৩ রুম, ২ বাথ</span>
                        <span class="price">৳ ২০,০০০/মাস</span>
                      </div>
                    </div>
                  </div>
                </div>
                <ul class="ss-feature-list ss-text-blue">
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> সহজে প্রপার্টি লিস্ট করুন</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> বিশ্বস্ত ভাড়াটে খুঁজুন</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> চুক্তি ও ভাড়া ব্যবস্থাপনা করুন</li>
                </ul>
              </div>
            </div>

            <!-- Column 3: Transaction -->
            <div class="ss-col ss-col-3">
              <div class="ss-badge">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"></path><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"></path></svg>
                লেনদেন সমস্যা
              </div>
              <div class="ss-image-container">
                <img src="https://images.unsplash.com/photo-1620608779956-621b34e56598?auto=format&fit=crop&w=400&q=80" alt="Worried Woman" class="person">
                <div class="ss-bubble ss-bubble-green">অগ্রিম টাকা, ব্লক, চুক্তি, ভাড়া নিয়ে ঝামেলা... কি করবো?</div>
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
                      <li><svg viewBox="0 0 24 24" fill="#28a745"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> পেমেন্ট ইতিহাস</li>
                      <li><svg viewBox="0 0 24 24" fill="#1f6baf"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> সাহায্য ও সাপোর্ট</li>
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
          </div>"""

css_code = """
    /* New Billboard Layout CSS */
    .ss-billboard-layout .ss-bottom-section {
      display: flex;
      flex-direction: row;
      align-items: center;
      background: #f8f9fa;
      margin: 15px;
      border-radius: 12px;
      padding: 10px;
    }
    .ss-billboard-layout .ss-app-mockup {
      width: 140px;
      min-width: 140px;
      margin: 0;
      border: 3px solid #333;
      border-radius: 12px;
      border-bottom: none;
      box-shadow: 0 5px 15px rgba(0,0,0,0.1);
    }
    .ss-billboard-layout .ss-app-mockup-header {
      padding: 8px;
      font-size: 10px;
      border-radius: 9px 9px 0 0;
    }
    .ss-billboard-layout .ss-mockup-body {
      padding: 5px;
      background: #f4f4f4;
      min-height: 120px;
    }
    .ss-prop-card {
      background: #fff;
      border-radius: 6px;
      padding: 4px;
      margin-bottom: 5px;
      display: flex;
      flex-direction: row;
      gap: 5px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }
    .ss-prop-img {
      width: 30px;
      height: 30px;
      border-radius: 4px;
      background-size: cover;
      background-position: center;
    }
    .ss-prop-details {
      display: flex;
      flex-direction: column;
      font-size: 8px;
      line-height: 1.1;
      color: #555;
    }
    .ss-prop-details strong { font-size: 9px; color: #111; }
    .ss-prop-details .price { font-weight: bold; color: #d32f2f; }
    
    .ss-inner-list { list-style: none; padding: 5px; margin: 0; }
    .ss-inner-list li { font-size: 9px; display: flex; align-items: center; gap: 4px; margin-bottom: 8px; color: #333; font-weight: 500; }
    .ss-inner-list svg { width: 12px; height: 12px; }

    .ss-billboard-layout .ss-feature-list {
      flex: 1;
      padding: 10px 10px 10px 15px;
      background: transparent;
    }
    .ss-billboard-layout .ss-feature-list li {
      font-size: 11px;
      margin-bottom: 10px;
    }
    .ss-billboard-layout .ss-feature-list li svg { width: 14px; height: 14px; }
    
    .ss-bg-red { background: #b02a2a !important; }
    .ss-bg-blue { background: #1f6baf !important; }
    .ss-bg-green { background: #2f5c42 !important; }
    .ss-text-red li svg { color: #b02a2a !important; }
    .ss-text-blue li svg { color: #1f6baf !important; }
    .ss-text-green li svg { color: #2f5c42 !important; }
    
    .ss-bubble-red { color: #b02a2a !important; border: 1px solid #b02a2a; }
    .ss-bubble-blue { color: #1f6baf !important; border: 1px solid #1f6baf; }
    .ss-bubble-green { color: #2f5c42 !important; border: 1px solid #2f5c42; }
    
    @media (max-width: 992px) {
      .ss-billboard-layout .ss-bottom-section { flex-direction: column; }
      .ss-billboard-layout .ss-app-mockup { width: 200px; }
    }
"""

filename = "d:/Shuvo/project Idea/Babu Project/Varatia_management/promotionwebandapi/wwwroot/landing.html"
with open(filename, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the start of the banner body
start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if '<div class="ss-banner-body">' in line:
        start_idx = i
        break

if start_idx != -1:
    # Find the end of the banner body (the </div> right before <div class="ss-banner-footer">)
    # We will search for ss-banner-footer
    footer_idx = -1
    for i in range(start_idx, len(lines)):
        if '<div class="ss-banner-footer">' in line:
            footer_idx = i
            break
            
    if footer_idx != -1:
        # Find the closing div of ss-banner-body
        for i in range(footer_idx - 1, start_idx, -1):
            if '</div>' in lines[i]:
                end_idx = i
                break

# Inject new HTML
if start_idx != -1 and end_idx != -1:
    lines = lines[:start_idx] + [html_code + '\\n'] + lines[end_idx+1:]
    
    # Now inject CSS
    css_insert_idx = -1
    for i, line in enumerate(lines):
        if '</style>' in line:
            css_insert_idx = i
            break
            
    if css_insert_idx != -1:
        lines.insert(css_insert_idx, css_code + '\\n')
        
    with open(filename, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print("Successfully replaced HTML and CSS.")
else:
    print("Could not find boundaries.")
