const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const path = require('path');

const options = {
  definition: {
    openapi: '3.0.0', // Correct OpenAPI version
    info: {
      title: 'Tailor API',
      version: '1.0.0', // API version (move this under `info`)
      description: 'A Tailor App API with Swagger documentation',
    },
  },
  apis: [path.join(__dirname, '../routes/*.js')],
};

const specs = swaggerJsdoc(options);

module.exports = {
  specs,
  swaggerUi,
};
