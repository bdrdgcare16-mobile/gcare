// // // // // // // controllers/taskController.js

// // // // // // const db            = require('../config/firebase');
// // // // // // const { v4: uuidv4 } = require('uuid');

// // // // // // const STATUS = ['Assigned', 'In Progress', 'Completed'];

// // // // // // // controllers/taskController.js

// // // // // // exports.createTask = async (req, res) => {
// // // // // //   // 1) Log who’s calling and with what payload
// // // // // //   console.log('▶ createTask called by', req.user);
// // // // // //   console.log('▶ body:', req.body);

// // // // // //   try {
// // // // // //     // Admin only
// // // // // //     const userId = req.user.userId;
// // // // // //     const userSnap = await db.collection('users').doc(userId).get();
// // // // // //     if (!userSnap.exists) {
// // // // // //       console.error('⚠️ User doc missing for', userId);
// // // // // //       return res.status(404).json({ error: 'User not found' });
// // // // // //     }

// // // // // //     // 2) Read the lowercase field you actually have in Firestore
// // // // // //     const { empid } = userSnap.data();
// // // // // //     console.log('▶ resolved empid:', empid);

// // // // // //     // 3) Destructure incoming body
// // // // // //     const {
// // // // // //       title,
// // // // // //       description,
// // // // // //       assignedTo = [],
// // // // // //       dueDate // ✅ Pull empid from req.body
// // // // // //     } = req.body;


// // // // // //     if (!title || !dueDate) {
// // // // // //       return res.status(400).json({ error: 'title and dueDate are required' });
// // // // // //     }

// // // // // //     // 4) Build and save
// // // // // //     const id = uuidv4();
// // // // // //     const payload = {
// // // // // //       id,
// // // // // //       userId,
// // // // // //       empid,               // ← matches your Firestore field
// // // // // //       title,
// // // // // //       description: description || '',
// // // // // //       assignedTo,
// // // // // //       dueDate: new Date(dueDate),
// // // // // //       status: 'Assigned',
// // // // // //       createdAt: new Date(),
// // // // // //       updatedAt: new Date()
// // // // // //     };

// // // // // //     await db.collection('tasks').doc(id).set(payload);
// // // // // //     return res.status(201).json(payload);

// // // // // //   } catch (err) {
// // // // // //     // 5) Print full error and return message
// // // // // //     console.error('🔥 createTask full error:', err);
// // // // // //     return res.status(500).json({ error: err.message });
// // // // // //   }
// // // // // // };


// // // // // // exports.getMyTasks = async (req, res) => {
// // // // // //   try {
// // // // // //     // Any user sees tasks assigned to them
// // // // // //     const userId = req.user.userId;
// // // // // //     const userSnap = await db.collection('users').doc(userId).get();
// // // // // //     const { empid } = userSnap.data();

// // // // // //     const snapshot = await db
// // // // // //       .collection('tasks')
// // // // // //       .where('assignedTo', 'array-contains', empid)
// // // // // //       .orderBy('dueDate', 'asc')
// // // // // //       .get();

// // // // // //     const tasks = snapshot.docs.map(doc => {
// // // // // //       const t = doc.data();
// // // // // //       t.dueDate    = t.dueDate.toDate().toISOString();
// // // // // //       t.createdAt  = t.createdAt.toDate().toISOString();
// // // // // //       t.updatedAt  = t.updatedAt.toDate().toISOString();
// // // // // //       return t;
// // // // // //     });

// // // // // //     return res.json(tasks);
// // // // // //   }catch (err) {
// // // // // //   console.error('🔥 createTask error:', err);
// // // // // //   return res.status(500).json({ error: err.message });
// // // // // // }
// // // // // // };

// // // // // // exports.getAllTasks = async (req, res) => {
// // // // // //   try {
// // // // // //     // Admin only: see every task
// // // // // //     const snapshot = await db
// // // // // //       .collection('tasks')
// // // // // //       .orderBy('createdAt', 'desc')
// // // // // //       .get();

// // // // // //     const tasks = snapshot.docs.map(doc => {
// // // // // //       const t = doc.data();
// // // // // //       t.dueDate    = t.dueDate.toDate().toISOString();
// // // // // //       t.createdAt  = t.createdAt.toDate().toISOString();
// // // // // //       t.updatedAt  = t.updatedAt.toDate().toISOString();
// // // // // //       return t;
// // // // // //     });

// // // // // //     return res.json(tasks);
// // // // // //   } catch (err) {
// // // // // //     console.error('getAllTasks error:', err);
// // // // // //     return res.status(500).json({ error: 'Internal server error' });
// // // // // //   }
// // // // // // };

// // // // // // exports.getTaskById = async (req, res) => {
// // // // // //   try {
// // // // // //     const { id } = req.params;
// // // // // //     const doc = await db.collection('tasks').doc(id).get();
// // // // // //     if (!doc.exists) {
// // // // // //       return res.status(404).json({ error: 'Task not found' });
// // // // // //     }
// // // // // //     const t = doc.data();
// // // // // //     // If user, ensure they’re assigned; if admin, allow
// // // // // //     const role = req.user.role;
// // // // // //     if (role !== 'admin') {
// // // // // //       const userSnap = await db.collection('users').doc(req.user.userId).get();
// // // // // //       const { empid } = userSnap.data();
// // // // // //       if (!t.assignedTo.includes(empid)) {
// // // // // //         return res.status(403).json({ error: 'Forbidden' });
// // // // // //       }
// // // // // //     }
// // // // // //     t.dueDate    = t.dueDate.toDate().toISOString();
// // // // // //     t.createdAt  = t.createdAt.toDate().toISOString();
// // // // // //     t.updatedAt  = t.updatedAt.toDate().toISOString();
// // // // // //     return res.json(t);
// // // // // //   } catch (err) {
// // // // // //     console.error('getTaskById error:', err);
// // // // // //     return res.status(500).json({ error: 'Internal server error' });
// // // // // //   }
// // // // // // };

