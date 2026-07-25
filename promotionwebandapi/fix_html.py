import sys
filename = 'd:/Shuvo/project Idea/Babu Project/Varatia_management/promotionwebandapi/wwwroot/landing.html'
with open(filename, 'r', encoding='utf-8') as f:
    lines = f.readlines()

html_code = '''          <div class="ss-banner-body ss-billboard-layout">
            <!-- Column 1: Search -->
            <div class="ss-col ss-col-1">
              <div class="ss-badge">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                ???? ?????
              </div>
              <div class="ss-image-container">
                <img src="https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=400&q=80" alt="Thinking Man" class="person">
                <div class="ss-bubble ss-bubble-red">???? ??????, ??????? ????, ??????????? ???? ????? ?????</div>
              </div>
              <div class="ss-bottom-section">
                <div class="ss-app-mockup">
                  <div class="ss-app-mockup-header ss-bg-red">
                    <span>&larr; ???? ?????</span>
                    <span><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg></span>
                  </div>
                  <div class="ss-mockup-body">
                    <div class="ss-prop-card">
                      <div class="ss-prop-img" style="background-image: url('https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=100&q=80')"></div>
                      <div class="ss-prop-details">
                        <strong>??????</strong>
                        <span>? ???, ? ???</span>
                        <span class="price">? ??,???/???</span>
                      </div>
                    </div>
                    <div class="ss-prop-card">
                      <div class="ss-prop-img" style="background-image: url('https://images.unsplash.com/photo-1502672260266-1c1de2d93688?auto=format&fit=crop&w=100&q=80')"></div>
                      <div class="ss-prop-details">
                        <strong>??????</strong>
                        <span>? ???, ? ???</span>
                        <span class="price">? ??,???/???</span>
                      </div>
                    </div>
                  </div>
                </div>
                <ul class="ss-feature-list ss-text-red">
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ???? ????? ??? ????? ??????? ????</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ??????, ????? ? ?????? ???? ???????</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ???, ????? ? ??????? ???? ?????</li>
                </ul>
              </div>
            </div>

            <!-- Column 2: Rent -->
            <div class="ss-col ss-col-2">
              <div class="ss-badge">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path></svg>
                ???? ?????
              </div>
              <div class="ss-image-container">
                <img src="https://images.unsplash.com/photo-1556157382-97eda2d62296?auto=format&fit=crop&w=400&q=80" alt="Smiling Man" class="person">
                <div class="ss-bubble ss-bubble-blue">???????? ?????? ???? ??? ???? ???? ??? ???</div>
              </div>
              <div class="ss-bottom-section">
                <div class="ss-app-mockup">
                  <div class="ss-app-mockup-header ss-bg-blue">
                    <span>&larr; ???? ?????</span>
                  </div>
                  <div class="ss-mockup-body">
                    <div class="ss-prop-card">
                      <div class="ss-prop-img" style="background-image: url('https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=100&q=80')"></div>
                      <div class="ss-prop-details">
                        <strong>????????</strong>
                        <span>? ???, ? ???</span>
                        <span class="price">? ??,???/???</span>
                      </div>
                    </div>
                    <div class="ss-prop-card">
                      <div class="ss-prop-img" style="background-image: url('https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=100&q=80')"></div>
                      <div class="ss-prop-details">
                        <strong>??????</strong>
                        <span>? ???, ? ???</span>
                        <span class="price">? ??,???/???</span>
                      </div>
                    </div>
                  </div>
                </div>
                <ul class="ss-feature-list ss-text-blue">
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ???? ????????? ????? ????</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ???????? ?????? ??????</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ?????? ? ???? ??????????? ????</li>
                </ul>
              </div>
            </div>

            <!-- Column 3: Transaction -->
            <div class="ss-col ss-col-3">
              <div class="ss-badge">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"></path><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"></path></svg>
                ?????? ??????
              </div>
              <div class="ss-image-container">
                <img src="https://images.unsplash.com/photo-1620608779956-621b34e56598?auto=format&fit=crop&w=400&q=80" alt="Worried Woman" class="person">
                <div class="ss-bubble ss-bubble-green">?????? ????, ????, ??????, ???? ???? ??????... ?? ?????</div>
              </div>
              <div class="ss-bottom-section">
                <div class="ss-app-mockup">
                  <div class="ss-app-mockup-header ss-bg-green">
                    <span>&larr; ?????? ???????</span>
                  </div>
                  <div class="ss-mockup-body">
                    <ul class="ss-inner-list">
                      <li><svg viewBox="0 0 24 24" fill="#28a745"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ??????? ??????</li>
                      <li><svg viewBox="0 0 24 24" fill="#28a745"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ?????? ???????</li>
                      <li><svg viewBox="0 0 24 24" fill="#28a745"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ??????? ??????</li>
                      <li><svg viewBox="0 0 24 24" fill="#1f6baf"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ??????? ? ???????</li>
                    </ul>
                  </div>
                </div>
                <ul class="ss-feature-list ss-text-green">
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ??????? ?????? ? ?????? ??????</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ???? ? ??????? ??????? ????</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ?????? ??? ??????? ??? ???? ???</li>
                </ul>
              </div>
            </div>
          </div>\n'''

start_idx = 2600 # line 2601
end_idx = 2697 # line 2697
lines[start_idx:end_idx] = [html_code]

with open(filename, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print('Fixed HTML syntax')
