# Centrifugo Namespaces Overview

Quick reference untuk semua namespaces yang sudah dikonfigurasi di Centrifugo.

---

## 📌 All Namespaces (9 Total)

### 1️⃣ **chat** - Real-time Chat

```json
{
  "name": "chat",
  "publish": true,
  "subscribe_to_publish": true,
  "presence": true,
  "join_leave": true,
  "history_size": 100,
  "history_ttl": "24h",
  "recover": true
}
```

**Gunakan:** Peer-to-peer chat antar users  
**Fitur:** Users bisa publish & subscribe, history 24h, presence tracking  
**Contoh:** Chat aplikasi, messaging real-time

---

### 2️⃣ **notifications** - Personal Notifications

```json
{
  "name": "notifications",
  "publish": true,
  "subscribe_to_publish": true,
  "history_size": 50,
  "history_ttl": "12h"
}
```

**Gunakan:** Notifikasi personal ke users  
**Fitur:** History 12 jam, lightweight  
**Contoh:** Order update, friend request, mention notification

---

### 3️⃣ **presence** - User Online Status

```json
{
  "name": "presence",
  "publish": true,
  "presence": true,
  "join_leave": true
}
```

**Gunakan:** Track siapa yang online  
**Fitur:** Real-time presence, join/leave events  
**Contoh:** Online indicator, user list dengan status

---

### 4️⃣ **typing** - User Typing Indicator

```json
{
  "name": "typing",
  "publish": true,
  "history_size": 0,
  "force_recovery": false
}
```

**Gunakan:** Show "user is typing" indicator  
**Fitur:** Real-time only, no history  
**Contoh:** "John is typing..." indicator di chat

---

### 5️⃣ **alerts** ⭐ - System Alerts (Server-Only)

```json
{
  "name": "alerts",
  "publish": true,
  "subscribe_to_publish": false,
  "history_size": 100,
  "history_ttl": "7d",
  "recover": true
}
```

**Gunakan:** Broadcast system alerts (hanya server publish)  
**Fitur:** History 7 hari, auto recover, server-only publish  
**Contoh:**

- "Critical error occurred"
- "Disk space low"
- "Database backup failed"

**Server Publish:**

```bash
curl -X POST http://localhost:8000/api/publish \
  -H "X-API-Key: $CENTRIFUGO_API_KEY" \
  -d '{"channel":"alerts","data":{"type":"error","message":"Critical error"}}'
```

---

### 6️⃣ **broadcast** - Broadcast Messages (Server-Only)

```json
{
  "name": "broadcast",
  "publish": true,
  "subscribe_to_publish": false,
  "history_size": 50,
  "history_ttl": "24h",
  "recover": true
}
```

**Gunakan:** Kirim pesan ke semua users (server-only)  
**Fitur:** History 24 jam, lightweight  
**Contoh:**

- "Sistem maintenance jam 22:00"
- "Update server berhasil"
- "Promo khusus tersedia"

---

### 7️⃣ **announcements** - Important Announcements (Server-Only)

```json
{
  "name": "announcements",
  "publish": true,
  "subscribe_to_publish": false,
  "history_size": 200,
  "history_ttl": "30d",
  "recover": true
}
```

**Gunakan:** Long-term announcements (server-only)  
**Fitur:** History 30 hari (lebih lama), dapat disimpan  
**Contoh:**

- "New features available"
- "Policy changes"
- "Important updates"

---

### 8️⃣ **system_events** - System Events (Server-Only)

```json
{
  "name": "system_events",
  "publish": true,
  "subscribe_to_publish": false,
  "history_size": 500,
  "history_ttl": "7d",
  "recover": true
}
```

**Gunakan:** Track system events dan monitoring (server-only)  
**Fitur:** Large history (500 items), untuk audit trail  
**Contoh:**

- User login/logout
- Data sync events
- Database maintenance
- API calls

---

### 9️⃣ **user_status** - User Activity Status (Server-Only)

```json
{
  "name": "user_status",
  "publish": true,
  "subscribe_to_publish": false,
  "presence": true,
  "join_leave": true,
  "history_size": 0,
  "force_recovery": false
}
```

**Gunakan:** User activity status updates (server-only)  
**Fitur:** Real-time presence, no history  
**Contoh:**

- "User is in meeting"
- "User is on break"
- "User is away"
- Activity tracking

---