// // // // // // exports.updateTask = async (req, res) => {
// // // // // //   try {
// // // // // //     const { id } = req.params;
// // // // // //     const { status, uploadUrl } = req.body;

// // // // // //     if (status && !STATUS.includes(status)) {
// // // // // //       return res.status(400).json({ error: 'Invalid status' });
// // // // // //     }

// // // // // //     const updateData = { updatedAt: new Date() };
// // // // // //     if (status)    updateData.status    = status;
// // // // // //     if (uploadUrl) updateData.uploadUrl = uploadUrl;

// // // // // //     await db.collection('tasks').doc(id).update(updateData);
// // // // // //     return res.json({ id, ...updateData });
// // // // // //   } catch (err) {
// // // // // //     console.error('updateTask error:', err);
// // // // // //     return res.status(500).json({ error: 'Internal server error' });
// // // // // //   }
// // // // // // };

// // // // // // exports.deleteTask = async (req, res) => {
// // // // // //   try {
// // // // // //     const { id } = req.params;
// // // // // //     await db.collection('tasks').doc(id).delete();
// // // // // //     return res.json({ message: 'Task deleted' });
// // // // // //   } catch (err) {
// // // // // //     console.error('deleteTask error:', err);
// // // // // //     return res.status(500).json({ error: 'Internal server error' });
// // // // // //   }
// // // // // // };

// // // // // const db = require('../config/firebase');
// // // // // const { v4: uuidv4 } = require('uuid');

// // // // // const STATUS = ['Assigned', 'In Progress', 'Completed'];

// // // // // exports.createTask = async (req, res) => {
// // // // //   console.log('▶ createTask called by', req.user);
// // // // //   console.log('▶ body:', req.body);

// // // // //   try {
// // // // //     // 1. Validate user exists
// // // // //     const userId = req.user.userId;
// // // // //     const userSnap = await db.collection('users').doc(userId).get();

// // // // //     if (!userSnap.exists) {
// // // // //       console.error('⚠️ User doc missing for', userId);
// // // // //       return res.status(404).json({ error: 'User not found in Firestore' });
// // // // //     }

// // // // //     // 2. Validate empid exists
// // // // //     const userData = userSnap.data();
// // // // //     console.log('✅ Firestore user data:', userData);

// // // // //     if (!userData?.empid) {
// // // // //       console.error('❌ empid missing for user', userId);
// // // // //       return res.status(400).json({ error: 'empid is missing in Firestore user document' });
// // // // //     }

// // // // //     const empid = userData.empid;

// // // // //     // 3. Destructure request body
// // // // //     const {
// // // // //       title,
// // // // //       description,
// // // // //       assignedTo = [],
// // // // //       dueDate
// // // // //     } = req.body;

// // // // //     if (!title || !dueDate) {
// // // // //       return res.status(400).json({ error: 'title and dueDate are required' });
// // // // //     }

// // // // //     // 4. Construct and store task
// // // // //     const id = uuidv4();
// // // // //     const payload = {
// // // // //       id,
// // // // //       userId,
// // // // //       empid,
// // // // //       title,
// // // // //       description: description || '',
// // // // //       assignedTo,
// // // // //       dueDate: new Date(dueDate),
// // // // //       status: 'Assigned',
// // // // //       createdAt: new Date(),
// // // // //       updatedAt: new Date()
// // // // //     };

// // // // //     await db.collection('tasks').doc(id).set(payload);
// // // // //     return res.status(201).json(payload);

// // // // //   } catch (err) {
// // // // //     console.error('🔥 createTask full error:', err);
// // // // //     return res.status(500).json({ error: err.message });
// // // // //   }
// // // // // };

// // // // // exports.getMyTasks = async (req, res) => {
// // // // //   try {
// // // // //     const userId = req.user.userId;
// // // // //     const userSnap = await db.collection('users').doc(userId).get();
// // // // //     const { empid } = userSnap.data();

// // // // //     const snapshot = await db
// // // // //       .collection('tasks')
// // // // //       .where('assignedTo', 'array-contains', empid)
// // // // //       .orderBy('dueDate', 'asc')
// // // // //       .get();

// // // // //     const tasks = snapshot.docs.map(doc => {
// // // // //       const t = doc.data();
// // // // //       t.dueDate    = t.dueDate.toDate().toISOString();
// // // // //       t.createdAt  = t.createdAt.toDate().toISOString();
// // // // //       t.updatedAt  = t.updatedAt.toDate().toISOString();
// // // // //       return t;
// // // // //     });

// // // // //     return res.json(tasks);
// // // // //   } catch (err) {
// // // // //     console.error('🔥 getMyTasks error:', err);
// // // // //     return res.status(500).json({ error: err.message });
// // // // //   }
// // // // // };

// // // // // exports.getAllTasks = async (req, res) => {
// // // // //   try {
// // // // //     const snapshot = await db
// // // // //       .collection('tasks')
// // // // //       .orderBy('createdAt', 'desc')
// // // // //       .get();

