import re

with open('promotionwebandapi/wwwroot/landing.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace CSS
css_old = r'''.live-chat \{ position: fixed; right: 22px; bottom: 22px; z-index: 60; font-family: "Anek Bangla", sans-serif; \}.*?\.chat-form button \{ border: 0; border-radius: 14px; padding: 10px 13px; color: #fff; background: var\(--primary\); font-weight: 900; cursor: pointer; \}'''
css_new = r'''    .live-chat { position: fixed; right: 22px; bottom: 22px; z-index: 60; font-family: "Anek Bangla", sans-serif; }
    .chat-launcher { display: flex; align-items: center; gap: 10px; border: 0; border-radius: 999px; padding: 12px 14px 12px 18px; color: #fff; background: linear-gradient(135deg, #11998e, #38ef7d); box-shadow: 0 15px 35px rgba(56, 239, 125, 0.4); cursor: pointer; transition: 0.3s; }
    .chat-launcher:hover { transform: translateY(-3px); box-shadow: 0 20px 40px rgba(56, 239, 125, 0.6); }
    .chat-launcher span { font-weight: 900; }
    .chat-launcher strong { width: 30px; height: 30px; display: grid; place-items: center; border-radius: 50%; background: rgba(255,255,255,.22); }
    
    .chat-panel { display: none; width: min(360px, calc(100vw - 28px)); margin-bottom: 12px; overflow: hidden; border-radius: 24px; background: rgba(255, 255, 255, 0.9); box-shadow: 0 28px 80px rgba(0, 0, 0, 0.2); backdrop-filter: blur(15px); border: 1px solid rgba(255,255,255,0.4); }
    .live-chat.open .chat-panel { display: block; animation: slideUp 0.3s ease-out; }
    @keyframes slideUp { from { transform: translateY(20px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
    
    .chat-header { display: flex; justify-content: space-between; gap: 12px; align-items: center; padding: 20px; color: #fff; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
    .chat-header strong { display: block; font-size: 1.1rem; }
    .chat-header small { display: block; color: rgba(255,255,255,.8); font-size: 0.85rem; }
    .chat-close { border: 0; background: rgba(255,255,255,.2); color: #fff; width: 34px; height: 34px; border-radius: 50%; cursor: pointer; font-size: 20px; transition: 0.3s; }
    .chat-close:hover { background: rgba(255,255,255,.4); transform: rotate(90deg); }
    
    .chat-messages { padding: 20px; height: 300px; max-height: 50vh; overflow-y: auto; background: rgba(248, 251, 255, 0.6); display: flex; flex-direction: column; gap: 12px; }
    .chat-messages::-webkit-scrollbar { width: 6px; }
    .chat-messages::-webkit-scrollbar-thumb { background: rgba(118, 75, 162, 0.3); border-radius: 10px; }
    
    .chat-bubble { width: fit-content; max-width: 85%; padding: 12px 16px; border-radius: 18px; line-height: 1.4; font-size: 0.95rem; box-shadow: 0 4px 15px rgba(0,0,0,0.05); }
    .chat-bubble.support { background: linear-gradient(135deg, #fdfbfb 0%, #ebedee 100%); color: #333; border-bottom-left-radius: 5px; display: flex; gap: 10px; align-items: flex-end; }
    .chat-bubble.user { margin-left: auto; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #fff; border-bottom-right-radius: 5px; }
    
    .chat-avatar { width: 28px; height: 28px; border-radius: 50%; object-fit: cover; box-shadow: 0 2px 5px rgba(0,0,0,0.2); }
    .chat-quick { display: flex; gap: 8px; flex-wrap: wrap; padding: 10px 20px 15px; background: rgba(248, 251, 255, 0.6); }
    .chat-quick button { border: 1px solid rgba(118, 75, 162, 0.3); background: rgba(255,255,255,0.8); color: #764ba2; padding: 6px 14px; border-radius: 999px; font-weight: bold; cursor: pointer; transition: 0.2s; font-size: 0.85rem; }
    .chat-quick button:hover { background: #764ba2; color: #fff; }
    
    .chat-form { display: flex; gap: 10px; padding: 15px; border-top: 1px solid rgba(0,0,0,0.05); background: #fff; }
    .chat-form input { flex: 1; border: 1px solid rgba(0,0,0,0.1); background: rgba(240, 240, 245, 0.5); outline: 0; border-radius: 20px; padding: 12px 15px; transition: 0.3s; }
    .chat-form input:focus { border-color: #764ba2; background: #fff; box-shadow: 0 0 0 3px rgba(118, 75, 162, 0.1); }
    .chat-form button { border: 0; border-radius: 50%; width: 45px; height: 45px; display: grid; place-items: center; color: #fff; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); font-weight: 900; cursor: pointer; transition: 0.3s; box-shadow: 0 4px 15px rgba(118, 75, 162, 0.4); }
    .chat-form button:hover { transform: scale(1.05); }
    .chat-form button:disabled { opacity: 0.5; cursor: not-allowed; }'''
content = re.sub(css_old, css_new, content, flags=re.DOTALL)

# Add SignalR script right before closing body tag
if '<script src="https://cdnjs.cloudflare.com/ajax/libs/microsoft-signalr/6.0.1/signalr.min.js"></script>' not in content:
    content = content.replace('</body>', '  <script src="https://cdnjs.cloudflare.com/ajax/libs/microsoft-signalr/6.0.1/signalr.min.js"></script>\n</body>')

# Replace Javascript logic
js_new = '''    let chatSessionId = localStorage.getItem('liveChatSessionId');
    let isLive = false;
    let chatConnection = null;

    if (!chatSessionId) {
        chatSessionId = 'guest_' + Math.random().toString(36).substr(2, 9);
        localStorage.setItem('liveChatSessionId', chatSessionId);
    }

    async function initLiveChat(name, phone) {
        if (chatConnection) return;
        
        chatConnection = new signalR.HubConnectionBuilder()
            .withUrl("/hubs/live-support")
            .withAutomaticReconnect()
            .build();
            
        chatConnection.on("ReceiveMessage", (msg) => {
            const msgs = document.querySelector('.chat-messages');
            const div = document.createElement('div');
            if (msg.senderType === 'Agent') {
                div.className = 'chat-bubble support';
                const pic = msg.agentProfilePictureUrl || '/images/default-avatar.png';
                div.innerHTML = <img src="" class="chat-avatar" alt="Agent"> <span></span>;
            } else {
                div.className = 'chat-bubble user';
                div.textContent = msg.messageText;
            }
            msgs.appendChild(div);
            msgs.scrollTop = msgs.scrollHeight;
        });
        
        chatConnection.on("AgentJoined", (agent) => {
            const pic = agent.profilePictureUrl || '/images/default-avatar.png';
            document.querySelector('.chat-header small').innerHTML = <img src="" class="chat-avatar" style="width:20px;height:20px;display:inline-block;vertical-align:middle;">  is now helping you;
        });
        
        chatConnection.on("SessionResolved", () => {
            const msgs = document.querySelector('.chat-messages');
            const div = document.createElement('div');
            div.className = 'chat-bubble support';
            div.innerHTML = <span>Session ended. Thanks for chatting!</span>;
            msgs.appendChild(div);
            msgs.scrollTop = msgs.scrollHeight;
            chatForm.message.disabled = true;
            chatForm.querySelector('button').disabled = true;
        });

        try {
            await chatConnection.start();
            await chatConnection.invoke("JoinSession", chatSessionId, name, phone);
            isLive = true;
            chatForm.message.disabled = false;
            chatForm.querySelector('button').disabled = false;
        } catch(err) {
            console.error('SignalR Error:', err);
        }
    }

    let chatStep = 0;
    let chatData = { name: '', phone: '', message: '', service: '???? ????? ???????' };

    chatForm?.addEventListener('submit', async event => {
      event.preventDefault();
      const text = chatForm.message.value.trim();
      if (!text) return;

      const userBubble = document.createElement('div');
      userBubble.className = 'chat-bubble user';
      userBubble.textContent = text;
      chatMessages.appendChild(userBubble);
      
      chatForm.reset();
      chatMessages.scrollTop = chatMessages.scrollHeight;

      if (isLive && chatConnection) {
          await chatConnection.invoke("SendGuestMessage", chatSessionId, text);
          return;
      }

      if (chatStep === 0) {
        chatData.message = text;
        setTimeout(() => {
          const supportBubble = document.createElement('div');
          supportBubble.className = 'chat-bubble support';
          supportBubble.innerHTML = <img src="/images/default-avatar.png" class="chat-avatar"> <span>????? ??????? ??????? ????????? ???? ????? ????? ????:</span>;
          chatMessages.appendChild(supportBubble);
          chatMessages.scrollTop = chatMessages.scrollHeight;
          chatStep++;
        }, 600);
      } else if (chatStep === 1) {
        chatData.name = text;
        setTimeout(() => {
          const supportBubble = document.createElement('div');
          supportBubble.className = 'chat-bubble support';
          supportBubble.innerHTML = <img src="/images/default-avatar.png" class="chat-avatar"> <span>???????, ? ???? ????? ??-??????? ?????? ??????? ???:</span>;
          chatMessages.appendChild(supportBubble);
          chatMessages.scrollTop = chatMessages.scrollHeight;
          chatStep++;
        }, 600);
      } else if (chatStep === 2) {
        if (!/^01\d{9}$/.test(text)) {
          setTimeout(() => {
            const supportBubble = document.createElement('div');
            supportBubble.className = 'chat-bubble support';
            supportBubble.innerHTML = <img src="/images/default-avatar.png" class="chat-avatar"> <span>??????? ???? ??? ??? ??? ???? ??-??????? ??????? ??? (????: 017...):</span>;
            chatMessages.appendChild(supportBubble);
            chatMessages.scrollTop = chatMessages.scrollHeight;
          }, 600);
          return;
        }
        
        chatData.phone = text;
        chatForm.message.disabled = true;
        chatForm.querySelector('button').disabled = true;
        
        setTimeout(() => {
            const supportBubble = document.createElement('div');
            supportBubble.className = 'chat-bubble support';
            supportBubble.innerHTML = <img src="/images/default-avatar.png" class="chat-avatar"> <span>???????! ???? ??????? ?????? ??????? ????? ???? ????? ????...</span>;
            chatMessages.appendChild(supportBubble);
            chatMessages.scrollTop = chatMessages.scrollHeight;
            initLiveChat(chatData.name, chatData.phone);
        }, 600);
      }
    });'''

match_start = content.find('    let chatStep = 0;')
match_end = content.find("    fetch('/Home/Bulletins')")
if match_start != -1 and match_end != -1:
    content = content[:match_start] + js_new + "\n\n" + content[match_end:]

with open('promotionwebandapi/wwwroot/landing.html', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated landing.html successfully.")
