// // // // // // const express = require('express');
// // // // // // const router = express.Router();
// // // // // // const authController = require('../controllers/authController');


// // // // // // /**
// // // // // //  * @swagger
// // // // // //  * /api/auth/login:
// // // // // //  *   post:
// // // // // //  *     summary: User login
// // // // // //  *     description: Login with email and password and get JWT token
// // // // // //  *     requestBody:
// // // // // //  *       required: true
// // // // // //  *       content:
// // // // // //  *         application/json:
// // // // // //  *           schema:
// // // // // //  *             type: object
// // // // // //  *             properties:
// // // // // //  *               email:
// // // // // //  *                 type: string
// // // // // //  *                 example: user@example.com
// // // // // //  *               password:
// // // // // //  *                 type: string
// // // // // //  *                 example: password123
// // // // // //  *     responses:
// // // // // //  *       200:
// // // // // //  *         description: Successful login
// // // // // //  *       401:
// // // // // //  *         description: Invalid credentials
// // // // // //  */
// // // // // // router.post('/login', authController.login);



// // // // // // /**
// // // // // //  * @swagger
// // // // // //  * /api/auth/change-password:
// // // // // //  *   post:
// // // // // //  *     summary: Change user password
// // // // // //  *     description: Change your password by providing old and new passwords.
// // // // // //  *     requestBody:
// // // // // //  *       required: true
// // // // // //  *       content:
// // // // // //  *         application/json:
// // // // // //  *           schema:
// // // // // //  *             type: object
// // // // // //  *             properties:
// // // // // //  *               email:
// // // // // //  *                 type: string
// // // // // //  *                 example: user@example.com
// // // // // //  *               oldPassword:
// // // // // //  *                 type: string
// // // // // //  *                 example: oldpassword123
// // // // // //  *               newPassword:
// // // // // //  *                 type: string
// // // // // //  *                 example: newpassword456
// // // // // //  *     responses:
// // // // // //  *       200:
// // // // // //  *         description: Password changed successfully
// // // // // //  *       400:
// // // // // //  *         description: Missing required fields
// // // // // //  *       401:
// // // // // //  *         description: Old password incorrect or unauthorized
// // // // // //  *       500:
// // // // // //  *         description: Internal server error
// // // // // //  */
// // // // // // router.post('/change-password', authController.changePassword);

// // // // // // /**
// // // // // //  * @swagger
// // // // // //  * /api/auth/register:
// // // // // //  *   post:
// // // // // //  *     summary: Register a new user (employee/admin)
// // // // // //  *     tags:
// // // // // //  *       - Authentication
// // // // // //  *     requestBody:
// // // // // //  *       required: true
// // // // // //  *       content:
// // // // // //  *         application/json:
// // // // // //  *           schema:
// // // // // //  *             type: object
// // // // // //  *             required:
// // // // // //  *               - empid
// // // // // //  *               - name
// // // // // //  *               - email
// // // // // //  *               - password
// // // // // //  *               - role
// // // // // //  *             properties:
// // // // // //  *               empid:
// // // // // //  *                 type: string
// // // // // //  *                 example: EMP001
// // // // // //  *               name:
// // // // // //  *                 type: string
// // // // // //  *                 example: Pavi
// // // // // //  *               email:
// // // // // //  *                 type: string
// // // // // //  *                 example: pavi@example.com
// // // // // //  *               password:
// // // // // //  *                 type: string
// // // // // //  *                 example: mysecurepassword
// // // // // //  *               role:
// // // // // //  *                 type: string
// // // // // //  *                 description: User role (e.g., admin, employee)
// // // // // //  *                 example: employee
// // // // // //  *     responses:
// // // // // //  *       200:
// // // // // //  *         description: User registered successfully
// // // // // //  *         content:
// // // // // //  *           application/json:
// // // // // //  *             schema:
// // // // // //  *               type: object
// // // // // //  *               properties:
// // // // // //  *                 message:
// // // // // //  *                   type: string
// // // // // //  *                   example: User registered successfully
// // // // // //  *                 userId:
// // // // // //  *                   type: string
// // // // // //  *                   example: hWV4b1p7mSGMdNEytEZs
// // // // // //  *       400:
// // // // // //  *         description: Validation error or user already exists
// // // // // //  *       500:
// // // // // //  *         description: Server error
// // // // // //  */