// // // // //     const tasks = snapshot.docs.map(doc => {
// // // // //       const t = doc.data();
// // // // //       t.dueDate    = t.dueDate.toDate().toISOString();
// // // // //       t.createdAt  = t.createdAt.toDate().toISOString();
// // // // //       t.updatedAt  = t.updatedAt.toDate().toISOString();
// // // // //       return t;
// // // // //     });

// // // // //     return res.json(tasks);
// // // // //   } catch (err) {
// // // // //     console.error('getAllTasks error:', err);
// // // // //     return res.status(500).json({ error: 'Internal server error' });
// // // // //   }
// // // // // };

// // // // // exports.getTaskById = async (req, res) => {
// // // // //   try {
// // // // //     const { id } = req.params;
// // // // //     const doc = await db.collection('tasks').doc(id).get();
// // // // //     if (!doc.exists) {
// // // // //       return res.status(404).json({ error: 'Task not found' });
// // // // //     }

// // // // //     const t = doc.data();
// // // // //     const role = req.user.role;

// // // // //     if (role !== 'admin') {
// // // // //       const userSnap = await db.collection('users').doc(req.user.userId).get();
// // // // //       const { empid } = userSnap.data();
// // // // //       if (!t.assignedTo.includes(empid)) {
// // // // //         return res.status(403).json({ error: 'Forbidden' });
// // // // //       }
// // // // //     }

// // // // //     t.dueDate    = t.dueDate.toDate().toISOString();
// // // // //     t.createdAt  = t.createdAt.toDate().toISOString();
// // // // //     t.updatedAt  = t.updatedAt.toDate().toISOString();
// // // // //     return res.json(t);
// // // // //   } catch (err) {
// // // // //     console.error('getTaskById error:', err);
// // // // //     return res.status(500).json({ error: 'Internal server error' });
// // // // //   }
// // // // // };

// // // // // exports.updateTask = async (req, res) => {
// // // // //   try {
// // // // //     const { id } = req.params;
// // // // //     const { status, uploadUrl } = req.body;

// // // // //     if (status && !STATUS.includes(status)) {
// // // // //       return res.status(400).json({ error: 'Invalid status' });
// // // // //     }

// // // // //     const updateData = { updatedAt: new Date() };
// // // // //     if (status)    updateData.status    = status;
// // // // //     if (uploadUrl) updateData.uploadUrl = uploadUrl;

// // // // //     await db.collection('tasks').doc(id).update(updateData);
// // // // //     return res.json({ id, ...updateData });
// // // // //   } catch (err) {
// // // // //     console.error('updateTask error:', err);
// // // // //     return res.status(500).json({ error: 'Internal server error' });
// // // // //   }
// // // // // };

// // // // // exports.deleteTask = async (req, res) => {
// // // // //   try {
// // // // //     const { id } = req.params;
// // // // //     await db.collection('tasks').doc(id).delete();
// // // // //     return res.json({ message: 'Task deleted' });
// // // // //   } catch (err) {
// // // // //     console.error('deleteTask error:', err);
// // // // //     return res.status(500).json({ error: 'Internal server error' });
// // // // //   }
// // // // // };



// // // // // controllers/taskController.js

// // // // const { db  }          = require('../config/firebase');
// // // // const { v4: uuidv4 } = require('uuid');

// // // // const STATUS = ['Assigned', 'In Progress', 'Completed'];

// // // // exports.createTask = async (req, res) => {
// // // //   console.log('▶ createTask called by', req.user);
// // // //   console.log('▶ body:', req.body);

// // // //   try {
// // // //     const userId = req.user.userId;
// // // //     const userSnap = await db.collection('users').doc(userId).get();
// // // //     if (!userSnap.exists) {
// // // //       console.error('⚠️ User doc missing for', userId);
// // // //       return res.status(404).json({ error: 'User not found in Firestore' });
// // // //     }

// // // //     const userData = userSnap.data();
// // // //     console.log('✅ Firestore user data:', userData);
// // // //     if (!userData.empid) {
// // // //       console.error('❌ empid missing for user', userId);
// // // //       return res.status(400).json({ error: 'empid is missing in Firestore user document' });
// // // //     }
// // // //     const empid = userData.empid;

// // // //     const { title, description, assignedTo = [], dueDate } = req.body;
// // // //     if (!title || !dueDate) {
// // // //       return res.status(400).json({ error: 'title and dueDate are required' });
// // // //     }

// // // //     const id = uuidv4();
// // // //     const payload = {
// // // //       id,
// // // //       userId,
// // // //       empid,
// // // //       title,
// // // //       description: description || '',
// // // //       assignedTo,
// // // //       dueDate: new Date(dueDate),
// // // //       status: 'Assigned',
// // // //       createdAt: new Date(),
// // // //       updatedAt: new Date()
// // // //     };

// // // //     await db.collection('tasks').doc(id).set(payload);
// // // //     return res.status(201).json(payload);

// // // //   } catch (err) {
// // // //     console.error('🔥 createTask full error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };

// // // // exports.getMyTasks = async (req, res) => {
// // // //   try {
// // // //     const userId = req.user.userId;
// // // //     const userSnap = await db.collection('users').doc(userId).get();
// // // //     const { empid } = userSnap.data();

// // // //     const snapshot = await db
// // // //       .collection('tasks')
// // // //       .where('assignedTo', 'array-contains', empid)
// // // //       .orderBy('dueDate', 'asc')
// // // //       .get();

// // // //     const tasks = snapshot.docs.map(doc => {
// // // //       const t = doc.data();
// // // //       t.dueDate   = t.dueDate.toDate().toISOString();
// // // //       t.createdAt = t.createdAt.toDate().toISOString();
// // // //       t.updatedAt = t.updatedAt.toDate().toISOString();
// // // //       return t;
// // // //     });

