// // // // const express = require('express');
// // // // const router = express.Router();
// // // // const ctrl = require('../controllers/eventController');

// // // // /**
// // // //  * @swagger
// // // //  * tags:
// // // //  *   - name: Events
// // // //  *     description: Manage events (admin & user)
// // // //  */

// // // // /**
// // // //  * @swagger
// // // //  * components:
// // // //  *   schemas:
// // // //  *     Event:
// // // //  *       type: object
// // // //  *       required:
// // // //  *         - title
// // // //  *         - description
// // // //  *         - location
// // // //  *         - fromDate
// // // //  *         - toDate
// // // //  *       properties:
// // // //  *         title:
// // // //  *           type: string
// // // //  *           description: Title of the event
// // // //  *         description:
// // // //  *           type: string
// // // //  *           description: Description of the event
// // // //  *         location:
// // // //  *           type: string
// // // //  *           description: Location where the event is held
// // // //  *         fromDate:
// // // //  *           type: string
// // // //  *           format: date
// // // //  *           description: Start date of the event
// // // //  *         toDate:
// // // //  *           type: string
// // // //  *           format: date
// // // //  *           description: End date of the event
// // // //  *         image:
// // // //  *           type: string
// // // //  *           format: binary
// // // //  *           description: Image upload for the event
// // // //  *         file:
// // // //  *           type: string
// // // //  *           format: binary
// // // //  *           description: File upload for the event
// // // //  */

// // // // module.exports = (db) => {
// // // //   router.use((req, res, next) => {
// // // //     req.app.locals.db = db;
// // // //     next();
// // // //   });

// // // //   /**
// // // //    * @swagger
// // // //    * /api/events:
// // // //    *   post:
// // // //    *     summary: Create a new event (Admin only)
// // // //    *     tags: [Events]
// // // //    *     consumes:
// // // //    *       - multipart/form-data
// // // //    *     requestBody:
// // // //    *       required: true
// // // //    *       content:
// // // //    *         multipart/form-data:
// // // //    *           schema:
// // // //    *             type: object
// // // //    *             properties:
// // // //    *               title:
// // // //    *                 type: string
// // // //    *               description:
// // // //    *                 type: string
// // // //    *               location:
// // // //    *                 type: string
// // // //    *               fromDate:
// // // //    *                 type: string
// // // //    *                 format: date
// // // //    *               toDate:
// // // //    *                 type: string
// // // //    *                 format: date
// // // //    *               image:
// // // //    *                 type: string
// // // //    *                 format: binary
// // // //    *               file:
// // // //    *                 type: string
// // // //    *                 format: binary
// // // //    *     responses:
// // // //    *       201:
// // // //    *         description: Event created successfully
// // // //    *       400:
// // // //    *         description: Missing required fields
// // // //    *       500:
// // // //    *         description: Internal server error
// // // //    */
// // // //   router.post('/', ctrl.createEvent);

// // // //   /**
// // // //    * @swagger
// // // //    * /api/events:
// // // //    *   get:
// // // //    *     summary: Get all events
// // // //    *     tags: [Events]
// // // //    *     responses:
// // // //    *       200:
// // // //    *         description: List of all events
// // // //    *         content:
// // // //    *           application/json:
// // // //    *             schema:
// // // //    *               type: array
// // // //    *               items:
// // // //    *                 $ref: '#/components/schemas/Event'
// // // //    *       500:
// // // //    *         description: Internal server error
// // // //    */
// // // //   router.get('/', ctrl.getAllEvents);

// // // //   /**
// // // //    * @swagger
// // // //    * /api/events/{id}:
// // // //    *   delete:
// // // //    *     summary: Delete an event by ID
// // // //    *     tags: [Events]
// // // //    *     parameters:
// // // //    *       - in: path
// // // //    *         name: id
// // // //    *         required: true
// // // //    *         schema:
// // // //    *           type: string
// // // //    *         description: Firestore document ID of the event to delete
// // // //    *     responses:
// // // //    *       200:
// // // //    *         description: Event deleted successfully
// // // //    *       500:
// // // //    *         description: Server error
// // // //    */
// // // //   router.delete('/:id', ctrl.deleteEvent);
// // // //   // ✅✅✅ ✅ END NEW
// // // // return router;
// // // // };
// // // /* routes/events.js */
// // // const express = require('express');
// // // const router = express.Router();
// // // const ctrl = require('../controllers/eventController');

