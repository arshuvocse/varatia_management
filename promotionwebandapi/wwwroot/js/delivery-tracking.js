(() => {
    const tileUrl = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";
    const tileAttribution = "&copy; OpenStreetMap contributors";

    const toNumber = value => {
        if (value === null || value === undefined || value === "") return null;
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : null;
    };

    const formatTime = value => {
        if (!value) return "এখনও লাইভ আপডেট নেই";
        const date = new Date(value);
        return Number.isNaN(date.getTime()) ? "এখনও লাইভ আপডেট নেই" : `আপডেট: ${date.toLocaleString("bn-BD")}`;
    };

    const createMap = element => {
        const fallbackLat = toNumber(element.dataset.lat) ?? 23.8103;
        const fallbackLng = toNumber(element.dataset.lng) ?? 90.4125;
        const map = L.map(element).setView([fallbackLat, fallbackLng], 13);
        L.tileLayer(tileUrl, { maxZoom: 19, attribution: tileAttribution }).addTo(map);
        return map;
    };

    const markerHtml = (label, className) =>
        `<span class="tracking-pin ${className}">${label}</span>`;

    const markerIcon = (label, className) => L.divIcon({
        className: "tracking-pin-shell",
        html: markerHtml(label, className),
        iconSize: [34, 34],
        iconAnchor: [17, 17]
    });

    const initFleetMap = element => {
        const endpoint = element.dataset.endpoint;
        if (!endpoint || !window.L) return;

        const map = createMap(element);
        const markers = new Map();
        const bounds = L.latLngBounds();

        const render = async () => {
            const response = await fetch(endpoint, { headers: { "Accept": "application/json" } });
            if (!response.ok) return;
            const data = await response.json();
            const seen = new Set();
            const currentBounds = L.latLngBounds();

            for (const person of data.deliveryMen ?? []) {
                const lat = toNumber(person.latitude ?? person.Latitude);
                const lng = toNumber(person.longitude ?? person.Longitude);
                if (lat === null || lng === null) continue;

                seen.add(person.id);
                const popup = `<strong>${person.name}</strong><br>${person.phone}<br>${person.availability}<br>${formatTime(person.lastLocationAt)}`;
                const latLng = [lat, lng];
                currentBounds.extend(latLng);
                bounds.extend(latLng);

                if (markers.has(person.id)) {
                    markers.get(person.id).setLatLng(latLng).setPopupContent(popup);
                } else {
                    markers.set(person.id, L.marker(latLng, { icon: markerIcon("D", "delivery") }).addTo(map).bindPopup(popup));
                }
            }

            for (const [id, marker] of markers.entries()) {
                if (!seen.has(id)) {
                    map.removeLayer(marker);
                    markers.delete(id);
                }
            }

            if (currentBounds.isValid()) map.fitBounds(currentBounds.pad(0.2));
            else if (bounds.isValid()) map.fitBounds(bounds.pad(0.2));
        };

        render().catch(() => {});
        window.setInterval(() => render().catch(() => {}), 15000);
    };

    const initOrderMap = element => {
        const endpoint = element.dataset.endpoint;
        if (!endpoint || !window.L) return;

        const map = createMap(element);
        let deliveryMarker = null;
        let customerMarker = null;
        let path = null;

        const render = async () => {
            const response = await fetch(endpoint, { headers: { "Accept": "application/json" } });
            if (!response.ok) return;
            const data = await response.json();
            const assignment = data.assignment;
            if (!assignment) return;

            const deliveryLat = toNumber(assignment.deliveryLatitude);
            const deliveryLng = toNumber(assignment.deliveryLongitude);
            const customerLat = toNumber(assignment.customerLatitude);
            const customerLng = toNumber(assignment.customerLongitude);
            const bounds = L.latLngBounds();

            if (deliveryLat !== null && deliveryLng !== null) {
                const latLng = [deliveryLat, deliveryLng];
                bounds.extend(latLng);
                const popup = `<strong>${assignment.deliveryManName}</strong><br>${assignment.deliveryManPhone}<br>${assignment.status}`;
                if (deliveryMarker) deliveryMarker.setLatLng(latLng).setPopupContent(popup);
                else deliveryMarker = L.marker(latLng, { icon: markerIcon("D", "delivery") }).addTo(map).bindPopup(popup);
            }

            if (customerLat !== null && customerLng !== null) {
                const latLng = [customerLat, customerLng];
                bounds.extend(latLng);
                const popup = `<strong>${assignment.customerName}</strong><br>${assignment.customerPhone}`;
                if (customerMarker) customerMarker.setLatLng(latLng).setPopupContent(popup);
                else customerMarker = L.marker(latLng, { icon: markerIcon("C", "customer") }).addTo(map).bindPopup(popup);
            }

            if (path) map.removeLayer(path);
            if (deliveryLat !== null && deliveryLng !== null && customerLat !== null && customerLng !== null) {
                path = L.polyline([[deliveryLat, deliveryLng], [customerLat, customerLng]], { color: "#1464e9", weight: 4 }).addTo(map);
            }

            if (bounds.isValid()) map.fitBounds(bounds.pad(0.25));
        };

        render().catch(() => {});
        window.setInterval(() => render().catch(() => {}), 10000);
    };

    const initLocationPush = form => {
        if (!navigator.geolocation) return;
        const token = form.querySelector("input[name='__RequestVerificationToken']")?.value ?? "";
        const assignmentId = form.dataset.assignmentId ?? "";
        const status = document.querySelector("[data-location-status]");

        const send = position => {
            const body = new URLSearchParams();
            body.set("__RequestVerificationToken", token);
            body.set("latitude", position.coords.latitude.toString());
            body.set("longitude", position.coords.longitude.toString());
            if (assignmentId) body.set("assignmentId", assignmentId);

            fetch(form.action, {
                method: "POST",
                headers: { "Content-Type": "application/x-www-form-urlencoded" },
                body
            }).then(response => {
                if (status) status.textContent = response.ok ? "লাইভ অবস্থান শেয়ার চালু আছে।" : "অবস্থান আপডেট করা যায়নি।";
            }).catch(() => {
                if (status) status.textContent = "অবস্থান আপডেট করা যায়নি।";
            });
        };

        navigator.geolocation.watchPosition(send, () => {
            if (status) status.textContent = "লাইভ অবস্থানের জন্য লোকেশন অনুমতি দিন।";
        }, { enableHighAccuracy: true, maximumAge: 30000, timeout: 15000 });
    };

    document.querySelectorAll(".delivery-live-map[data-kind='fleet']").forEach(initFleetMap);
    document.querySelectorAll(".delivery-live-map[data-kind='order']").forEach(initOrderMap);
    document.querySelectorAll(".js-delivery-location-push").forEach(initLocationPush);
})();