// // // //     return res.json(tasks);
// // // //   } catch (err) {
// // // //     console.error('🔥 getMyTasks error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };

// // // // exports.getAllTasks = async (req, res) => {
// // // //   try {
// // // //     const snapshot = await db
// // // //       .collection('tasks')
// // // //       .orderBy('createdAt', 'desc')
// // // //       .get();

// // // //     const tasks = snapshot.docs.map(doc => {
// // // //       const t = doc.data();
// // // //       t.dueDate   = t.dueDate.toDate().toISOString();
// // // //       t.createdAt = t.createdAt.toDate().toISOString();
// // // //       t.updatedAt = t.updatedAt.toDate().toISOString();
// // // //       return t;
// // // //     });

// // // //     return res.json(tasks);
// // // //   } catch (err) {
// // // //     console.error('getAllTasks error:', err);
// // // //     return res.status(500).json({ error: 'Internal server error' });
// // // //   }
// // // // };

// // // // exports.getTaskById = async (req, res) => {
// // // //   try {
// // // //     const { id } = req.params;
// // // //     const doc = await db.collection('tasks').doc(id).get();
// // // //     if (!doc.exists) {
// // // //       return res.status(404).json({ error: 'Task not found' });
// // // //     }

// // // //     const t = doc.data();
// // // //     if (req.user.role !== 'admin') {
// // // //       const userSnap = await db.collection('users').doc(req.user.userId).get();
// // // //       const { empid } = userSnap.data();
// // // //       if (!t.assignedTo.includes(empid)) {
// // // //         return res.status(403).json({ error: 'Forbidden' });
// // // //       }
// // // //     }

// // // //     t.dueDate   = t.dueDate.toDate().toISOString();
// // // //     t.createdAt = t.createdAt.toDate().toISOString();
// // // //     t.updatedAt = t.updatedAt.toDate().toISOString();
// // // //     return res.json(t);

// // // //   } catch (err) {
// // // //     console.error('getTaskById error:', err);
// // // //     return res.status(500).json({ error: 'Internal server error' });
// // // //   }
// // // // };

// // // // exports.updateTask = async (req, res) => {
// // // //   try {
// // // //     const { id } = req.params;
// // // //     const { status, uploadUrl } = req.body;

// // // //     if (status && !STATUS.includes(status)) {
// // // //       return res.status(400).json({ error: 'Invalid status' });
// // // //     }

// // // //     const updateData = { updatedAt: new Date() };
// // // //     if (status)    updateData.status    = status;
// // // //     if (uploadUrl) updateData.uploadUrl = uploadUrl;

// // // //     await db.collection('tasks').doc(id).update(updateData);
// // // //     return res.json({ id, ...updateData });

// // // //   } catch (err) {
// // // //     console.error('updateTask error:', err);
// // // //     return res.status(500).json({ error: 'Internal server error' });
// // // //   }
// // // // };

// // // // exports.deleteTask = async (req, res) => {
// // // //   try {
// // // //     const { id } = req.params;
// // // //     await db.collection('tasks').doc(id).delete();
// // // //     return res.json({ message: 'Task deleted' });

// // // //   } catch (err) {
// // // //     console.error('deleteTask error:', err);
// // // //     return res.status(500).json({ error: 'Internal server error' });
// // // //   }
// // // // };

// // // // /**
// // // //  * 7) Admin: fetch tasks by employee ID
// // // //  */
// // // // exports.getTasksByEmp = async (req, res) => {
// // // //   try {
// // // //     const { empid } = req.params;

// // // //     const snapshot = await db
// // // //       .collection('tasks')
// // // //       .where('assignedTo', 'array-contains', empid)
// // // //       .orderBy('dueDate', 'asc')  // ensure this index is built
// // // //       .get();

// // // //     const tasks = snapshot.docs.map(d => {
// // // //       const t = d.data();
// // // //       t.dueDate   = t.dueDate.toDate().toISOString();
// // // //       t.createdAt = t.createdAt.toDate().toISOString();
// // // //       t.updatedAt = t.updatedAt.toDate().toISOString();
// // // //       return t;
// // // //     });

// // // //     return res.json(tasks);
// // // //   } catch (err) {
// // // //     console.error('getTasksByEmp error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };
// // // const { db } = require('../config/firebase');           // ✅ destructure db
// // // const admin = require('firebase-admin');
// // // const { v4: uuidv4 } = require('uuid');
// // // const mime = require('mime-types');

// // // const STATUS = ['Assigned', 'In Progress', 'Completed'];

// // // function parseDataUrl(dataUrl) {
// // //   // data:<mime>;base64,<payload>
// // //   const m = /^data:([^;]+);base64,(.+)$/.exec(dataUrl || '');
// // //   if (!m) return null;
// // //   return { mime: m[1], buffer: Buffer.from(m[2], 'base64') };
// // // }

// // // async function uploadBufferToBucket(buffer, mimeType, filePath) {
// // //   const bucket = admin.storage().bucket(); // requires storageBucket set in initializeApp
// // //   const file = bucket.file(filePath);
// // //   await file.save(buffer, {
// // //     contentType: mimeType,
// // //     public: true,
// // //     metadata: { cacheControl: 'public, max-age=31536000' }
// // //   });
// // //   // Ensure public
// // //   try { await file.makePublic(); } catch (_) {}
// // //   return `https://storage.googleapis.com/${bucket.name}/${filePath}`;
// // // }

// // // /**
// // //  * 1) Admin creates a task
// // //  */
// // // exports.createTask = async (req, res) => {
// // //   try {
// // //     const userId = req.user.userId;

