# Quick Guide: Menambahkan Namespace Baru di Centrifugo

Panduan cepat untuk menambahkan namespace baru sesuai kebutuhan aplikasi Anda.

---

## ⚡ 3-Step Quick Start

### Step 1️⃣: Edit config.json

Buka file: `docker/centrifugo/config.json`

Tambahkan namespace baru ke array "namespaces":

```json
{
  "name": "your_namespace_name",
  "publish": true,
  "subscribe_to_publish": false, // atau true
  "history_size": 100,
  "history_ttl": "24h",
  "recover": true
}
```

### Step 2️⃣: Restart Centrifugo

```bash
docker-compose restart centrifugo
```

### Step 3️⃣: Use dalam aplikasi

```javascript
// Subscribe
const sub = centrifuge.subscribe("your_namespace_name", (msg) => {
  console.log("Message:", msg.data);
});

// Publish (jika subscribe_to_publish: true)
sub.publish({ data: "value" });
```

---

## 📝 Contoh Kasus Penggunaan

### Kasus 1: Alert/Warning System

Anda ingin broadcast alert ke semua users (hanya server yang bisa publish):

**Config:**

```json
{
  "name": "alerts",
  "publish": true,
  "subscribe_to_publish": false,
  "history_size": 100,
  "history_ttl": "7d"
}
```

**Client:**

```javascript
centrifuge.subscribe("alerts", (msg) => {
  console.log("Alert:", msg.data); // {type: 'error', message: '...'}
});
```

**Server API:**

```bash
curl -X POST http://localhost:8000/api/publish \
  -H "X-API-Key: your-api-key" \
  -d '{"channel":"alerts","data":{"type":"error","message":"Server error"}}'
```

---

### Kasus 2: User Activity Tracking

Track apa yang user sedang lakukan (hanya server publish):

**Config:**

```json
{
  "name": "activities",
  "publish": true,
  "subscribe_to_publish": false,
  "history_size": 500,
  "history_ttl": "24h"
}
```

**Client:**

```javascript
centrifuge.subscribe("activities", (msg) => {
  // {userId: 123, action: 'viewed_product', product_id: 456}
  updateActivityFeed(msg.data);
});
```

---

### Kasus 3: Live Collaboration

Users bisa collaborate real-time (peer-to-peer):

**Config:**

```json
{
  "name": "collaboration",
  "publish": true,
  "subscribe_to_publish": true,
  "history_size": 200,
  "history_ttl": "1h"
}
```

**Client:**

```javascript
const sub = centrifuge.subscribe("collaboration", (msg) => {
  updateSharedDocument(msg.data);
});

// User dapat publish
sub.publish({
  userId: 123,
  action: "edit",
  content: "updated text",
});
```

---

### Kasus 4: Live Feed (Social)

Post/update feed real-time:

**Config:**

```json
{
  "name": "feed",
  "publish": true,
  "subscribe_to_publish": true,
  "history_size": 100,
  "history_ttl": "7d"
}
```

**Client:**

```javascript
const feedSub = centrifuge.subscribe("feed", (msg) => {
  // {userId: 123, content: '...', likes: 45}
  displayPostInFeed(msg.data);
});

// Post ke feed
feedSub.publish({
  userId: getCurrentUserId(),
  content: "Hello world!",
  timestamp: new Date(),
});
```

---

### Kasus 5: Admin Command Channel

Admin commands ke users (server-only):

**Config:**

```json
{
  "name": "admin_commands",
  "publish": true,
  "subscribe_to_publish": false,
  "history_size": 100,
  "history_ttl": "7d"
}
```

**Client:**

```javascript
centrifuge.subscribe("admin_commands", (msg) => {
  // {command: 'logout', reason: '...'}
  // {command: 'refresh', data: {...}}
  executeAdminCommand(msg.data);
});
```

**Server:**

```bash
# Logout all users
curl -X POST http://localhost:8000/api/publish \
  -H "X-API-Key: your-api-key" \
  -d '{"channel":"admin_commands","data":{"command":"logout","reason":"Security breach"}}'
```