// // // // // // router.post('/register', authController.register);


// // // // // // module.exports = router;

// // // // // const express = require('express');
// // // // // const router = express.Router();
// // // // // const authController = require('../controllers/authController');

// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/auth/login:
// // // // //  *   post:
// // // // //  *     summary: User login
// // // // //  *     description: Login with email and password and get JWT token
// // // // //  *     tags:
// // // // //  *       - Authentication
// // // // //  *     requestBody:
// // // // //  *       required: true
// // // // //  *       content:
// // // // //  *         application/json:
// // // // //  *           schema:
// // // // //  *             type: object
// // // // //  *             properties:
// // // // //  *               email:
// // // // //  *                 type: string
// // // // //  *                 example: user@example.com
// // // // //  *               password:
// // // // //  *                 type: string
// // // // //  *                 example: password123
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: Successful login
// // // // //  *       401:
// // // // //  *         description: Invalid credentials
// // // // //  */
// // // // // router.post('/login', authController.login);

// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/auth/register:
// // // // //  *   post:
// // // // //  *     summary: Register a new user (employee/admin)
// // // // //  *     tags:
// // // // //  *       - Authentication
// // // // //  *     requestBody:
// // // // //  *       required: true
// // // // //  *       content:
// // // // //  *         application/json:
// // // // //  *           schema:
// // // // //  *             type: object
// // // // //  *             required:
// // // // //  *               - empid
// // // // //  *               - name
// // // // //  *               - email
// // // // //  *               - password
// // // // //  *               - role
// // // // //  *             properties:
// // // // //  *               empid:
// // // // //  *                 type: string
// // // // //  *                 example: EMP001
// // // // //  *               name:
// // // // //  *                 type: string
// // // // //  *                 example: Pavi
// // // // //  *               email:
// // // // //  *                 type: string
// // // // //  *                 example: pavi@example.com
// // // // //  *               password:
// // // // //  *                 type: string
// // // // //  *                 example: mysecurepassword
// // // // //  *               role:
// // // // //  *                 type: string
// // // // //  *                 example: employee
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: User registered successfully
// // // // //  *       400:
// // // // //  *         description: Validation error or user already exists
// // // // //  *       500:
// // // // //  *         description: Server error
// // // // //  */
// // // // // router.post('/register', authController.register);

// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/auth/change-password:
// // // // //  *   post:
// // // // //  *     summary: Change user password
// // // // //  *     description: Change your password by providing old and new passwords.
// // // // //  *     tags:
// // // // //  *       - Authentication
// // // // //  *     requestBody:
// // // // //  *       required: true
// // // // //  *       content:
// // // // //  *         application/json:
// // // // //  *           schema:
// // // // //  *             type: object
// // // // //  *             properties:
// // // // //  *               email:
// // // // //  *                 type: string
// // // // //  *                 example: user@example.com
// // // // //  *               oldPassword:
// // // // //  *                 type: string
// // // // //  *                 example: oldpassword123
// // // // //  *               newPassword:
// // // // //  *                 type: string
// // // // //  *                 example: newpassword456
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: Password changed successfully
// // // // //  *       400:
// // // // //  *         description: Missing required fields
// // // // //  *       401:
// // // // //  *         description: Old password incorrect or unauthorized
// // // // //  *       500:
// // // // //  *         description: Internal server error
// // // // //  */
// // // // // router.post('/change-password', authController.changePassword);

// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/auth/forgot-password:
// // // // //  *   post:
// // // // //  *     summary: Forgot password (reset without old password)
// // // // //  *     tags:
// // // // //  *       - Authentication
// // // // //  *     requestBody:
// // // // //  *       required: true
// // // // //  *       content:
// // // // //  *         application/json:
// // // // //  *           schema:
// // // // //  *             type: object
// // // // //  *             properties:
// // // // //  *               email:
// // // // //  *                 type: string
// // // // //  *                 example: user@example.com
// // // // //  *               newPassword:
// // // // //  *                 type: string
// // // // //  *                 example: newsecurepassword
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: Password reset successfully
// // // // //  *       400:
// // // // //  *         description: Missing required fields
// // // // //  *       404:
// // // // //  *         description: User not found
// // // // //  *       500:
// // // // //  *         description: Internal server error
// // // // //  */
// // // // // router.post('/forgot-password', authController.forgotPassword); // ✅ NEW ENDPOINT

// // // // // module.exports = router;
// // // // const express = require('express');
// // // // const router = express.Router();
// // // // const authController = require('../controllers/authController'); // Import controller functions

// // // // /**
// // // //  * @swagger
// // // //  * /api/auth/login:
// // // //  *   post:
// // // //  *     summary: User login
// // // //  *     description: Login with email and password and get JWT token
// // // //  *     tags:
// // // //  *       - Authentication
// // // //  *     requestBody:
// // // //  *       required: true
// // // //  *       content:
// // // //  *         application/json:
// // // //  *           schema:
// // // //  *             type: object
// // // //  *             properties:
// // // //  *               email:
// // // //  *                 type: string
// // // //  *                 example: user@example.com
// // // //  *               password:
// // // //  *                 type: string
// // // //  *                 example: password123
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: Successful login
// // // //  *       401:
// // // //  *         description: Invalid credentials
// // // //  */
// // // // router.post('/login', authController.login);

// // // // /**
// // // //  * @swagger
// // // //  * /api/auth/register:
// // // //  *   post:
// // // //  *     summary: Register a new user (employee/admin)
// // // //  *     tags:
// // // //  *       - Authentication
// // // //  *     requestBody:
// // // //  *       required: true
// // // //  *       content:
// // // //  *         application/json:
// // // //  *           schema:
// // // //  *             type: object
// // // //  *             required:
// // // //  *               - empid
// // // //  *               - name
// // // //  *               - email
// // // //  *               - password
// // // //  *               - role
// // // //  *             properties:
// // // //  *               empid:
// // // //  *                 type: string
// // // //  *                 example: EMP001
// // // //  *               name:
// // // //  *                 type: string
// // // //  *                 example: Pavi
// // // //  *               email:
// // // //  *                 type: string
// // // //  *                 example: pavi@example.com
// // // //  *               password:
// // // //  *                 type: string
// // // //  *                 example: mysecurepassword
// // // //  *               role:
// // // //  *                 type: string
// // // //  *                 example: employee
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: User registered successfully
// // // //  *       400:
// // // //  *         description: Validation error or user already exists
// // // //  *       500:
// // // //  *         description: Server error
// // // //  */
// // // // router.post('/register', authController.register);

// // // // /**
// // // //  * @swagger
// // // //  * /api/auth/change-password:
// // // //  *   post:
// // // //  *     summary: Change user password
// // // //  *     description: Change your password by providing old and new passwords.
// // // //  *     tags:
// // // //  *       - Authentication
// // // //  *     requestBody:
// // // //  *       required: true
// // // //  *       content:
// // // //  *         application/json:
// // // //  *           schema:
// // // //  *             type: object
// // // //  *             properties:
// // // //  *               email:
// // // //  *                 type: string
// // // //  *                 example: user@example.com
// // // //  *               oldPassword:
// // // //  *                 type: string
// // // //  *                 example: oldpassword123
// // // //  *               newPassword:
// // // //  *                 type: string
// // // //  *                 example: newpassword456
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: Password changed successfully
// // // //  *       400:
// // // //  *         description: Missing required fields
// // // //  *       401:
// // // //  *         description: Old password incorrect or unauthorized
// // // //  *       500:
// // // //  *         description: Internal server error
// // // //  */
// // // // router.post('/change-password', authController.changePassword);

