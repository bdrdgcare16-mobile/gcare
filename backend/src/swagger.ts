import swaggerUi from 'swagger-ui-express';
import swaggerJSDoc from 'swagger-jsdoc';
import express from 'express';

const app = express();

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Nishali HRMS API',
      version: '1.0.0',
      description: 'API documentation for Nishali HRMS backend',
    },
    servers: [
      { url: 'http://localhost:3000', description: 'Local server' },
    ],
  },
  apis: ['./src/routes/*.ts'],
};

const swaggerSpec = swaggerJSDoc(options);

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.listen(4000, () => {
  console.log('Swagger docs available at http://localhost:4000/api-docs');
}); 