// // //     // Need empid for the creator (same pattern as your other controllers)
// // //     const userSnap = await db.collection('users').doc(userId).get();
// // //     if (!userSnap.exists) {
// // //       return res.status(404).json({ error: 'User not found in Firestore' });
// // //     }
// // //     const userData = userSnap.data();
// // //     if (!userData.empid) {
// // //       return res.status(400).json({ error: 'empid is missing in Firestore user document' });
// // //     }
// // //     const empid = userData.empid;

// // //     const { title, description = '', assignedTo = [], dueDate } = req.body;
// // //     if (!title || !dueDate) {
// // //       return res.status(400).json({ error: 'title and dueDate are required' });
// // //     }

// // //     const id = uuidv4();
// // //     const payload = {
// // //       id,
// // //       userId,
// // //       empid,
// // //       title,
// // //       description,
// // //       assignedTo,
// // //       dueDate: new Date(dueDate),
// // //       status: 'Assigned',
// // //       createdAt: new Date(),
// // //       updatedAt: new Date()
// // //     };

// // //     await db.collection('tasks').doc(id).set(payload);
// // //     return res.status(201).json(payload);
// // //   } catch (err) {
// // //     console.error('createTask error:', err);
// // //     return res.status(500).json({ error: err.message || 'Internal server error' });
// // //   }
// // // };

// // // /**
// // //  * 2) Authenticated user: get own tasks
// // //  */
// // // exports.getMyTasks = async (req, res) => {
// // //   try {
// // //     const userId = req.user.userId;
// // //     const userSnap = await db.collection('users').doc(userId).get();
// // //     const { empid } = userSnap.data();

// // //     const snapshot = await db
// // //       .collection('tasks')
// // //       .where('assignedTo', 'array-contains', empid)
// // //       .orderBy('dueDate', 'asc')
// // //       .get();

// // //     const tasks = snapshot.docs.map(doc => {
// // //       const t = doc.data();
// // //       t.dueDate   = t.dueDate.toDate().toISOString();
// // //       t.createdAt = t.createdAt.toDate().toISOString();
// // //       t.updatedAt = t.updatedAt.toDate().toISOString();
// // //       return t;
// // //     });

// // //     return res.json(tasks);
// // //   } catch (err) {
// // //     console.error('getMyTasks error:', err);
// // //     return res.status(500).json({ error: err.message || 'Internal server error' });
// // //   }
// // // };

// // // /**
// // //  * 3) Admin: get all tasks
// // //  */
// // // exports.getAllTasks = async (req, res) => {
// // //   try {
// // //     const snapshot = await db
// // //       .collection('tasks')
// // //       .orderBy('createdAt', 'desc')
// // //       .get();

// // //     const tasks = snapshot.docs.map(doc => {
// // //       const t = doc.data();
// // //       t.dueDate   = t.dueDate.toDate().toISOString();
// // //       t.createdAt = t.createdAt.toDate().toISOString();
// // //       t.updatedAt = t.updatedAt.toDate().toISOString();
// // //       return t;
// // //     });

// // //     return res.json(tasks);
// // //   } catch (err) {
// // //     console.error('getAllTasks error:', err);
// // //     return res.status(500).json({ error: 'Internal server error' });
// // //   }
// // // };

// // // /**
// // //  * 4) Get one task (route uses :taskId)
// // //  */
// // // exports.getTaskById = async (req, res) => {
// // //   try {
// // //     const { taskId } = req.params;               // ✅ match router
// // //     const doc = await db.collection('tasks').doc(taskId).get();
// // //     if (!doc.exists) {
// // //       return res.status(404).json({ error: 'Task not found' });
// // //     }

// // //     const t = doc.data();
// // //     if (req.user.role !== 'admin') {
// // //       const userSnap = await db.collection('users').doc(req.user.userId).get();
// // //       const { empid } = userSnap.data();
// // //       if (!t.assignedTo.includes(empid)) {
// // //         return res.status(403).json({ error: 'Forbidden' });
// // //       }
// // //     }

// // //     t.dueDate   = t.dueDate.toDate().toISOString();
// // //     t.createdAt = t.createdAt.toDate().toISOString();
// // //     t.updatedAt = t.updatedAt.toDate().toISOString();
// // //     return res.json(t);
// // //   } catch (err) {
// // //     console.error('getTaskById error:', err);
// // //     return res.status(500).json({ error: 'Internal server error' });
// // //   }
// // // };

// // // /**
// // //  * 5) Update (route uses :taskId). If uploadUrl is a data: URL, upload it to Storage and save a public URL.
// // //  */
// // // exports.updateTask = async (req, res) => {
// // //   try {
// // //     const { taskId } = req.params;               // ✅ match router
// // //     const { status, uploadUrl } = req.body;

// // //     const updateData = { updatedAt: new Date() };

// // //     if (status) {
// // //       if (!STATUS.includes(status)) {
// // //         return res.status(400).json({ error: 'Invalid status' });
// // //       }
// // //       updateData.status = status;
// // //     }

// // //     if (uploadUrl) {
// // //       if (/^data:/.test(uploadUrl)) {
// // //         const parsed = parseDataUrl(uploadUrl);
// // //         if (!parsed) {
// // //           return res.status(400).json({ error: 'Invalid data URL' });
// // //         }
// // //         const ext  = mime.extension(parsed.mime) || 'bin';
// // //         const path = `tasks/${taskId}/${Date.now()}.${ext}`;
// // //         const publicUrl = await uploadBufferToBucket(parsed.buffer, parsed.mime, path);
// // //         updateData.uploadUrl = publicUrl;        // small URL, safe for Firestore
// // //       } else {
// // //         updateData.uploadUrl = uploadUrl;        // already a URL
// // //       }
// // //     }