## 🎯 Quick Decision Table

| Kebutuhan        | Gunakan Namespace | Alasan                      |
| ---------------- | ----------------- | --------------------------- |
| Chat app         | `chat`            | Peer-to-peer dengan history |
| Notify user      | `notifications`   | Personal, lightweight       |
| Show who online  | `presence`        | Real-time status            |
| Show typing      | `typing`          | Real-time, no history       |
| Alert sistem     | `alerts`          | Server-only, important      |
| Announce semua   | `broadcast`       | All users, medium history   |
| Important notice | `announcements`   | All users, long history     |
| Track events     | `system_events`   | Server-only, full audit     |
| User activity    | `user_status`     | Real-time, server-only      |

---

## 💻 Quick Client Examples

### Subscribe ke chat

```javascript
centrifuge.subscribe("chat", (msg) => {
  console.log("Chat:", msg.data);
});
```

### Subscribe ke alerts

```javascript
centrifuge.subscribe("alerts", (msg) => {
  console.log("Alert:", msg.data);
  // {type: 'error', message: '...'}
});
```

### Subscribe ke broadcast

```javascript
centrifuge.subscribe("broadcast", (msg) => {
  console.log("Broadcast:", msg.data);
  showBannerNotification(msg.data);
});
```

### Subscribe ke presence

```javascript
const presenceSub = centrifuge.subscribe("presence", (msg) => {
  console.log("Presence update:", msg.data);
});

presenceSub.on("join", (ctx) => {
  console.log("User joined:", ctx.info);
});

presenceSub.on("leave", (ctx) => {
  console.log("User left:", ctx.info);
});
```

---

## 🔄 Publishing Examples

### Client publish ke chat

```javascript
const chatSub = centrifuge.subscribe('chat', ...);
chatSub.publish({
  text: 'Hello world',
  userId: 123
});
```

### Server publish ke alerts

```bash
curl -X POST http://localhost:8000/api/publish \
  -H "X-API-Key: $API_KEY" \
  -d '{
    "channel": "alerts",
    "data": {
      "type": "error",
      "message": "Server error occurred",
      "severity": "high"
    }
  }'
```

### Server publish ke broadcast

```bash
curl -X POST http://localhost:8000/api/publish \
  -H "X-API-Key: $API_KEY" \
  -d '{
    "channel": "broadcast",
    "data": {
      "title": "System Maintenance",
      "message": "Maintenance jam 22:00",
      "duration": "2 hours"
    }
  }'
```

---

## 📊 Namespace Comparison

| Feature        | chat      | notifications | alerts   | broadcast | announcements |
| -------------- | --------- | ------------- | -------- | --------- | ------------- |
| Client publish | ✅        | ✅            | ❌       | ❌        | ❌            |
| Server publish | ✅        | ✅            | ✅       | ✅        | ✅            |
| Presence       | ✅        | ❌            | ❌       | ❌        | ❌            |
| History        | 100 (24h) | 50 (12h)      | 100 (7d) | 50 (24h)  | 200 (30d)     |
| Recovery       | ✅        | ✅            | ✅       | ✅        | ✅            |

---

## 🚀 Getting Started

1. **Use existing namespaces** - Sudah siap untuk digunakan
2. **Add your own** - Lihat `ADD_NAMESPACE_GUIDE.md`
3. **See examples** - Lihat `CENTRIFUGO_EXAMPLES.js`
4. **Read full docs** - Lihat `CENTRIFUGO_NAMESPACES.md`

---

## ✏️ Want to Add Custom Namespace?

```json
{
  "name": "your_namespace",
  "publish": true,
  "subscribe_to_publish": false,
  "history_size": 100,
  "history_ttl": "24h",
  "recover": true
}
```

**Steps:**

1. Edit: `docker/centrifugo/config.json`
2. Restart: `docker-compose restart centrifugo`
3. Use in client: `centrifuge.subscribe('your_namespace', ...)`

---

## 📞 Help

- **How to add namespace?** → `ADD_NAMESPACE_GUIDE.md`
- **Detailed reference?** → `CENTRIFUGO_NAMESPACES.md`
- **Code examples?** → `CENTRIFUGO_EXAMPLES.js`
- **Configuration?** → `docker/centrifugo/config.json`

---

**Last Updated:** 2026-01-20  
**Namespaces:** 9 (ready to use)  
**Status:** Production Ready
