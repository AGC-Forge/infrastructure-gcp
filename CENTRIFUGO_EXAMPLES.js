// Centrifugo Client Implementation Examples
// Gunakan di aplikasi frontend/backend Anda

// ============================================================================
// 1. BASIC SETUP
// ============================================================================

import { Centrifuge } from 'centrifuge';

// Koneksi ke Centrifugo
const centrifuge = new Centrifuge('ws://localhost:8000/connection/websocket', {
  token: 'your-jwt-token-here',
});

centrifuge.connect();

centrifuge.on('connected', () => {
  console.log('Connected to Centrifugo');
});

// ============================================================================
// 2. CHAT NAMESPACE - Peer-to-peer messaging
// ============================================================================

const chatSub = centrifuge.subscribe('chat', (message) => {
  console.log('Chat message:', message.data);
  // {text: "Hello", userId: 123, timestamp: ...}
});

// Publish chat message
function sendChatMessage(text) {
  chatSub.publish({ text, userId: getCurrentUserId() });
}

// ============================================================================
// 3. NOTIFICATIONS - Personal notifications
// ============================================================================

const notificationsSub = centrifuge.subscribe('notifications', (message) => {
  console.log('Notification:', message.data);
  // {type: 'order', title: 'Order confirmed', ...}
  
  // Show browser notification
  new Notification(message.data.title, {
    body: message.data.body,
    icon: '/icon.png'
  });
});

// ============================================================================
// 4. ALERTS - System-wide alerts (server-only)
// ============================================================================

const alertsSub = centrifuge.subscribe('alerts', (message) => {
  console.log('Alert received:', message.data);
  // {type: 'error', message: 'Server error', severity: 'high'}
  
  // Handle different alert types
  switch(message.data.type) {
    case 'error':
      showErrorAlert(message.data.message);
      break;
    case 'warning':
      showWarningAlert(message.data.message);
      break;
    case 'info':
      showInfoAlert(message.data.message);
      break;
  }
});

// ============================================================================
// 5. BROADCAST - Announcements to all (server-only)
// ============================================================================

const broadcastSub = centrifuge.subscribe('broadcast', (message) => {
  console.log('Broadcast:', message.data);
  // {title: 'Maintenance', duration: '2 hours', ...}
  
  showBroadcastBanner(message.data);
});

// ============================================================================
// 6. ANNOUNCEMENTS - Important notices (server-only)
// ============================================================================

const announcementsSub = centrifuge.subscribe('announcements', (message) => {
  console.log('Announcement:', message.data);
  // {title: 'New feature', description: '...', url: '...'}
  
  showAnnouncementModal(message.data);
});

// ============================================================================
// 7. SYSTEM_EVENTS - System monitoring (server-only)
// ============================================================================

const systemEventsSub = centrifuge.subscribe('system_events', (message) => {
  console.log('System event:', message.data);
  // {event: 'user_login', userId: 123, timestamp: ...}
  
  // Track user activity
  trackEvent(message.data);
});

// ============================================================================
// 8. PRESENCE - User online status
// ============================================================================

const presenceSub = centrifuge.subscribe('presence', (message) => {
  console.log('Presence update:', message.data);
});

// Listen for presence changes
presenceSub.on('subscribe', () => {
  console.log('Subscribed to presence');
});

presenceSub.on('join', (ctx) => {
  console.log('User joined:', ctx.info);
  updatePresenceUI(ctx.info);
});

presenceSub.on('leave', (ctx) => {
  console.log('User left:', ctx.info);
  removePresenceUI(ctx.info);
});

// Get current presence info
presenceSub.presence().then((data) => {
  console.log('Current presence:', data.presence);
});

// ============================================================================
// 9. TYPING - User is typing indicator
// ============================================================================

const typingSub = centrifuge.subscribe('typing', (message) => {
  console.log('User typing:', message.data);
  // {userId: 123, channel: 'chat', ...}
  
  showTypingIndicator(message.data.userId);
});

// Publish typing event
let typingTimeout;
function publishTyping() {
  clearTimeout(typingTimeout);
  
  typingSub.publish({ userId: getCurrentUserId() });
  
  // Stop showing typing after 3 seconds
  typingTimeout = setTimeout(() => {
    typingSub.publish({ userId: getCurrentUserId(), stop: true });
  }, 3000);
}

// Call when user types
document.getElementById('message-input').addEventListener('keyup', publishTyping);

// ============================================================================
// 10. USER_STATUS - Activity status tracking
// ============================================================================

const userStatusSub = centrifuge.subscribe('user_status', (message) => {
  console.log('User status:', message.data);
  // {userId: 123, status: 'in_meeting', ...}
});

userStatusSub.on('join', (ctx) => {
  console.log('User status changed:', ctx.info);
});

// ============================================================================
// 11. ERROR HANDLING
// ============================================================================

chatSub.on('error', (err) => {
  console.error('Chat subscription error:', err);
});

chatSub.on('unsubscribe', (ctx) => {
  console.log('Chat unsubscribed:', ctx.reason);
});

centrifuge.on('error', (err) => {
  console.error('Centrifugo error:', err);
});

centrifuge.on('disconnect', (ctx) => {
  console.log('Disconnected:', ctx.reason);
});

// ============================================================================
// 12. ADVANCED - Subscribe to multiple channels
// ============================================================================

class CentrifugoManager {
  constructor(wsUrl, token) {
    this.centrifuge = new Centrifuge(wsUrl, { token });
    this.subscriptions = new Map();
    this.connect();
  }

  connect() {
    this.centrifuge.connect();
  }

