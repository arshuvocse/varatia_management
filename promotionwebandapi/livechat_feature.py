import sys

filename = 'd:/Shuvo/project Idea/Babu Project/Varatia_management/promotionwebandapi/wwwroot/landing.html'
with open(filename, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 1. Add Animation CSS
for i, line in enumerate(lines):
    if '.chat-launcher {' in line and 'pulseGlow' not in line:
        lines[i] = line.replace('.chat-launcher {', '.chat-launcher { animation: pulseGlow 2s infinite; ')
        lines.insert(i+1, '''    @keyframes pulseGlow {
      0% { box-shadow: 0 0 0 0 rgba(56, 239, 125, 0.7); transform: scale(1); }
      70% { box-shadow: 0 0 0 15px rgba(56, 239, 125, 0); transform: scale(1.05); }
      100% { box-shadow: 0 0 0 0 rgba(56, 239, 125, 0); transform: scale(1); }
    }\n''')
        break

# 2. Hide existing chat UI initially, add form
pre_chat_form = '''    <div class="chat-pre-form" id="chatPreForm" style="padding: 20px;">
      <h4 style="margin-top:0; font-size:16px; margin-bottom:15px;">চ্যাট শুরু করতে আপনার তথ্য দিন</h4>
      <input type="text" id="preChatName" placeholder="আপনার পুরো নাম" style="width:100%; padding:10px; margin-bottom:10px; border:1px solid #ccc; border-radius:8px; font-size:14px; box-sizing:border-box;" required>
      <input type="text" id="preChatMobile" placeholder="মোবাইল নম্বর" style="width:100%; padding:10px; margin-bottom:15px; border:1px solid #ccc; border-radius:8px; font-size:14px; box-sizing:border-box;" required>
      <button type="button" id="startChatBtn" style="width:100%; padding:12px; background:linear-gradient(135deg, #11998e, #38ef7d); color:white; border:none; border-radius:8px; font-weight:bold; cursor:pointer; font-size:15px; transition: 0.2s;">চ্যাট শুরু করুন</button>
    </div>
'''

for i, line in enumerate(lines):
    if '<div class="chat-messages"' in line and 'id="chatMessages"' in line:
        if 'display:none' not in line:
            lines[i] = line.replace('class="chat-messages"', 'class="chat-messages" style="display:none;"')
        lines.insert(i, pre_chat_form)
        break

for i, line in enumerate(lines):
    if '<div class="chat-input-area"' in line:
        if 'display:none' not in line:
            lines[i] = line.replace('class="chat-input-area"', 'class="chat-input-area" style="display:none;"')
        break

# 3. Add JS logic
js_code = '''
    const startChatBtn = document.getElementById('startChatBtn');
    const chatPreForm = document.getElementById('chatPreForm');
    const chatMessagesEl = document.getElementById('chatMessages');
    const chatInputAreaEl = document.querySelector('.chat-input-area');
    
    if(startChatBtn) {
      startChatBtn.addEventListener('click', async () => {
        const name = document.getElementById('preChatName').value.trim();
        const mobile = document.getElementById('preChatMobile').value.trim();
        
        if(!name || !mobile) {
          alert('দয়া করে আপনার নাম এবং মোবাইল নম্বর দিন।');
          return;
        }
        
        startChatBtn.innerText = 'অপেক্ষা করুন...';
        startChatBtn.disabled = true;
        
        try {
          const res = await fetch('/api/LiveChatApi/start', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ FullName: name, MobileNumber: mobile })
          });
          
          if(res.ok) {
            chatPreForm.style.display = 'none';
            chatMessagesEl.style.display = 'flex'; // or whatever the original was
            chatInputAreaEl.style.display = 'block'; // or flex
            // Add a welcome message
            const msg = document.createElement('div');
            msg.className = 'chat-message received';
            msg.innerHTML = `<div class="msg-bubble">হ্যালো ${name}! কিভাবে আপনাকে সাহায্য করতে পারি?</div>`;
            chatMessagesEl.appendChild(msg);
          } else {
            alert('সার্ভার সমস্যা, পরে আবার চেষ্টা করুন।');
            startChatBtn.innerText = 'চ্যাট শুরু করুন';
            startChatBtn.disabled = false;
          }
        } catch(e) {
          console.error(e);
          alert('সংযোগ সমস্যা!');
          startChatBtn.innerText = 'চ্যাট শুরু করুন';
          startChatBtn.disabled = false;
        }
      });
    }
'''

for i, line in enumerate(lines):
    if 'const chatLauncher = document.querySelector' in line:
        lines.insert(i, js_code)
        break

with open(filename, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print('Live chat UI injected successfully.')
