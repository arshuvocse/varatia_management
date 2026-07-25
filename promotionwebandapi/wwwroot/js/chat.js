(() => {
    if (document.body.dataset.liveChatEnabled !== "true" || !window.signalR) {
        return;
    }

    const badges = () => [...document.querySelectorAll("[data-chat-notification-badge]")];
    const setUnread = count => {
        badges().forEach(badge => {
            badge.textContent = count > 99 ? "99+" : String(count);
            badge.hidden = count <= 0;
        });
    };

    const showToast = notification => {
        const stack = document.getElementById("live-notification-stack");
        if (!stack || Number(document.body.dataset.activeConversationId) === notification.conversationId) {
            return;
        }

        const toast = document.createElement("button");
        toast.type = "button";
        toast.className = "live-chat-toast";
        toast.innerHTML = `<strong>${escapeHtml(notification.senderName)}</strong><span>${escapeHtml(notification.messageText)}</span>`;
        toast.addEventListener("click", () => {
            window.dispatchEvent(new CustomEvent("chat:open-notification", { detail: notification }));
            toast.remove();
        });
        stack.appendChild(toast);
        window.setTimeout(() => toast.remove(), 6000);
    };

    const escapeHtml = value => {
        const element = document.createElement("span");
        element.textContent = value || "";
        return element.innerHTML;
    };

    const connection = new signalR.HubConnectionBuilder()
        .withUrl("/hubs/chat")
        .withAutomaticReconnect()
        .build();

    connection.on("ReceiveMessage", message => {
        window.dispatchEvent(new CustomEvent("chat:message", { detail: message }));
    });

    connection.on("ReceiveNotification", notification => {
        const firstBadge = badges()[0];
        setUnread((Number(firstBadge?.textContent) || 0) + 1);
        showToast(notification);
        window.dispatchEvent(new CustomEvent("chat:notification", { detail: notification }));
    });

    connection.on("UnreadCountChanged", count => setUnread(Number(count) || 0));

    connection.on("UserTyping", status => {
        window.dispatchEvent(new CustomEvent("chat:typing", { detail: status }));
    });

    window.chatConnection = connection;
    window.chatConnectionReady = connection.start().catch(error => {
        console.warn("লাইভ চ্যাট পাওয়া যাচ্ছে না। সেশন শেষ হলে আবার লগইন করুন।", error);
        return null;
    });

    window.renderChatMessageBody = (container, message) => {
        if (message.messageType === "Image" && message.mediaUrl) {
            const link = document.createElement("a");
            link.href = message.mediaUrl;
            link.target = "_blank";
            link.rel = "noopener";
            const image = document.createElement("img");
            image.className = "chat-message-image";
            image.src = message.mediaUrl;
            image.alt = "চ্যাটের ছবি";
            link.appendChild(image);
            container.appendChild(link);
            return;
        }

        if ((message.messageType === "Audio" || message.messageType === "Voice") && message.mediaUrl) {
            const wrapper = document.createElement("div");
            wrapper.className = "chat-audio-wrapper";
            const audio = document.createElement("audio");
            audio.controls = true;
            audio.preload = "metadata";
            audio.className = "chat-message-audio";
            audio.src = message.mediaUrl;
            wrapper.appendChild(audio);
            container.appendChild(wrapper);
            return;
        }

        const text = document.createElement("p");
        text.textContent = message.messageText;
        container.appendChild(text);
    };

    window.uploadChatImage = async (conversationId, file) => {
        const verificationToken = document.querySelector('input[name="__RequestVerificationToken"]')?.value;
        if (!verificationToken) {
            throw new Error("Your session could not be verified. Please sign in again.");
        }

        const formData = new FormData();
        formData.append("conversationId", conversationId);
        formData.append("image", file);
        formData.append("__RequestVerificationToken", verificationToken);
        const response = await fetch("/Chat/UploadImage", { method: "POST", body: formData });
        if (!response.ok) {
            const error = await response.json().catch(() => ({ message: "ছবি আপলোড করা যায়নি।" }));
            throw new Error(error.message || "ছবি আপলোড করা যায়নি।");
        }
    };

    window.uploadChatAudio = async (conversationId, audioBlob) => {
        const verificationToken = document.querySelector('input[name="__RequestVerificationToken"]')?.value;
        if (!verificationToken) {
            throw new Error("Your session could not be verified. Please sign in again.");
        }

        const mimeType = audioBlob.type || "audio/webm";
        const extension = mimeType.includes("ogg") ? "voice.ogg" : mimeType.includes("wav") ? "voice.wav" : "voice.webm";
        const file = new File([audioBlob], extension, { type: mimeType });

        const formData = new FormData();
        formData.append("conversationId", conversationId);
        formData.append("audio", file);
        formData.append("__RequestVerificationToken", verificationToken);
        const response = await fetch("/Chat/UploadAudio", { method: "POST", body: formData });
        if (!response.ok) {
            const error = await response.json().catch(() => ({ message: "ভয়েস এসএমএস পাঠানো যায়নি।" }));
            throw new Error(error.message || "ভয়েস এসএমএস পাঠানো যায়নি।");
        }
    };

    window.setupVoiceRecorder = ({ recordButton, getConversationId }) => {
        if (!recordButton) return;

        let mediaRecorder = null;
        let audioChunks = [];
        let isRecording = false;
        let timerInterval = null;
        let secondsElapsed = 0;

        const updateButtonState = state => {
            if (state === "recording") {
                recordButton.classList.add("recording");
                recordButton.innerHTML = `🔴 Send (${secondsElapsed}s)`;
            } else if (state === "uploading") {
                recordButton.classList.remove("recording");
                recordButton.disabled = true;
                recordButton.innerHTML = `Sending...`;
            } else {
                recordButton.classList.remove("recording");
                recordButton.disabled = !getConversationId();
                recordButton.innerHTML = `🎤 Voice`;
            }
        };

        const stopTimer = () => {
            if (timerInterval) {
                clearInterval(timerInterval);
                timerInterval = null;
            }
            secondsElapsed = 0;
        };

        const startRecording = async () => {
            const conversationId = getConversationId();
            if (!conversationId) return;

            try {
                const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                audioChunks = [];
                const options = MediaRecorder.isTypeSupported("audio/webm;codecs=opus")
                    ? { mimeType: "audio/webm;codecs=opus" }
                    : MediaRecorder.isTypeSupported("audio/ogg;codecs=opus")
                        ? { mimeType: "audio/ogg;codecs=opus" }
                        : {};
                mediaRecorder = new MediaRecorder(stream, options);

                mediaRecorder.ondataavailable = event => {
                    if (event.data.size > 0) {
                        audioChunks.push(event.data);
                    }
                };

                mediaRecorder.onstop = async () => {
                    stream.getTracks().forEach(track => track.stop());
                    if (audioChunks.length === 0) {
                        updateButtonState("idle");
                        return;
                    }

                    const audioBlob = new Blob(audioChunks, { type: mediaRecorder.mimeType || "audio/webm" });
                    updateButtonState("uploading");
                    try {
                        await window.uploadChatAudio(conversationId, audioBlob);
                    } catch (err) {
                        alert(err.message || "ভয়েস এসএমএস পাঠাতে ব্যর্থ হয়েছে।");
                    } finally {
                        isRecording = false;
                        updateButtonState("idle");
                    }
                };

                mediaRecorder.start();
                isRecording = true;
                secondsElapsed = 0;
                updateButtonState("recording");

                timerInterval = setInterval(() => {
                    secondsElapsed++;
                    updateButtonState("recording");
                    if (secondsElapsed >= 120) { // Auto stop after 2 mins
                        stopRecording();
                    }
                }, 1000);
            } catch (err) {
                alert("মাইক্রোফোন অ্যাক্সেস পাওয়া যায়নি: " + (err.message || "অ্যাক্সেস অস্বীকার করা হয়েছে।"));
                isRecording = false;
                updateButtonState("idle");
            }
        };

        const stopRecording = () => {
            stopTimer();
            if (mediaRecorder && mediaRecorder.state !== "inactive") {
                mediaRecorder.stop();
            }
        };

        recordButton.addEventListener("click", () => {
            if (!isRecording) {
                startRecording();
            } else {
                stopRecording();
            }
        });
    };
})();