// // //     await db.collection('tasks').doc(taskId).update(updateData);
// // //     return res.json({ id: taskId, ...updateData });
// // //   } catch (err) {
// // //     console.error('updateTask error:', err);
// // //     return res.status(500).json({ error: 'Internal server error' });
// // //   }
// // // };

// // // /**
// // //  * 6) Delete (route uses :taskId)
// // //  */
// // // exports.deleteTask = async (req, res) => {
// // //   try {
// // //     const { taskId } = req.params;               // ✅ match router
// // //     await db.collection('tasks').doc(taskId).delete();
// // //     return res.json({ message: 'Task deleted' });
// // //   } catch (err) {
// // //     console.error('deleteTask error:', err);
// // //     return res.status(500).json({ error: 'Internal server error' });
// // //   }
// // // };

// // // /**
// // //  * 7) Admin: fetch tasks by employee ID
// // //  */
// // // exports.getTasksByEmp = async (req, res) => {
// // //   try {
// // //     const { empid } = req.params;
// // //     const snapshot = await db
// // //       .collection('tasks')
// // //       .where('assignedTo', 'array-contains', empid)
// // //       .orderBy('dueDate', 'asc')
// // //       .get();

// // //     const tasks = snapshot.docs.map(d => {
// // //       const t = d.data();
// // //       t.dueDate   = t.dueDate.toDate().toISOString();
// // //       t.createdAt = t.createdAt.toDate().toISOString();
// // //       t.updatedAt = t.updatedAt.toDate().toISOString();
// // //       return t;
// // //     });

// // //     return res.json(tasks);
// // //   } catch (err) {
// // //     console.error('getTasksByEmp error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };

// // // controllers/tasks.controller.js
// // const { db } = require('../config/firebase'); // <- project path
// // const { uploadBufferToStorage, buildTaskPath } = require('../utils/storage');

// // /** Compose a Firestore task document */
// // function makeTaskDoc({
// //   id,
// //   title,
// //   description,
// //   dueDate,
// //   kind,
// //   fileMeta,
// //   user,
// //   audience,
// //   assignedTo,
// // }) {
// //   const nowIso = new Date().toISOString();
// //   return {
// //     id,
// //     title: title?.trim() || fileMeta?.name || 'Task',
// //     description: (description || '').trim(),
// //     audience,                                    // "all" | "employee"
// //     assignedTo: audience === 'employee' ? (assignedTo || '').trim() : null,
// //     dueDate: dueDate || null,                    // "yyyy-MM-dd" or null
// //     kind: kind || 'Task',                        // e.g. "Task" | "DailyUpdate"
// //     file: fileMeta,                              // { name, size, contentType, url }
// //     status: 'assigned',
// //     createdBy: user?.uid || 'admin',
// //     createdAt: nowIso,
// //     updatedAt: nowIso,
// //   };
// // }

// // /** 🔊 Admin: upload one file → visible to ALL employees */
// // exports.createBroadcastTask = async (req, res) => {
// //   try {
// //     if (!req.file) return res.status(400).json({ error: 'file is required' });

// //     const { title = '', description = '', dueDate = null, kind = 'Task' } = req.body;

// //     const docRef = db.collection('tasks').doc();
// //     const destPath = buildTaskPath(docRef.id, req.file.originalname);
// //     const url = await uploadBufferToStorage(req.file, destPath);

// //     const fileMeta = {
// //       name: req.file.originalname,
// //       size: req.file.size,
// //       contentType: req.file.mimetype,
// //       url,
// //     };

// //     const data = makeTaskDoc({
// //       id: docRef.id,
// //       title,
// //       description,
// //       dueDate,
// //       kind,
// //       fileMeta,
// //       user: req.user,
// //       audience: 'all',
// //     });

// //     await docRef.set(data);
// //     return res.status(201).json(data);
// //   } catch (e) {
// //     return res
// //       .status(500)
// //       .json({ error: 'Failed to upload broadcast task', details: e.message });
// //   }
// // };

// // /** 🎯 Admin: upload one file → to ONE employee (empid) */
// // exports.createSingleTask = async (req, res) => {
// //   try {
// //     const {
// //       assignedTo = '',
// //       title = '',
// //       description = '',
// //       dueDate = null,
// //       kind = 'Task',
// //     } = req.body;

// //     if (!assignedTo.trim()) {
// //       return res.status(400).json({ error: 'assignedTo (empid) is required' });
// //     }
// //     if (!req.file) return res.status(400).json({ error: 'file is required' });

// //     const docRef = db.collection('tasks').doc();
// //     const destPath = buildTaskPath(docRef.id, req.file.originalname);
// //     const url = await uploadBufferToStorage(req.file, destPath);

// //     const fileMeta = {
// //       name: req.file.originalname,
// //       size: req.file.size,
// //       contentType: req.file.mimetype,
// //       url,
// //     };

// //     const data = makeTaskDoc({
// //       id: docRef.id,
// //       title,
// //       description,
// //       dueDate,
// //       kind,
// //       fileMeta,
// //       user: req.user,
// //       audience: 'employee',
// //       assignedTo,
// //     });

// //     await docRef.set(data);
// //     return res.status(201).json(data);
// //   } catch (e) {
// //     return res.status(500).json({ error: 'Failed to upload task', details: e.message });
// //   }
// // };

