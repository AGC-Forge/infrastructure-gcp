# Centrifugo Namespaces Documentation

Panduan lengkap untuk menggunakan dan menambahkan namespaces di Centrifugo.

---

## 📚 Apa itu Namespace?

Namespace adalah ruang komunikasi terpisah dalam Centrifugo. Setiap namespace memiliki:

- Konfigurasi sendiri
- Users subscribed sendiri
- Message history sendiri
- Permission rules sendiri

Ibarat ruangan terpisah di sebuah gedung - users di room chat tidak bisa lihat messages di room notifications.

---

## 🔧 Struktur Namespace Parameter

```json
{
  "name": "namespace_name",
  "publish": true, // Izin publish pesan
  "subscribe_to_publish": true, // User bisa publish ke namespace sendiri
  "presence": true, // Track user presence (online/offline)
  "join_leave": true, // Trigger event saat user join/leave
  "history_size": 100, // Jumlah pesan history
  "history_ttl": "24h", // Berapa lama history disimpan
  "recover": true, // Auto recover lost messages
  "force_recovery": false // Force recovery untuk semua clients
}
```

---

## 📋 Namespace di Centrifugo Sekarang

### 1. **chat**

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

**Gunakan untuk:** Chat real-time antar users  
**Fitur:**

- Users bisa publish & subscribe
- History 100 messages selama 24 jam
- Presence tracking aktif
- Recover messages jika disconnect

---

### 2. **notifications**

```json
{
  "name": "notifications",
  "publish": true,
  "subscribe_to_publish": true,
  "history_size": 50,
  "history_ttl": "12h"
}
```

**Gunakan untuk:** Notifikasi personal ke users  
**Fitur:**

- History 50 items selama 12 jam
- Users bisa publish & subscribe

---

### 3. **presence**

```json
{
  "name": "presence",
  "publish": true,
  "presence": true,
  "join_leave": true
}
```

**Gunakan untuk:** Track user online status  
**Fitur:**

- Presence tracking enabled
- Join/leave events
- Real-time status updates

---

### 4. **typing**

```json
{
  "name": "typing",
  "publish": true,
  "history_size": 0,
  "force_recovery": false
}
```

**Gunakan untuk:** User sedang mengetik indicator  
**Fitur:**

- No history (real-time only)
- Lightweight untuk "user is typing" status

---

### 5. **alerts** ⭐ BARU

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

**Gunakan untuk:** Alert system-wide (error, warning, critical)  
**Fitur:**

- Only server can publish (subscribe_to_publish: false)
- History 100 alerts selama 7 hari
- Auto recover jika disconnect
- Subscribers hanya terima, tidak bisa publish

**Client Usage:**

```javascript
// Subscribe
centrifuge.subscribe("alerts", (message) => {
  console.log("Alert received:", message);
});

// Server-side publish (tidak bisa dari client)
// curl -X POST http://localhost:8000/api/publish \
//   -H "X-API-Key: $CENTRIFUGO_API_KEY" \
//   -d '{"channel":"alerts","data":{"type":"error","message":"Server down"}}'
```

---

### 6. **broadcast** ⭐ BARU

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

**Gunakan untuk:** Broadcast messages ke semua subscribers  
**Fitur:**

- Server-only publishing
- History 50 messages
- Untuk announcements, updates, dll

**Use Cases:**

- "Sistem maintenance akan dimulai jam 22:00"
- "Update database selesai"
- "Promo khusus tersedia sekarang"

**Client Usage:**

```javascript
// Subscribe
centrifuge.subscribe("broadcast", (message) => {
  console.log("Broadcast:", message.data);
});
```

---

### 7. **announcements** ⭐ BARU

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

**Gunakan untuk:** Pengumuman penting (long-term)  
**Fitur:**

- Longer history (200 messages, 30 hari)
- Server-only publishing
- Untuk pengumuman yang ingin disimpan lama

**Use Cases:**

- "Fitur baru tersedia"
- "Policy update"
- "Important notice"

---

### 8. **system_events** ⭐ BARU

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