// // // /**
// // //  * @openapi
// // //  * tags:
// // //  *   - name: Events
// // //  *     description: Manage events (admin & user)
// // //  *
// // //  * components:
// // //  *   schemas:
// // //  *     EventIn:
// // //  *       type: object
// // //  *       required: [title, description, location, fromDate, toDate]
// // //  *       properties:
// // //  *         title:
// // //  *           type: string
// // //  *           example: Independence Day
// // //  *         description:
// // //  *           type: string
// // //  *           example: Flag hoisting at 9AM
// // //  *         location:
// // //  *           type: string
// // //  *           example: Main Hall
// // //  *         fromDate:
// // //  *           type: string
// // //  *           format: date
// // //  *           example: 2025-08-15
// // //  *         toDate:
// // //  *           type: string
// // //  *           format: date
// // //  *           example: 2025-08-15
// // //  *         image:
// // //  *           type: string
// // //  *           format: binary
// // //  *           description: Event banner (optional)
// // //  *         file:
// // //  *           type: string
// // //  *           format: binary
// // //  *           description: Related file (PDF/DOC/etc., optional)
// // //  *     EventOut:
// // //  *       allOf:
// // //  *         - $ref: '#/components/schemas/EventIn'
// // //  *         - type: object
// // //  *           properties:
// // //  *             id:
// // //  *               type: string
// // //  *               example: tR8NvqbV3tpxBDQbqgmb
// // //  *             imageUrl:
// // //  *               type: string
// // //  *               nullable: true
// // //  *               example: /uploads/2b9d…-banner.png
// // //  *             fileUrl:
// // //  *               type: string
// // //  *               nullable: true
// // //  *               example: /uploads/8c3a…-brochure.pdf
// // //  *             createdAt:
// // //  *               type: string
// // //  *               format: date-time
// // //  */

// // // /**
// // //  * Wire Firestore handle into each request (db is injected from server.js)
// // //  */
// // // module.exports = (db) => {
// // //   router.use((req, _res, next) => {
// // //     req.app.locals.db = db;
// // //     next();
// // //   });

// // //   /**
// // //    * @openapi
// // //    * /api/events:
// // //    *   post:
// // //    *     summary: Create a new event (Admin)
// // //    *     tags: [Events]
// // //    *     requestBody:
// // //    *       required: true
// // //    *       content:
// // //    *         multipart/form-data:
// // //    *           schema:
// // //    *             $ref: '#/components/schemas/EventIn'
// // //    *     responses:
// // //    *       201:
// // //    *         description: Event created
// // //    *         content:
// // //    *           application/json:
// // //    *             schema:
// // //    *               $ref: '#/components/schemas/EventOut'
// // //    *       400:
// // //    *         description: Missing required fields
// // //    *       500:
// // //    *         description: Server error
// // //    */
// // //   router.post('/', ctrl.createEvent);

// // //   /**
// // //    * @openapi
// // //    * /api/events:
// // //    *   get:
// // //    *     summary: List all events
// // //    *     tags: [Events]
// // //    *     responses:
// // //    *       200:
// // //    *         description: Array of events
// // //    *         content:
// // //    *           application/json:
// // //    *             schema:
// // //    *               type: array
// // //    *               items:
// // //    *                 $ref: '#/components/schemas/EventOut'
// // //    *       500:
// // //    *         description: Server error
// // //    */
// // //   router.get('/', ctrl.getAllEvents);

// // //   /**
// // //    * @openapi
// // //    * /api/events/{id}:
// // //    *   delete:
// // //    *     summary: Delete an event by ID
// // //    *     tags: [Events]
// // //    *     parameters:
// // //    *       - in: path
// // //    *         name: id
// // //    *         required: true
// // //    *         schema:
// // //    *           type: string
// // //    *         description: Firestore document ID
// // //    *     responses:
// // //    *       200:
// // //    *         description: Deleted
// // //    *       500:
// // //    *         description: Server error
// // //    */
// // //   router.delete('/:id', ctrl.deleteEvent);

// // //   return router;
// // // };
// // /* routes/events.js */
// // const express = require('express');
// // const router = express.Router();
// // const ctrl = require('../controllers/eventController');