// // // // /**
// // // //  * @swagger
// // // //  * /api/auth/forgot-password:
// // // //  *   post:
// // // //  *     summary: Forgot password (reset without old password)
// // // //  *     tags:
// // // //  *       - Authentication
// // // //  *     requestBody:
// // // //  *       required: true
// // // //  *       content:
// // // //  *         application/json:
// // // //  *           schema:
// // // //  *             type: object
// // // //  *             properties:
// // // //  *               email:
// // // //  *                 type: string
// // // //  *                 example: user@example.com
// // // //  *               newPassword:
// // // //  *                 type: string
// // // //  *                 example: newsecurepassword
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: Password reset successfully
// // // //  *       400:
// // // //  *         description: Missing required fields
// // // //  *       404:
// // // //  *         description: User not found
// // // //  *       500:
// // // //  *         description: Internal server error
// // // //  */
// // // // router.post('/forgot-password', authController.forgotPassword);

// // // // module.exports = router;
// // // const express = require('express');
// // // const router  = express.Router();
// // // const authController = require('../controllers/authController');
// // // const { verifyToken } = require('../middlewares/authMiddleware');

// // // /**
// // //  * @swagger
// // //  * tags:
// // //  *   - name: Authentication
// // //  *     description: Login, register, and password management
// // //  * components:
// // //  *   securitySchemes:
// // //  *     bearerAuth:
// // //  *       type: http
// // //  *       scheme: bearer
// // //  *       bearerFormat: JWT
// // //  */

// // // /**
// // //  * @swagger
// // //  * /api/auth/login:
// // //  *   post:
// // //  *     summary: User login (returns token + role)
// // //  *     tags: [Authentication]
// // //  *     requestBody:
// // //  *       required: true
// // //  *       content:
// // //  *         application/json:
// // //  *           schema:
// // //  *             type: object
// // //  *             properties:
// // //  *               email:
// // //  *                 type: string
// // //  *               password:
// // //  *                 type: string
// // //  *     responses:
// // //  *       200:
// // //  *         description: Successful login, returns { token, role, … }
// // //  *       400:
// // //  *         description: Missing email or password
// // //  *       401:
// // //  *         description: Invalid credentials
// // //  */
// // // router.post('/login', authController.login);

// // // /**
// // //  * @swagger
// // //  * /api/auth/register:
// // //  *   post:
// // //  *     summary: Register a new user (employee or admin)
// // //  *     tags: [Authentication]
// // //  *     requestBody:
// // //  *       required: true
// // //  *       content:
// // //  *         application/json:
// // //  *           schema:
// // //  *             type: object
// // //  *             required:
// // //  *               - empid
// // //  *               - name
// // //  *               - email
// // //  *               - password
// // //  *               - role
// // //  *             properties:
// // //  *               empid:
// // //  *                 type: string
// // //  *               name:
// // //  *                 type: string
// // //  *               email:
// // //  *                 type: string
// // //  *               password:
// // //  *                 type: string
// // //  *               role:
// // //  *                 type: string
// // //  *                 enum: [admin, employee]
// // //  *     responses:
// // //  *       200:
// // //  *         description: User registered successfully
// // //  *       400:
// // //  *         description: Validation error or user exists
// // //  */
// // // router.post('/register', authController.register);

// // // /**
// // //  * @swagger
// // //  * /api/auth/change-password:
// // //  *   post:
// // //  *     summary: Change user password
// // //  *     tags: [Authentication]
// // //  *     requestBody:
// // //  *       required: true
// // //  *       content:
// // //  *         application/json:
// // //  *           schema:
// // //  *             type: object
// // //  *             properties:
// // //  *               email:
// // //  *                 type: string
// // //  *               oldPassword:
// // //  *                 type: string
// // //  *               newPassword:
// // //  *                 type: string
// // //  *     responses:
// // //  *       200:
// // //  *         description: Password changed
// // //  *       400:
// // //  *         description: Missing fields
// // //  *       401:
// // //  *         description: Unauthorized
// // //  */
// // // router.post('/change-password', authController.changePassword);

