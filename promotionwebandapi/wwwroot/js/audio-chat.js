(() => {
    if (!window.chatConnection) return;

    let conversationId = 0;
    let peer = null;
    let localStream = null;
    let pendingOffer = null;
    let pendingCandidates = [];
    let isCaller = false;

    const overlay = document.createElement("section");
    overlay.className = "audio-call-overlay";
    overlay.hidden = true;
    overlay.innerHTML = `
        <div class="audio-call-card">
            <span class="audio-call-icon">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path></svg>
            </span>
            <h2 id="audio-call-name">অডিও কল</h2>
            <p id="audio-call-status">সংযোগ করা হচ্ছে...</p>
            <div class="audio-call-actions">
                <button type="button" id="audio-call-accept" title="Accept Call">
                    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path></svg>
                </button>
                <button type="button" id="audio-call-end" title="End Call">
                    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.68 13.31a16 16 0 0 0 3.41 2.6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7 2 2 0 0 1 1.72 2v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.42 19.42 0 0 1-3.33-2.67m-2.67-3.34a19.79 19.79 0 0 1-3.07-8.63A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91"></path><line x1="23" y1="1" x2="1" y2="23"></line></svg>
                </button>
            </div>
            <audio id="audio-call-remote" autoplay></audio>
        </div>`;
    document.body.appendChild(overlay);

    const name = overlay.querySelector("#audio-call-name");
    const status = overlay.querySelector("#audio-call-status");
    const accept = overlay.querySelector("#audio-call-accept");
    const end = overlay.querySelector("#audio-call-end");
    const remoteAudio = overlay.querySelector("#audio-call-remote");

    const setStatus = value => status.textContent = value;
    const show = (title, canAccept) => {
        name.textContent = title;
        accept.hidden = !canAccept;
        overlay.hidden = false;
    };

    const createPeer = async () => {
        localStream = await navigator.mediaDevices.getUserMedia({ audio: true, video: false });
        peer = new RTCPeerConnection({
            iceServers: [{ urls: "stun:stun.l.google.com:19302" }]
        });
        localStream.getTracks().forEach(track => peer.addTrack(track, localStream));
        peer.ontrack = event => remoteAudio.srcObject = event.streams[0];
        peer.onicecandidate = event => {
            if (event.candidate && conversationId) {
                window.chatConnection.invoke("SendIceCandidate", conversationId, JSON.stringify(event.candidate));
            }
        };
        peer.onconnectionstatechange = () => {
            if (peer?.connectionState === "connected") setStatus("Connected");
            if (["failed", "closed", "disconnected"].includes(peer?.connectionState)) cleanup(false);
        };
        return peer;
    };

    const cleanup = notify => {
        const id = conversationId;
        peer?.close();
        localStream?.getTracks().forEach(track => track.stop());
        peer = null;
        localStream = null;
        pendingOffer = null;
        pendingCandidates = [];
        conversationId = 0;
        overlay.hidden = true;
        if (notify && id) window.chatConnection.invoke("EndAudioCall", id);
    };

    const applyCandidates = async () => {
        while (peer?.remoteDescription && pendingCandidates.length) {
            await peer.addIceCandidate(pendingCandidates.shift());
        }
    };

    document.addEventListener("click", async event => {
        const button = event.target.closest("[data-audio-call-button]");
        if (!button || button.disabled) return;
        conversationId = Number(document.body.dataset.activeConversationId);
        if (!conversationId) return;

        try {
            isCaller = true;
            show(button.dataset.callName || "Audio call", false);
            setStatus("Calling...");
            await window.chatConnectionReady;
            await createPeer();
            const offer = await peer.createOffer();
            await peer.setLocalDescription(offer);
            await window.chatConnection.invoke("StartAudioCall", conversationId, JSON.stringify(offer));
        } catch (error) {
            setStatus(error.message || "Microphone permission is required.");
            setTimeout(() => cleanup(false), 2500);
        }
    });

    accept.addEventListener("click", async () => {
        try {
            accept.hidden = true;
            setStatus("Connecting...");
            await createPeer();
            await peer.setRemoteDescription(JSON.parse(pendingOffer));
            await applyCandidates();
            const answer = await peer.createAnswer();
            await peer.setLocalDescription(answer);
            await window.chatConnection.invoke("AnswerAudioCall", conversationId, JSON.stringify(answer));
        } catch (error) {
            setStatus(error.message || "Call could not connect.");
            setTimeout(() => cleanup(true), 2500);
        }
    });

    end.addEventListener("click", () => cleanup(true));

    window.chatConnection.on("IncomingAudioCall", call => {
        if (peer || pendingOffer) {
            window.chatConnection.invoke("EndAudioCall", call.conversationId);
            return;
        }
        isCaller = false;
        conversationId = call.conversationId;
        pendingOffer = call.offer;
        show(call.callerName || "Incoming audio call", true);
        setStatus("Incoming call");
    });

    window.chatConnection.on("AudioCallAnswered", async call => {
        if (!isCaller || call.conversationId !== conversationId || !peer) return;
        await peer.setRemoteDescription(JSON.parse(call.answer));
        await applyCandidates();
        setStatus("Connecting...");
    });

    window.chatConnection.on("AudioIceCandidate", async data => {
        if (data.conversationId !== conversationId) return;
        const candidate = JSON.parse(data.candidate);
        if (peer?.remoteDescription) await peer.addIceCandidate(candidate);
        else pendingCandidates.push(candidate);
    });

    window.chatConnection.on("AudioCallEnded", data => {
        if (data.conversationId === conversationId) {
            setStatus("Call ended");
            setTimeout(() => cleanup(false), 800);
        }
    });
})();