// // /**
// //  * @openapi
// //  * tags:
// //  *   - name: Events
// //  *     description: Manage events (admin & user)
// //  *
// //  * components:
// //  *   schemas:
// //  *     EventIn:
// //  *       type: object
// //  *       required: [title, description, location, fromDate, toDate]
// //  *       properties:
// //  *         title:       { type: string, example: AI Conference }
// //  *         description: { type: string, example: AI in healthcare }
// //  *         location:    { type: string, example: Chennai }
// //  *         fromDate:    { type: string, format: date, example: 2025-08-13 }
// //  *         toDate:      { type: string, format: date, example: 2025-08-15 }
// //  *         image:       { type: string, format: binary, description: Optional image }
// //  *         file:        { type: string, format: binary, description: Optional related file }
// //  *     EventOut:
// //  *       allOf:
// //  *         - $ref: '#/components/schemas/EventIn'
// //  *         - type: object
// //  *           properties:
// //  *             id:        { type: string, example: tR8NvqbV3tpxBDQbqgmb }
// //  *             imageUrl:  { type: string, nullable: true }
// //  *             fileUrl:   { type: string, nullable: true }
// //  *             createdAt: { type: string, format: date-time }
// //  */

// // module.exports = (db) => {
// //   router.use((req, _res, next) => {
// //     req.app.locals.db = db;
// //     next();
// //   });

// //   /**
// //    * @openapi
// //    * /api/events:
// //    *   post:
// //    *     summary: Create a new event (multipart/form-data)
// //    *     tags: [Events]
// //    *     requestBody:
// //    *       required: true
// //    *       content:
// //    *         multipart/form-data:
// //    *           schema: { $ref: '#/components/schemas/EventIn' }
// //    *     responses:
// //    *       201: { description: Created, content: { application/json: { schema: { $ref: '#/components/schemas/EventOut' } } } }
// //    *       400: { description: Missing fields }
// //    *       500: { description: Server error }
// //    */
// //   router.post('/', ctrl.createEvent);

// //   /**
// //    * @openapi
// //    * /api/events:
// //    *   get:
// //    *     summary: Get all events
// //    *     tags: [Events]
// //    *     responses:
// //    *       200:
// //    *         description: OK
// //    *         content:
// //    *           application/json:
// //    *             schema:
// //    *               type: array
// //    *               items: { $ref: '#/components/schemas/EventOut' }
// //    *       500: { description: Server error }
// //    */
// //   router.get('/', ctrl.getAllEvents);

// //   /**
// //    * @openapi
// //    * /api/events/{id}:
// //    *   delete:
// //    *     summary: Delete an event
// //    *     tags: [Events]
// //    *     parameters:
// //    *       - in: path
// //    *         name: id
// //    *         required: true
// //    *         schema: { type: string }
// //    *     responses:
// //    *       200: { description: Deleted }
// //    *       500: { description: Server error }
// //    */
// //   router.delete('/:id', ctrl.deleteEvent);

// //   return router;
// // };
// // routes/events.js
// const express = require('express');
// const router = express.Router();
// const ctrl = require('../controllers/eventController');

// /**
//  * @openapi
//  * tags:
//  *   - name: Events
//  *     description: Manage events (admin & user)
//  *
//  * components:
//  *   schemas:
//  *     EventIn:
//  *       type: object
//  *       required: [title, description, location, fromDate, toDate]
//  *       properties:
//  *         title:       { type: string, example: AI Conference }
//  *         description: { type: string, example: AI in healthcare }
//  *         location:    { type: string, example: Chennai }
//  *         fromDate:    { type: string, format: date, example: 2025-08-13 }
//  *         toDate:      { type: string, format: date, example: 2025-08-15 }
//  *         image:       { type: string, format: binary, description: Optional image }
//  *         file:        { type: string, format: binary, description: Optional related file }
//  *     EventOut:
//  *       allOf:
//  *         - $ref: '#/components/schemas/EventIn'
//  *         - type: object
//  *           properties:
//  *             id:        { type: string, example: tR8NvqbV3tpxBDQbqgmb }
//  *             imageUrl:  { type: string, nullable: true }
//  *             fileUrl:   { type: string, nullable: true }
//  *             createdAt: { type: string, format: date-time }
//  */

