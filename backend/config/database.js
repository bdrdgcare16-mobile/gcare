// Database configuration for PostgreSQL
const config = {
  development: {
    DATABASE_URL: "postgresql://postgres:Nishali@localhost:5432/SERV",
    PORT: 3000,
    NODE_ENV: "development",
    JWT_SECRET: "your-super-secret-jwt-key-change-this-in-production",
    JWT_EXPIRES_IN: "7d",
    CORS_ORIGIN: "http://localhost:3000,http://localhost:8080,http://localhost:3001",
    LOG_LEVEL: "info"
  },
  production: {
    DATABASE_URL: process.env.DATABASE_URL || "postgresql://postgres:Nishali@localhost:5432/SERV",
    PORT: process.env.PORT || 3000,
    NODE_ENV: "production",
    JWT_SECRET: process.env.JWT_SECRET || "your-super-secret-jwt-key-change-this-in-production",
    JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || "7d",
    CORS_ORIGIN: process.env.CORS_ORIGIN || "*",
    LOG_LEVEL: process.env.LOG_LEVEL || "error"
  }
};

const env = process.env.NODE_ENV || "development";
module.exports = config[env]; 