  subscribe(channel, callback, options = {}) {
    if (this.subscriptions.has(channel)) {
      return this.subscriptions.get(channel);
    }

    const sub = this.centrifuge.subscribe(channel, callback);
    
    if (options.onError) {
      sub.on('error', options.onError);
    }
    
    if (options.onJoin) {
      sub.on('join', options.onJoin);
    }
    
    if (options.onLeave) {
      sub.on('leave', options.onLeave);
    }

    this.subscriptions.set(channel, sub);
    return sub;
  }

  unsubscribe(channel) {
    const sub = this.subscriptions.get(channel);
    if (sub) {
      sub.unsubscribe();
      this.subscriptions.delete(channel);
    }
  }

  disconnect() {
    this.centrifuge.disconnect();
  }
}

// Usage
const manager = new CentrifugoManager(
  'ws://localhost:8000/connection/websocket',
  'your-token'
);

manager.subscribe('chat', (msg) => {
  console.log('Chat:', msg.data);
}, {
  onJoin: (ctx) => console.log('User joined'),
  onLeave: (ctx) => console.log('User left')
});

// ============================================================================
// 13. REACT HOOKS EXAMPLE
// ============================================================================

import { useEffect, useState, useRef } from 'react';

function useCentrifugo(channel) {
  const [messages, setMessages] = useState([]);
  const [isConnected, setIsConnected] = useState(false);
  const subRef = useRef(null);

  useEffect(() => {
    // Subscribe to channel
    subRef.current = centrifuge.subscribe(channel, (message) => {
      setMessages(prev => [...prev, message.data]);
    });

    // Handle connection status
    centrifuge.on('connected', () => setIsConnected(true));
    centrifuge.on('disconnect', () => setIsConnected(false));

    // Cleanup
    return () => {
      if (subRef.current) {
        subRef.current.unsubscribe();
      }
    };
  }, [channel]);

  const publish = (data) => {
    if (subRef.current) {
      subRef.current.publish(data);
    }
  };

  return { messages, isConnected, publish };
}

// Usage in component
function ChatComponent() {
  const { messages, isConnected, publish } = useCentrifugo('chat');

  return (
    <div>
      <p>Status: {isConnected ? 'Connected' : 'Disconnected'}</p>
      <div>
        {messages.map((msg, i) => (
          <p key={i}>{msg.text}</p>
        ))}
      </div>
      <button onClick={() => publish({ text: 'Hello' })}>
        Send
      </button>
    </div>
  );
}

// ============================================================================
// 14. REAL-WORLD EXAMPLE - E-Commerce Notifications
// ============================================================================

class OrderNotificationManager {
  constructor(centrifugo) {
    this.centrifugo = centrifugo;
    this.subscribe();
  }

  subscribe() {
    // Subscribe to order updates
    this.centrifugo.subscribe('orders', (message) => {
      const { orderId, status, message: msg } = message.data;
      
      switch(status) {
        case 'confirmed':
          this.showOrderConfirmed(orderId, msg);
          break;
        case 'shipped':
          this.showOrderShipped(orderId, msg);
          break;
        case 'delivered':
          this.showOrderDelivered(orderId, msg);
          break;
        case 'cancelled':
          this.showOrderCancelled(orderId, msg);
          break;
      }
    });

    // Subscribe to alerts
    this.centrifugo.subscribe('alerts', (message) => {
      const { type, message: msg } = message.data;
      
      if (type === 'stock_low') {
        this.showStockAlert(msg);
      } else if (type === 'delivery_issue') {
        this.showDeliveryAlert(msg);
      }
    });
  }

  showOrderConfirmed(orderId, message) {
    console.log(`Order ${orderId} confirmed: ${message}`);
    // Update UI...
  }

  showOrderShipped(orderId, message) {
    console.log(`Order ${orderId} shipped: ${message}`);
    // Update UI...
  }

  showOrderDelivered(orderId, message) {
    console.log(`Order ${orderId} delivered: ${message}`);
    // Update UI...
  }

  showOrderCancelled(orderId, message) {
    console.log(`Order ${orderId} cancelled: ${message}`);
    // Update UI...
  }

  showStockAlert(message) {
    console.log(`Stock alert: ${message}`);
    // Update UI...
  }

  showDeliveryAlert(message) {
    console.log(`Delivery alert: ${message}`);
    // Update UI...
  }
}

// Usage
const orderManager = new OrderNotificationManager(centrifuge);

// ============================================================================
// 15. SERVER-SIDE EXAMPLES (Node.js + Centrifugo SDK)
// ============================================================================

/*
// Publish alert
await centrifugo.api.publish('alerts', {
  type: 'error',
  message: 'Critical system error',
  severity: 'high',
  timestamp: new Date()
});

// Broadcast announcement
await centrifugo.api.publish('broadcast', {
  title: 'System Maintenance',
  message: 'Sistem maintenance jam 22:00 WIB',
  duration: '2 hours',
  url: 'https://status.example.com'
});

// Publish order update
await centrifugo.api.publish('orders', {
  orderId: 'ORD-12345',
  status: 'shipped',
  message: 'Order telah dikirim',
  trackingUrl: 'https://track.courier.com/...'
});

// Publish system event
await centrifugo.api.publish('system_events', {
  event: 'user_login',
  userId: 123,
  timestamp: new Date(),
  ipAddress: '192.168.1.1'
});

// Get presence info
const presence = await centrifugo.api.presence('presence');
console.log('Current users:', presence);

// Get channel info
const info = await centrifugo.api.info('chat');
console.log('Channel info:', info);
*/

// ============================================================================
// END OF EXAMPLES
// ============================================================================

export { CentrifugoManager, useCentrifugo, OrderNotificationManager };