**Gunakan untuk:** System events dan monitoring  
**Fitur:**

- Very large history (500 items)
- Server-only publishing
- Untuk tracking system events

**Use Cases:**

- User login/logout events
- Data sync events
- Database events
- Server state changes

---

### 9. **user_status** ⭐ BARU

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

**Gunakan untuk:** User status updates (activity status)  
**Fitur:**

- Presence tracking
- Join/leave events
- No history (real-time only)
- Server-only publishing

**Use Cases:**

- "User sedang dalam meeting"
- "User sedang di presentation"
- Activity status tracking

---

## ➕ Cara Menambahkan Namespace Baru

Tambahkan object baru ke array "namespaces" di config.json:

```json
{
  "name": "your_namespace_name",
  "publish": true,
  "subscribe_to_publish": true, // atau false sesuai kebutuhan
  "history_size": 100,
  "history_ttl": "24h",
  "recover": true
}
```

### Contoh Penambahan Namespace Baru

#### Kasus 1: Logging real-time

```json
{
  "name": "logs",
  "publish": true,
  "subscribe_to_publish": false,
  "history_size": 1000,
  "history_ttl": "24h",
  "recover": true
}
```

#### Kasus 2: E-commerce order updates

```json
{
  "name": "orders",
  "publish": true,
  "subscribe_to_publish": false,
  "history_size": 200,
  "history_ttl": "30d",
  "recover": true
}
```

#### Kasus 3: Live tracking

```json
{
  "name": "tracking",
  "publish": true,
  "subscribe_to_publish": true,
  "presence": true,
  "join_leave": true,
  "history_size": 0
}
```

#### Kasus 4: Admin commands

```json
{
  "name": "admin_commands",
  "publish": true,
  "subscribe_to_publish": false,
  "history_size": 100,
  "history_ttl": "7d"
}
```

---

## 🎯 Parameter Explanation

### `publish: true/false`

- **true**: Channel bisa menerima messages
- **false**: Channel tidak aktif

### `subscribe_to_publish: true/false`

- **true**: Clients bisa publish ke channel ini (subscriber = publisher)
- **false**: Hanya server yang bisa publish (clients hanya subscribe)

### `presence: true/false`

- **true**: Track who's online (presence information)
- **false**: No presence tracking

### `join_leave: true/false`

- **true**: Trigger event saat user join/leave
- **false**: No join/leave events

### `history_size: number`

- Jumlah messages disimpan (default: 0 = no history)
- Misal: 100 = simpan 100 messages terakhir

### `history_ttl: string`

- Time-to-live untuk history
- Format: "24h", "7d", "1m", dll
- Misal: "24h" = history berlaku 24 jam

### `recover: true/false`

- **true**: Auto recover lost messages jika client disconnect
- **false**: No recovery

### `force_recovery: false`

- **false**: Clients bisa choose apakah mau recover
- **true**: Force semua clients untuk recover

---

## 💻 Client-Side Usage

### Subscribe ke namespace

```javascript
const centrifuge = new Centrifuge("ws://localhost:8000/connection/websocket");

// Chat channel
const chatSub = centrifuge.subscribe("chat", (message) => {
  console.log("New chat:", message.data);
});

// Alerts (server-only)
const alertSub = centrifuge.subscribe("alerts", (message) => {
  console.log("Alert:", message.data);
});

// Broadcast
const broadcastSub = centrifuge.subscribe("broadcast", (message) => {
  console.log("Broadcast:", message.data);
});

// Publish ke chat
chatSub.publish({ text: "Hello world" });
```

---

## 🖥️ Server-Side Usage (API)

### Publish ke namespace (hanya untuk server)

```bash
curl -X POST http://localhost:8000/api/publish \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $CENTRIFUGO_API_KEY" \
  -d '{
    "channel": "alerts",
    "data": {
      "type": "error",
      "message": "Critical error occurred",
      "severity": "high"
    }
  }'
```

### Broadcast ke semua users