// // // /**
// // //  * @swagger
// // //  * /api/auth/forgot-password:
// // //  *   post:
// // //  *     summary: Reset password without old password
// // //  *     tags: [Authentication]
// // //  *     requestBody:
// // //  *       required: true
// // //  *       content:
// // //  *         application/json:
// // //  *           schema:
// // //  *             type: object
// // //  *             properties:
// // //  *               email:
// // //  *                 type: string
// // //  *               newPassword:
// // //  *                 type: string
// // //  *     responses:
// // //  *       200:
// // //  *         description: Password reset successfully
// // //  *       400:
// // //  *         description: Missing fields
// // //  *       404:
// // //  *         description: User not found
// // //  */
// // // router.post('/forgot-password', authController.forgotPassword);

// // // /**
// // //  * @swagger
// // //  * /api/auth/me:
// // //  *   get:
// // //  *     summary: Get current logged-in user details
// // //  *     tags: [Authentication]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     responses:
// // //  *       200:
// // //  *         description: Returns user object
// // //  *       401:
// // //  *         description: Missing or invalid token
// // //  */
// // // router.get('/me', verifyToken, authController.getMe);

// // // module.exports = router;
// // const express = require('express');
// // const router  = express.Router();
// // const authController = require('../controllers/authController');
// // const { verifyToken, isAdmin } = require('../middlewares/authMiddleware');

// // /**
// //  * @swagger
// //  * tags:
// //  *   - name: Authentication
// //  *     description: Login, register, and password management
// //  * components:
// //  *   securitySchemes:
// //  *     bearerAuth:
// //  *       type: http
// //  *       scheme: bearer
// //  *       bearerFormat: JWT
// //  */

// // /**
// //  * @swagger
// //  * /api/auth/login:
// //  *   post:
// //  *     summary: User login (returns token + role)
// //  *     tags: [Authentication]
// //  *     requestBody:
// //  *       required: true
// //  *       content:
// //  *         application/json:
// //  *           schema:
// //  *             type: object
// //  *             properties:
// //  *               email:
// //  *                 type: string
// //  *               password:
// //  *                 type: string
// //  *     responses:
// //  *       200:
// //  *         description: Successful login, returns { token, role, … }
// //  *       400:
// //  *         description: Missing email or password
// //  *       401:
// //  *         description: Invalid credentials
// //  */
// // router.post('/login', authController.login);

// // /**
// //  * @swagger
// //  * /api/auth/register:
// //  *   post:
// //  *     summary: Register a new user (employee or admin)
// //  *     tags: [Authentication]
// //  *     requestBody:
// //  *       required: true
// //  *       content:
// //  *         application/json:
// //  *           schema:
// //  *             type: object
// //  *             required:
// //  *               - empid
// //  *               - name
// //  *               - email
// //  *               - password
// //  *               - role
// //  *             properties:
// //  *               empid:
// //  *                 type: string
// //  *               name:
// //  *                 type: string
// //  *               email:
// //  *                 type: string
// //  *               password:
// //  *                 type: string
// //  *               role:
// //  *                 type: string
// //  *                 enum: [admin, employee]
// //  *     responses:
// //  *       200:
// //  *         description: User registered successfully
// //  *       400:
// //  *         description: Validation error or user exists
// //  */
// // router.post('/register', authController.register);

// // /**
// //  * @swagger
// //  * /api/auth/change-password:
// //  *   post:
// //  *     summary: Change user password
// //  *     tags: [Authentication]
// //  *     requestBody:
// //  *       required: true
// //  *       content:
// //  *         application/json:
// //  *           schema:
// //  *             type: object
// //  *             properties:
// //  *               email:
// //  *                 type: string
// //  *               oldPassword:
// //  *                 type: string
// //  *               newPassword:
// //  *                 type: string
// //  *     responses:
// //  *       200:
// //  *         description: Password changed
// //  *       400:
// //  *         description: Missing fields
// //  *       401:
// //  *         description: Unauthorized
// //  */
// // router.post('/change-password', authController.changePassword);

