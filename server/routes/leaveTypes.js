const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/leaveTypeController');
const { verifyToken, isAdmin, isUserOrAdmin } = require('../middlewares/authMiddleware');

router.post('/', verifyToken, isAdmin, ctrl.createLeaveType);
router.get('/', verifyToken, isUserOrAdmin, ctrl.listLeaveTypes);

module.exports = router;