// // /** 📜 List tasks
// //  * Admin:
// //  *   GET /api/tasks?audience=all       -> only broadcasts
// //  *   GET /api/tasks?audience=employee  -> only employee-targeted tasks
// //  * Employee app:
// //  *   GET /api/tasks?empid=EMP001       -> broadcasts + personal
// //  */
// // exports.listTasks = async (req, res) => {
// //   try {
// //     const { empid, audience } = req.query;

// //     const sortByCreated = (arr) =>
// //       arr.sort((a, b) => (b?.createdAt || '').localeCompare(a?.createdAt || ''));

// //     if (audience === 'all' || audience === 'employee') {
// //       const snap = await db.collection('tasks')
// //         .where('audience', '==', audience)
// //         .get(); // no orderBy
// //       return res.json(sortByCreated(snap.docs.map(d => d.data())));
// //     }

// //     const pid = empid || req.user?.empid;
// //     if (!pid) return res.status(400).json({ error: 'empid is required' });

// //     const [broadcastSnap, personalSnap] = await Promise.all([
// //       db.collection('tasks').where('audience', '==', 'all').get(),
// //       db.collection('tasks')
// //         .where('audience', '==', 'employee')
// //         .where('assignedTo', '==', pid)
// //         .get(),
// //     ]);

// //     const list = [
// //       ...broadcastSnap.docs.map(d => d.data()),
// //       ...personalSnap.docs.map(d => d.data()),
// //     ];
// //     return res.json(sortByCreated(list));
// //   } catch (e) {
// //     return res.status(500).json({ error: 'Failed to fetch tasks', details: e.message });
// //   }
// // };
// // module.exports = {
// //   createBroadcastTask,
// //   createSingleTask,
// //   listTasks,
// //   getTask,
// // }
// // controllers/taskcontroller.js
// const { db } = require('../config/firebase');
// const { uploadBufferToStorage, buildTaskPath } = require('../utils/storage');

// // Compose a Firestore Task document
// function makeTaskDoc({
//   id,
//   title,
//   description,
//   dueDate,
//   kind,
//   fileMeta,
//   user,
//   audience,
//   assignedTo,
// }) {
//   const nowIso = new Date().toISOString();
//   return {
//     id,
//     title: title?.trim() || fileMeta?.name || 'Task',
//     description: (description || '').trim(),
//     audience,                                    // "all" | "employee"
//     assignedTo: audience === 'employee' ? (assignedTo || '').trim() : null,
//     dueDate: dueDate || null,                    // "yyyy-MM-dd" or null
//     kind: kind || 'Task',                        // e.g. "Task" | "DailyUpdate"
//     file: fileMeta,                              // { name, size, contentType, url }
//     status: 'assigned',
//     createdBy: user?.uid || 'admin',
//     createdAt: nowIso,
//     updatedAt: nowIso,
//   };
// }

// /** 🔊 Admin: upload one file → visible to ALL employees */
// async function createBroadcastTask(req, res) {
//   try {
//     if (!req.file) return res.status(400).json({ error: 'file is required' });

//     const { title = '', description = '', dueDate = null, kind = 'Task' } = req.body;

//     const docRef = db.collection('tasks').doc();
//     const destPath = buildTaskPath(docRef.id, req.file.originalname);
//     const url = await uploadBufferToStorage(req.file, destPath);

//     const fileMeta = {
//       name: req.file.originalname,
//       size: req.file.size,
//       contentType: req.file.mimetype,
//       url,
//     };

//     const data = makeTaskDoc({
//       id: docRef.id,
//       title,
//       description,
//       dueDate,
//       kind,
//       fileMeta,
//       user: req.user,
//       audience: 'all',
//     });

//     await docRef.set(data);
//     return res.status(201).json(data);
//   } catch (e) {
//     return res
//       .status(500)
//       .json({ error: 'Failed to upload broadcast task', details: e.message });
//   }
// }

// /** 🎯 Admin: upload one file → to ONE employee (empid) */
// async function createSingleTask(req, res) {
//   try {
//     const {
//       assignedTo = '',
//       title = '',
//       description = '',
//       dueDate = null,
//       kind = 'Task',
//     } = req.body;

//     if (!assignedTo.trim()) {
//       return res.status(400).json({ error: 'assignedTo (empid) is required' });
//     }
//     if (!req.file) return res.status(400).json({ error: 'file is required' });

//     const docRef = db.collection('tasks').doc();
//     const destPath = buildTaskPath(docRef.id, req.file.originalname);
//     const url = await uploadBufferToStorage(req.file, destPath);

//     const fileMeta = {
//       name: req.file.originalname,
//       size: req.file.size,
//       contentType: req.file.mimetype,
//       url,
//     };

//     const data = makeTaskDoc({
//       id: docRef.id,
//       title,
//       description,
//       dueDate,
//       kind,
//       fileMeta,
//       user: req.user,
//       audience: 'employee',
//       assignedTo,
//     });

//     await docRef.set(data);
//     return res.status(201).json(data);
//   } catch (e) {
//     return res.status(500).json({ error: 'Failed to upload task', details: e.message });
//   }
// }

// /** 📜 List tasks
//  * Admin:
//  *   GET /api/tasks?audience=all       -> only broadcasts
//  *   GET /api/tasks?audience=employee  -> only employee-targeted tasks
//  * Employee:
//  *   GET /api/tasks?empid=EMP001       -> broadcasts + personal
//  */
// async function listTasks(req, res) {
//   try {
//     const { empid, audience } = req.query;