---

## 🔧 Parameter Cheat Sheet

| Parameter              | Arti                     | Contoh                              |
| ---------------------- | ------------------------ | ----------------------------------- |
| `name`                 | Nama channel             | `"alerts"`                          |
| `publish`              | Channel active?          | `true` atau `false`                 |
| `subscribe_to_publish` | Users bisa publish?      | `true` = yes, `false` = only server |
| `history_size`         | Simpan berapa pesan      | `0` = none, `100` = 100 messages    |
| `history_ttl`          | Berapa lama history      | `"24h"`, `"7d"`, `"1m"`             |
| `presence`             | Track online status?     | `true` atau `false`                 |
| `join_leave`           | Notify join/leave?       | `true` atau `false`                 |
| `recover`              | Auto recover disconnect? | `true` atau `false`                 |

---

## ✅ Checklist: Sebelum Tambah Namespace

- [ ] Tentukan nama namespace yang jelas (misal: `alerts`, `orders`, `chat`)
- [ ] Tentukan apakah users bisa publish atau hanya server (`subscribe_to_publish`)
- [ ] Tentukan ukuran history yang sesuai (0 = no history)
- [ ] Tentukan retention time yang sesuai (`history_ttl`)
- [ ] Edit `docker/centrifugo/config.json`
- [ ] Restart: `docker-compose restart centrifugo`
- [ ] Test dengan client

---

## 🧪 Testing Namespace Baru

### Method 1: Server API

```bash
# Publish test message
curl -X POST http://localhost:8000/api/publish \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $CENTRIFUGO_API_KEY" \
  -d '{
    "channel": "your_new_namespace",
    "data": {"test": "message"}
  }'
```

### Method 2: Client

```javascript
// Subscribe
const sub = centrifuge.subscribe("your_new_namespace", (msg) => {
  console.log("Received:", msg.data);
});

// Publish (jika bisa)
sub.publish({ test: "message" });
```

---

## 🚨 Common Mistakes

❌ **Salah: Typo di nama namespace**

```json
// Config
{"name": "alerts"}

// Client - TYPO!
centrifuge.subscribe('alert', ...)  // Won't work!
```

✅ **Benar:**

```json
// Config
{"name": "alerts"}

// Client
centrifuge.subscribe('alerts', ...)  // Sama persis
```

---

❌ **Salah: Lupa restart Centrifugo**

```bash
# Edit config.json
# Kemudian langsung client connect
# Result: Namespace tidak ada!
```

✅ **Benar:**

```bash
# Edit config.json
docker-compose restart centrifugo
# Tunggu sampai running
# Baru client connect
```

---

❌ **Salah: publish=false**

```json
{
  "name": "test",
  "publish": false // Channel tidak aktif!
}
```

✅ **Benar:**

```json
{
  "name": "test",
  "publish": true // Channel aktif
}
```

---

## 📊 Current Namespaces (Sudah Ada)

✅ `chat` - Peer-to-peer chat  
✅ `notifications` - Personal notifications  
✅ `presence` - User online status  
✅ `typing` - User typing indicator  
✅ `alerts` - System alerts (server-only)  
✅ `broadcast` - Broadcast messages (server-only)  
✅ `announcements` - Important announcements (server-only)  
✅ `system_events` - System events (server-only)  
✅ `user_status` - User activity status (server-only)

---

## 🎯 Next Actions

1. **Identifikasi kebutuhan** - Apa namespace yang dibutuhkan?
2. **Tentukan konfigurasi** - publish? history? recovery?
3. **Edit config.json** - Tambah ke array namespaces
4. **Restart Centrifugo** - `docker-compose restart centrifugo`
5. **Test** - Dari client atau server API
6. **Document** - Catat tujuan namespace

---

## 📞 Help

- **Lebih detail:** Lihat `CENTRIFUGO_NAMESPACES.md`
- **Code examples:** Lihat `CENTRIFUGO_EXAMPLES.js`
- **Config reference:** Lihat `docker/centrifugo/config.json`

---

**Created:** 2026-01-20  
**Status:** Ready to Use