// // /**
// //  * @swagger
// //  * /api/auth/forgot-password:
// //  *   post:
// //  *     summary: Reset password without old password
// //  *     tags: [Authentication]
// //  *     requestBody:
// //  *       required: true
// //  *       content:
// //  *         application/json:
// //  *           schema:
// //  *             type: object
// //  *             properties:
// //  *               email:
// //  *                 type: string
// //  *               newPassword:
// //  *                 type: string
// //  *     responses:
// //  *       200:
// //  *         description: Password reset successfully
// //  *       400:
// //  *         description: Missing fields
// //  *       404:
// //  *         description: User not found
// //  */
// // router.post('/forgot-password', authController.forgotPassword);

// // /**
// //  * @swagger
// //  * /api/auth/me:
// //  *   get:
// //  *     summary: Get current logged-in user details
// //  *     tags: [Authentication]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     responses:
// //  *       200:
// //  *         description: Returns user object
// //  *       401:
// //  *         description: Missing or invalid token
// //  */
// // router.get('/me', verifyToken, authController.getMe);

// // /* ===================== ADMIN: enable employee logins ====================== */

// // /**
// //  * @swagger
// //  * /api/auth/admin/create-employee-login:
// //  *   post:
// //  *     summary: (Admin) Create/login-enable a single employee
// //  *     description: >
// //  *       Creates a login in the **users** collection for the given employee.
// //  *       If password is omitted, a temporary password like `EMPID@123` is set.
// //  *     tags: [Authentication]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     requestBody:
// //  *       required: true
// //  *       content:
// //  *         application/json:
// //  *           schema:
// //  *             type: object
// //  *             required: [empid]
// //  *             properties:
// //  *               empid:   { type: string, example: "EMP001" }
// //  *               email:   { type: string, example: "emp001@example.com" }
// //  *               password:{ type: string, example: "MyTemp@123" }
// //  *     responses:
// //  *       200: { description: Login enabled for employee }
// //  *       400: { description: Validation error }
// //  *       401: { description: Unauthorized }
// //  *       403: { description: Admin only }
// //  *       404: { description: Employee not found }
// //  *       409: { description: Login already exists }
// //  */
// // router.post(
// //   '/admin/create-employee-login',
// //   verifyToken,
// //   isAdmin,
// //   authController.createEmployeeLogin
// // );

// // /**
// //  * @swagger
// //  * /api/auth/admin/backfill-employee-logins:
// //  *   post:
// //  *     summary: (Admin) Create logins for all employees without a user account
// //  *     description: >
// //  *       Scans the **employees** collection and creates a login for each
// //  *       record that has an email and no corresponding user in **users**.
// //  *       A temporary password `EMPID@123` is set; the response lists created accounts.
// //  *     tags: [Authentication]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     responses:
// //  *       200: { description: Backfill complete }
// //  *       401: { description: Unauthorized }
// //  *       403: { description: Admin only }
// //  */
// // router.post(
// //   '/admin/backfill-employee-logins',
// //   verifyToken,
// //   isAdmin,
// //   authController.backfillEmployeesToUsers
// // );

// // module.exports = router;
// const express = require('express');
// const router  = express.Router();
// const authController = require('../controllers/authController');
// const { verifyToken, isAdmin } = require('../middlewares/authMiddleware');

// /**
//  * @swagger
//  * tags:
//  *   - name: Authentication
//  *     description: Login, register, and password management
//  * components:
//  *   securitySchemes:
//  *     bearerAuth:
//  *       type: http
//  *       scheme: bearer
//  *       bearerFormat: JWT
//  */

// /**
//  * @swagger
//  * /api/auth/login:
//  *   post:
//  *     summary: User login (returns token + role)
//  *     tags: [Authentication]
//  *     requestBody:
//  *       required: true
//  *       content:
//  *         application/json:
//  *           schema:
//  *             type: object
//  *             properties:
//  *               email:
//  *                 type: string
//  *               password:
//  *                 type: string
//  *     responses:
//  *       200:
//  *         description: Successful login, returns { token, role, … }
//  *       400:
//  *         description: Missing email or password
//  *       401:
//  *         description: Invalid credentials
//  */
// router.post('/login', authController.login);