// module.exports = (db) => {
//   // inject Firestore
//   router.use((req, _res, next) => { req.app.locals.db = db; next(); });

//   /**
//    * @openapi
//    * /api/events:
//    *   post:
//    *     summary: Create a new event (multipart/form-data)
//    *     tags: [Events]
//    *     requestBody:
//    *       required: true
//    *       content:
//    *         multipart/form-data:
//    *           schema: { $ref: '#/components/schemas/EventIn' }
//    *     responses:
//    *       201:
//    *         description: Created
//    *         content:
//    *           application/json:
//    *             schema: { $ref: '#/components/schemas/EventOut' }
//    *       400: { description: Missing fields }
//    *       500: { description: Server error }
//    */
//   router.post('/', ctrl.createEvent);

//   /**
//    * @openapi
//    * /api/events:
//    *   get:
//    *     summary: Get all events
//    *     tags: [Events]
//    *     responses:
//    *       200:
//    *         description: OK
//    *         content:
//    *           application/json:
//    *             schema:
//    *               type: array
//    *               items: { $ref: '#/components/schemas/EventOut' }
//    *       500: { description: Server error }
//    */
//   router.get('/', ctrl.getAllEvents);

//   /**
//    * @openapi
//    * /api/events/{id}:
//    *   delete:
//    *     summary: Delete an event
//    *     tags: [Events]
//    *     parameters:
//    *       - in: path
//    *         name: id
//    *         required: true
//    *         schema: { type: string }
//    *     responses:
//    *       200: { description: Deleted }
//    *       500: { description: Server error }
//    */
//   router.delete('/:id', ctrl.deleteEvent);

//   return router;
// };
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/eventController');

/**
 * @openapi
 * tags:
 *   - name: Events
 *     description: Manage events (admin & user)
 *
 * components:
 *   schemas:
 *     EventIn:
 *       type: object
 *       required: [title, description, location, fromDate, toDate]
 *       properties:
 *         title:       { type: string, example: AI Conference }
 *         description: { type: string, example: AI in healthcare }
 *         location:    { type: string, example: Chennai }
 *         fromDate:    { type: string, format: date, example: 2025-08-13 }
 *         toDate:      { type: string, format: date, example: 2025-08-15 }
 *         image:       { type: string, format: binary, description: Optional image }
 *         file:        { type: string, format: binary, description: Optional related file }
 *     EventOut:
 *       allOf:
 *         - $ref: '#/components/schemas/EventIn'
 *         - type: object
 *           properties:
 *             id:        { type: string, example: tR8NvqbV3tpxBDQbqgmb }
 *             imageUrl:  { type: string, nullable: true }
 *             fileUrl:   { type: string, nullable: true }
 *             createdAt: { type: string, format: date-time }
 */

module.exports = (db) => {
  // Make Firestore available on req.app.locals.db
  router.use((req, _res, next) => { req.app.locals.db = db; next(); });

  /**
   * @openapi
   * /api/events:
   *   post:
   *     summary: Create a new event (multipart/form-data)
   *     tags: [Events]
   *     requestBody:
   *       required: true
   *       content:
   *         multipart/form-data:
   *           schema: { $ref: '#/components/schemas/EventIn' }
   *     responses:
   *       201:
   *         description: Created
   *         content:
   *           application/json:
   *             schema: { $ref: '#/components/schemas/EventOut' }
   *       400: { description: Missing fields }
   *       500: { description: Server error }
   */
  router.post('/', ctrl.createEvent);

  /**
   * @openapi
   * /api/events:
   *   get:
   *     summary: Get all events
   *     tags: [Events]
   *     responses:
   *       200:
   *         description: OK
   *         content:
   *           application/json:
   *             schema:
   *               type: array
   *               items: { $ref: '#/components/schemas/EventOut' }
   *       500: { description: Server error }
   */
  router.get('/', ctrl.getAllEvents);

  /**
   * @openapi
   * /api/events/{id}:
   *   delete:
   *     summary: Delete an event
   *     tags: [Events]
   *     parameters:
   *       - in: path
   *         name: id
   *         required: true
   *         schema: { type: string }
   *     responses:
   *       200: { description: Deleted }
   *       500: { description: Server error }
   */
  router.delete('/:id', ctrl.deleteEvent);

  return router;
};
