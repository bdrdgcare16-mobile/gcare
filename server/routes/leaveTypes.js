// // routes/leaveTypes.js
// const express = require('express');
// const router = express.Router();
// const ctrl = require('../controllers/leaveTypeController');

// const { verifyToken, isAdmin } = require('../middlewares/authMiddleware');

// /**
//  * @swagger
//  * tags: [Leave Types]
//  */

// router.post('/', verifyToken, isAdmin, ctrl.createLeaveType);
// // GET /api/leave-types  -> returns active leave_types
// router.get('/', verifyToken, isUserOrAdmin, async (req, res) => {
//   try {
//     const snap = await db.collection('leave_types').get();
//     const out = snap.docs.map(d => {
//       const x = d.data();
//       // normalize some fields
//       return {
//         id: x.id || d.id,
//         type: x.type,
//         allowedDays: x.allowedDays,
//         fromDate: x.fromDate || null,
//         toDate: x.toDate || null,
//         active: x.active !== false
//       };
//     });
//     // only active
//     res.json(out.filter(x => x.active));
//   } catch (err) {
//     console.error('leave-types list error:', err);
//     res.status(500).json({ error: 'Internal server error' });
//   }
// });

// module.exports = router;

// module.exports = router;
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/leaveTypeController');
const { verifyToken, isAdmin, isUserOrAdmin } = require('../middlewares/authMiddleware');

router.post('/', verifyToken, isAdmin, ctrl.createLeaveType);
router.get('/', verifyToken, isUserOrAdmin, ctrl.listLeaveTypes);

module.exports = router;