// /**
//  * @swagger
//  * /api/auth/register:
//  *   post:
//  *     summary: Register a new user (employee or admin)
//  *     tags: [Authentication]
//  *     requestBody:
//  *       required: true
//  *       content:
//  *         application/json:
//  *           schema:
//  *             type: object
//  *             required:
//  *               - empid
//  *               - name
//  *               - email
//  *               - password
//  *               - role
//  *             properties:
//  *               empid:
//  *                 type: string
//  *               name:
//  *                 type: string
//  *               email:
//  *                 type: string
//  *               password:
//  *                 type: string
//  *               role:
//  *                 type: string
//  *                 enum: [admin, employee]
//  *     responses:
//  *       200:
//  *         description: User registered successfully
//  *       400:
//  *         description: Validation error or user exists
//  */
// router.post('/register', authController.register);

// /**
//  * @swagger
//  * /api/auth/change-password:
//  *   post:
//  *     summary: Change user password
//  *     tags: [Authentication]
//  *     requestBody:
//  *       required: true
//  *       content:
//  *         application/json:
//  *           schema:
//  *             type: object
//  *             properties:
//  *               email:
//  *                 type: string
//  *               oldPassword:
//  *                 type: string
//  *               newPassword:
//  *                 type: string
//  *     responses:
//  *       200:
//  *         description: Password changed
//  *       400:
//  *         description: Missing fields
//  *       401:
//  *         description: Unauthorized
//  */
// router.post('/change-password', authController.changePassword);

// /**
//  * @swagger
//  * /api/auth/forgot-password:
//  *   post:
//  *     summary: Reset password without old password
//  *     tags: [Authentication]
//  *     requestBody:
//  *       required: true
//  *       content:
//  *         application/json:
//  *           schema:
//  *             type: object
//  *             properties:
//  *               email:
//  *                 type: string
//  *               newPassword:
//  *                 type: string
//  *     responses:
//  *       200:
//  *         description: Password reset successfully
//  *       400:
//  *         description: Missing fields
//  *       404:
//  *         description: User not found
//  */
// router.post('/forgot-password', authController.forgotPassword);

// /**
//  * @swagger
//  * /api/auth/me:
//  *   get:
//  *     summary: Get current logged-in user details
//  *     tags: [Authentication]
//  *     security:
//  *       - bearerAuth: []
//  *     responses:
//  *       200:
//  *         description: Returns user object
//  *       401:
//  *         description: Missing or invalid token
//  */
// router.get('/me', verifyToken, authController.getMe);

// /* ===================== ADMIN: enable employee logins ====================== */

// /**
//  * @swagger
//  * /api/auth/admin/create-employee-login:
//  *   post:
//  *     summary: (Admin) Create/login-enable a single employee
//  *     description: >
//  *       Creates a login in the **users** collection for the given employee.
//  *       If password is omitted, a temporary password like `EMPID@123` is set.
//  *     tags: [Authentication]
//  *     security:
//  *       - bearerAuth: []
//  *     requestBody:
//  *       required: true
//  *       content:
//  *         application/json:
//  *           schema:
//  *             type: object
//  *             required: [empid]
//  *             properties:
//  *               empid:   { type: string, example: "EMP001" }
//  *               email:   { type: string, example: "emp001@example.com" }
//  *               password:{ type: string, example: "MyTemp@123" }
//  *     responses:
//  *       200: { description: Login enabled for employee }
//  *       400: { description: Validation error }
//  *       401: { description: Unauthorized }
//  *       403: { description: Admin only }
//  *       404: { description: Employee not found }
//  *       409: { description: Login already exists }
//  */
// router.post(
//   '/admin/create-employee-login',
//   verifyToken,
//   isAdmin,
//   authController.createEmployeeLogin
// );

// /**
//  * @swagger
//  * /api/auth/admin/backfill-employee-logins:
//  *   post:
//  *     summary: (Admin) Create logins for all employees without a user account
//  *     description: >
//  *       Scans the **employees** collection and creates a login for each
//  *       record that has an email and no corresponding user in **users**.
//  *       A temporary password `EMPID@123` is set; the response lists created accounts.
//  *     tags: [Authentication]
//  *     security:
//  *       - bearerAuth: []
//  *     responses:
//  *       200: { description: Backfill complete }
//  *       401: { description: Unauthorized }
//  *       403: { description: Admin only }
//  */
// router.post(
//   '/admin/backfill-employee-logins',
//   verifyToken,
//   isAdmin,
//   authController.backfillEmployeesToUsers
// );