```bash
curl -X POST http://localhost:8000/api/publish \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $CENTRIFUGO_API_KEY" \
  -d '{
    "channel": "broadcast",
    "data": {
      "message": "Sistem maintenance jam 22:00",
      "duration": "2 hours"
    }
  }'
```

---

## 📊 Recommended Namespaces Setup

### Minimal Setup (3 namespaces)

```json
"namespaces": [
  {"name": "chat"},
  {"name": "notifications"},
  {"name": "system_events"}
]
```

### Medium Setup (6 namespaces)

```json
"namespaces": [
  {"name": "chat"},
  {"name": "notifications"},
  {"name": "presence"},
  {"name": "typing"},
  {"name": "alerts"},
  {"name": "broadcast"}
]
```

### Full Setup (9 namespaces) - Sudah dikonfigurasi

```json
"namespaces": [
  {"name": "chat"},
  {"name": "notifications"},
  {"name": "presence"},
  {"name": "typing"},
  {"name": "alerts"},
  {"name": "broadcast"},
  {"name": "announcements"},
  {"name": "system_events"},
  {"name": "user_status"}
]
```

---

## 🔑 Best Practices

### 1. **Use `subscribe_to_publish: false` untuk server-only channels**

```json
// ✅ Baik
{
  "name": "alerts",
  "publish": true,
  "subscribe_to_publish": false  // Hanya server bisa publish
}

// ❌ Buruk - clients bisa publish spam
{
  "name": "alerts",
  "publish": true,
  "subscribe_to_publish": true
}
```

### 2. **Set `history_size` sesuai kebutuhan**

```json
// ✅ Baik - history sesuai kebutuhan
{
  "name": "announcements",
  "history_size": 200,     // Simpan 200 messages
  "history_ttl": "30d"     // Selama 30 hari
}

// ❌ Buruk - terlalu besar = memory waste
{
  "name": "chat",
  "history_size": 10000    // Terlalu besar!
}
```

### 3. **Use `recover: true` untuk important messages**

```json
// ✅ Important channels
{
  "name": "alerts",
  "recover": true   // Auto recover jika disconnect
}

// ✅ Real-time only
{
  "name": "typing",
  "recover": false  // Tidak perlu recover
}
```

### 4. **Organize namespaces by purpose**

```json
"namespaces": [
  // Chat & messaging
  {"name": "chat"},
  {"name": "notifications"},

  // Presence & activity
  {"name": "presence"},
  {"name": "typing"},

  // System & alerts
  {"name": "alerts"},
  {"name": "broadcast"},
  {"name": "system_events"}
]
```

---

## 🎓 Learning Path

1. **Start with basic:**
   - `chat` - peer-to-peer messaging
   - `notifications` - personal notifications

2. **Add presence:**
   - `presence` - show who's online
   - `typing` - show who's typing

3. **Add system:**
   - `alerts` - system alerts
   - `broadcast` - announcements to all

4. **Advanced:**
   - Create custom namespaces per feature
   - Fine-tune history_size & history_ttl
   - Implement permission logic

---

## 📞 Common Questions

### Q: Bisa add unlimited namespaces?

**A:** Ya! Centrifugo support unlimited namespaces. Tapi lebih baik organize dengan baik.

### Q: Bisa change namespace config tanpa restart?

**A:** Tidak. Harus restart Centrifugo container:

```bash
docker-compose restart centrifugo
```

### Q: Berapa max history_size yang reasonable?

**A:** Depends:

- Real-time: 0-50
- Short-term: 50-200
- Long-term: 200-1000
- Logging: 500-5000

### Q: Lebih baik centralized atau separate namespaces?

**A:** Separate namespaces lebih baik untuk:

- Performance (less contention)
- Permission control
- Organization
- Scaling

---

## 🚀 Next Steps

1. **Gunakan namespaces yang sudah dikonfigurasi**
2. **Test dengan client applications**
3. **Tambahkan namespace baru sesuai kebutuhan**
4. **Monitor performance & adjust settings**
5. **Document custom namespaces**

---

**Created:** 2026-01-20  
**Centrifugo Version:** v5  
**Documentation:** Complete
