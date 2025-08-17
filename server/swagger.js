

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'SERV Backend API',
      version: '1.0.0',
      description: 'API documentation for your attendance management backend',
    },
    servers: [
      {
        url: 'http://localhost:3000',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {              // This matches the name "bearerAuth" used in your routes
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
    security: [
      {
        bearerAuth: [],           // This applies bearer auth globally to all endpoints by default
      },
    ],
  },
  apis: ['./routes/*.js'],       // Include your route files here
};

const swaggerJSDoc = require('swagger-jsdoc');
const swaggerSpec = swaggerJSDoc(options);
module.exports = swaggerSpec;
