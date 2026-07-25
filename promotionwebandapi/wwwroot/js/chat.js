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
})();