// module.exports = router;
const express = require('express');
const router  = express.Router();
const authController = require('../controllers/authController');
const { verifyToken, isAdmin } = require('../middlewares/authMiddleware');

/**
 * @swagger
 * tags:
 *   - name: Authentication
 *     description: Login, register, and password management
 * components:
 *   securitySchemes:
 *     bearerAuth:
 *       type: http
 *       scheme: bearer
 *       bearerFormat: JWT
 */

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: User login (returns token + role)
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Successful login, returns { token, role, … }
 *       400:
 *         description: Missing email or password
 *       401:
 *         description: Invalid credentials
 */
router.post('/login', authController.login);

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new user (employee or admin)
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - empid
 *               - name
 *               - email
 *               - password
 *               - role
 *             properties:
 *               empid:
 *                 type: string
 *               name:
 *                 type: string
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *               role:
 *                 type: string
 *                 enum: [admin, employee]
 *     responses:
 *       200:
 *         description: User registered successfully
 *       400:
 *         description: Validation error or user exists
 */
router.post('/register', authController.register);

/**
 * @swagger
 * /api/auth/change-password:
 *   post:
 *     summary: Change user password
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email:
 *                 type: string
 *               oldPassword:
 *                 type: string
 *               newPassword:
 *                 type: string
 *     responses:
 *       200:
 *         description: Password changed
 *       400:
 *         description: Missing fields
 *       401:
 *         description: Unauthorized
 */
router.post('/change-password', authController.changePassword);

/**
 * @swagger
 * /api/auth/forgot-password:
 *   post:
 *     summary: Reset password without old password
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email:
 *                 type: string
 *               newPassword:
 *                 type: string
 *     responses:
 *       200:
 *         description: Password reset successfully
 *       400:
 *         description: Missing fields
 *       404:
 *         description: User not found
 */
router.post('/forgot-password', authController.forgotPassword);

/**
 * @swagger
 * /api/auth/me:
 *   get:
 *     summary: Get current logged-in user details
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Returns user object
 *       401:
 *         description: Missing or invalid token
 */
router.get('/me', verifyToken, authController.getMe);

/* ===================== ADMIN: enable employee logins ====================== */

/**
 * @swagger
 * /api/auth/admin/create-employee-login:
 *   post:
 *     summary: (Admin) Create/login-enable a single employee
 *     description: >
 *       Creates a login in the **users** collection for the given employee.
 *       If password is omitted, a temporary password like `EMPID@123` is set.
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - empid
 *             properties:
 *               empid:
 *                 type: string
 *                 example: "EMP001"
 *               email:
 *                 type: string
 *                 example: "emp001@example.com"
 *               password:
 *                 type: string
 *                 example: "MyTemp@123"
 *     responses:
 *       200:
 *         description: Login enabled for employee
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Admin only
 *       404:
 *         description: Employee not found
 *       409:
 *         description: Login already exists
 */
router.post(
  '/admin/create-employee-login',
  verifyToken,
  isAdmin,
  authController.createEmployeeLogin
);

/**
 * @swagger
 * /api/auth/admin/backfill-employee-logins:
 *   post:
 *     summary: (Admin) Create logins for all employees without a user account
 *     description: >
 *       Scans the **employees** collection and creates a login for each
 *       record that has an email and no corresponding user in **users**.
 *       A temporary password `EMPID@123` is set; the response lists created accounts.
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Backfill complete
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Admin only
 */
router.post(
  '/admin/backfill-employee-logins',
  verifyToken,
  isAdmin,
  authController.backfillEmployeesToUsers
);
router.post('/forgot-password/request-otp', authController.requestOtp);
router.post('/forgot-password/verify-otp', authController.verifyOtp);
router.post('/forgot-password/reset', authController.resetPasswordWithOtp);
module.exports = router;