//     // Admin filtered by audience
//     if (audience === 'all' || audience === 'employee') {
//       const snap = await db
//         .collection('tasks')
//         .where('audience', '==', audience)
//         .orderBy('createdAt', 'desc')
//         .get();
//       return res.json(snap.docs.map((d) => d.data()));
//     }

//     // Employee view (union of broadcasts and personal)
//     const pid = empid || req.user?.empid;
//     if (!pid) return res.status(400).json({ error: 'empid is required' });

//     const [broadcastSnap, personalSnap] = await Promise.all([
//       db
//         .collection('tasks')
//         .where('audience', '==', 'all')
//         .orderBy('createdAt', 'desc')
//         .get(),
//       db
//         .collection('tasks')
//         .where('audience', '==', 'employee')
//         .where('assignedTo', '==', pid)
//         .orderBy('createdAt', 'desc')
//         .get(),
//     ]);

//     const list = [
//       ...broadcastSnap.docs.map((d) => d.data()),
//       ...personalSnap.docs.map((d) => d.data()),
//     ].sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));

//     return res.json(list);
//   } catch (e) {
//     return res.status(500).json({ error: 'Failed to fetch tasks', details: e.message });
//   }
// }

// /** Get a single task by id */
// async function getTask(req, res) {
//   try {
//     const doc = await db.collection('tasks').doc(req.params.id).get();
//     if (!doc.exists) return res.status(404).json({ error: 'Not found' });
//     res.json(doc.data());
//   } catch (e) {
//     res.status(500).json({ error: 'Failed to fetch task', details: e.message });
//   }
// }

// module.exports = {
//   createBroadcastTask,
//   createSingleTask,
//   listTasks,
//   getTask,
// };
// controllers/taskcontroller.js
const { db } = require('../config/firebase');
const { uploadBufferToStorage, buildTaskPath } = require('../utils/storage');

// Compose a Firestore Task document
function makeTaskDoc({
  id,
  title,
  description,
  dueDate,
  kind,
  fileMeta,
  user,
  audience,
  assignedTo,
}) {
  const nowIso = new Date().toISOString();
  return {
    id,
    title: title?.trim() || fileMeta?.name || 'Task',
    description: (description || '').trim(),
    audience,                                    // "all" | "employee"
    assignedTo: audience === 'employee' ? (assignedTo || '').trim() : null,
    dueDate: dueDate || null,                    // "yyyy-MM-dd" or null
    kind: kind || 'Task',                        // e.g. "Task" | "DailyUpdate"
    file: fileMeta,                              // { name, size, contentType, url }
    status: 'assigned',
    createdBy: user?.uid || 'admin',
    createdAt: nowIso,
    updatedAt: nowIso,
  };
}

/** 🔊 Admin: upload one file → visible to ALL employees */
async function createBroadcastTask(req, res) {
  try {
    if (!req.file) return res.status(400).json({ error: 'file is required' });

    const { title = '', description = '', dueDate = null, kind = 'Task' } = req.body;

    const docRef = db.collection('tasks').doc();
    const destPath = buildTaskPath(docRef.id, req.file.originalname);
    const url = await uploadBufferToStorage(req.file, destPath);

    const fileMeta = {
      name: req.file.originalname,
      size: req.file.size,
      contentType: req.file.mimetype,
      url,
    };

    const data = makeTaskDoc({
      id: docRef.id,
      title,
      description,
      dueDate,
      kind,
      fileMeta,
      user: req.user,
      audience: 'all',
    });

    await docRef.set(data);
    return res.status(201).json(data);
  } catch (e) {
    return res
      .status(500)
      .json({ error: 'Failed to upload broadcast task', details: e.message });
  }
}

/** 🎯 (Optional) Admin: upload one file → to ONE employee (empid) */
async function createSingleTask(req, res) {
  try {
    const {
      assignedTo = '',
      title = '',
      description = '',
      dueDate = null,
      kind = 'Task',
    } = req.body;

    if (!assignedTo.trim()) {
      return res.status(400).json({ error: 'assignedTo (empid) is required' });
    }
    if (!req.file) return res.status(400).json({ error: 'file is required' });

    const docRef = db.collection('tasks').doc();
    const destPath = buildTaskPath(docRef.id, req.file.originalname);
    const url = await uploadBufferToStorage(req.file, destPath);

    const fileMeta = {
      name: req.file.originalname,
      size: req.file.size,
      contentType: req.file.mimetype,
      url,
    };

    const data = makeTaskDoc({
      id: docRef.id,
      title,
      description,
      dueDate,
      kind,
      fileMeta,
      user: req.user,
      audience: 'employee',
      assignedTo,
    });

    await docRef.set(data);
    return res.status(201).json(data);
  } catch (e) {
    return res.status(500).json({ error: 'Failed to upload task', details: e.message });
  }
}

/**
 * 📜 List tasks
 * ✔️ Simplified: always return broadcasts only (audience='all')
 *    -> no composite index required
 */
async function listTasks(req, res) {
  try {
    const snap = await db
      .collection('tasks')
      .where('audience', '==', 'all')
      .orderBy('createdAt', 'desc')
      .get();

    return res.json(snap.docs.map((d) => d.data()));
  } catch (e) {
    return res.status(500).json({ error: 'Failed to fetch tasks', details: e.message });
  }
}

/** Get a single task by id */
async function getTask(req, res) {
  try {
    const doc = await db.collection('tasks').doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Not found' });
    res.json(doc.data());
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch task', details: e.message });
  }
}

module.exports = {
  createBroadcastTask,
  createSingleTask, // kept exported (even if you don't use it)
  listTasks,
  getTask,
};
