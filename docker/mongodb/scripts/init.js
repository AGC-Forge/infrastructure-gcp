// init.js - MongoDB Initialization Script with Customizable Credentials

// Tunggu sebentar untuk memastikan MongoDB siap
sleep(5000);

// Dapatkan environment variables
var rootUser = process.env.MONGO_INITDB_ROOT_USERNAME || "forge";
var rootPassword = process.env.MONGO_INITDB_ROOT_PASSWORD || "Resti#2305";
var appUser = process.env.MONGO_APP_USER || "forge";
var appPassword = process.env.MONGO_APP_PASSWORD || "Resti#2305";
var appDb = process.env.MONGO_APP_DB || "forge_db";

print("======================================");
print("MongoDB Initialization Started");
print("======================================");
print("Root User:", rootUser);
print("Application Database:", appDb);
print("Application User:", appUser);
print("======================================");

// Connect to admin database and authenticate using runCommand with auth
db = db.getSiblingDB("admin");

// Use runCommand for authentication which is more reliable
var authResult = db.runCommand({
  authScheme: "SCRAM-SHA-1",
  user: rootUser,
  pwd: rootPassword,
  digestPassword: true,
});

if (authResult.ok !== 1) {
  print("ERROR: Authentication failed for root user");
  print("Auth result:", JSON.stringify(authResult));
} else {
  print("Successfully authenticated as root user");
}

// Buat atau switch ke application database
db = db.getSiblingDB(appDb);

// Cek apakah user sudah ada
var existingUser = db.getUser(appUser);
if (existingUser) {
  print("User " + appUser + " already exists, updating...");
  db.updateUser(appUser, {
    roles: [
      { role: "readWrite", db: appDb },
      { role: "dbAdmin", db: appDb },
    ],
  });
} else {
  print("Creating new user: " + appUser);
  // Create application user with readWrite access
  db.createUser({
    user: appUser,
    pwd: appPassword,
    roles: [
      { role: "readWrite", db: appDb },
      { role: "dbAdmin", db: appDb },
    ],
    customData: {
      createdBy: "infrastructure-setup",
      createdAt: new Date(),
      environment: process.env.NODE_ENV || "development",
    },
  });
}

// Create collections with validation (only if not exists)
var collections = db.getCollectionNames();

if (!collections.includes("users")) {
  print("Creating users collection with validation...");
  db.createCollection("users", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: ["email", "createdAt"],
        properties: {
          email: {
            bsonType: "string",
            pattern: "^.+@.+$",
            description: "must be a valid email address",
          },
          username: {
            bsonType: "string",
            minLength: 3,
            maxLength: 50,
          },
          name: {
            bsonType: "string",
            maxLength: 100,
          },
          status: {
            bsonType: "string",
            enum: ["active", "inactive", "suspended"],
            description: "must be either active, inactive, or suspended",
          },
          createdAt: {
            bsonType: "date",
            description: "must be a date",
          },
          updatedAt: {
            bsonType: "date",
          },
        },
      },
    },
    validationAction: "warn",
  });
}

if (!collections.includes("sessions")) {
  print("Creating sessions collection...");
  db.createCollection("sessions", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: ["userId", "token", "expiresAt"],
        properties: {
          userId: {
            bsonType: "objectId",
            description: "reference to users collection",
          },
          token: {
            bsonType: "string",
          },
          expiresAt: {
            bsonType: "date",
          },
          createdAt: {
            bsonType: "date",
          },
        },
      },
    },
  });
}

if (!collections.includes("logs")) {
  print("Creating logs collection (capped)...");
  db.createCollection("logs", {
    capped: true,
    size: 5242880,
    max: 5000,
  });
}

// Create indexes
print("Creating/updating indexes...");

// Users collection indexes
db.users.createIndex(
  { email: 1 },
  {
    unique: true,
    background: true,
    name: "email_unique",
  },
);

db.users.createIndex(
  { username: 1 },
  {
    unique: true,
    sparse: true,
    background: true,
    name: "username_unique",
  },
);

db.users.createIndex(
  { createdAt: 1 },
  {
    background: true,
    name: "created_at_idx",
  },
);

db.users.createIndex(
  { status: 1 },
  {
    background: true,
    name: "status_idx",
  },
);

// Sessions collection indexes
db.sessions.createIndex(
  { token: 1 },
  {
    unique: true,
    background: true,
    name: "token_unique",
  },
);

db.sessions.createIndex(
  { userId: 1 },
  {
    background: true,
    name: "user_id_idx",
  },
);

db.sessions.createIndex(
  { expiresAt: 1 },
  {
    expireAfterSeconds: 0,
    background: true,
    name: "expires_at_ttl",
  },
);

// Logs collection index
db.logs.createIndex(
  { createdAt: -1 },
  {
    background: true,
    name: "logs_created_at_idx",
  },
);

// Verify setup
print("\n======================================");
print("Verifying MongoDB Setup:");
print("--------------------------------------");
print("Database:", appDb);
print("Collections:", db.getCollectionNames().join(", "));
print("Users in database:");
db.getUsers().forEach(function (user) {
  print(
    "  - " +
      user.user +
      " (roles: " +
      user.roles
        .map(function (r) {
          return r.role;
        })
        .join(", ") +
      ")",
  );
});
print("======================================");
print("MongoDB initialization completed successfully!");
print("======================================");
