// // exports.createFeedback = async (req, res) => {
// //   try {
// //     const db = req.app.locals.db;
// //     const message = req.body.message;
// //     const userId = req.headers['x-user-id']; // sent from frontend

// //     if (!userId || !message)
// //       return res.status(400).json({ error: 'Missing userId or message' });

// //     // 🔍 Fetch user info from users collection
// //     const userSnap = await db.collection('users').doc(userId).get();
// //     if (!userSnap.exists) {
// //       return res.status(404).json({ error: 'User not found in users DB' });
// //     }

// //     const user = userSnap.data();

// //     const feedback = {
// //       empid: user.empid || '',
// //       name: user.name || '',
// //       message,
// //       date: new Date(),
// //       response: '',
// //       visibility: ['admin']
// //     };

// //     const docRef = await db.collection('feedbacks').add(feedback);
// //     res.status(201).json({ id: docRef.id });
// //   } catch (err) {
// //     res.status(500).json({ error: err.message });
// //   }
// // };

// // exports.getAllFeedback = async (req, res) => {
// //   try {
// //     const db = req.app.locals.db;
// //     const snapshot = await db.collection('feedbacks').orderBy('date', 'desc').get();

// //     const feedbackList = snapshot.docs.map(doc => {
// //       const data = doc.data();

// //       return {
// //         id: doc.id,
// //         empid: data.empid,
// //         name: data.name,
// //         message: data.message,
// //         response: data.response,
// //         visibility: data.visibility,
// //         date: data.date.toDate().toISOString() // ✅ Converts to readable string
// //       };
// //     });

// //     res.json(feedbackList);
// //   } catch (err) {
// //     res.status(500).json({ error: err.message });
// //   }
// // };
// exports.createFeedback = async (req, res) => {
//   try {
//     const db = req.app.locals.db;
//     const message = (req.body?.message || '').toString().trim();
//     const userId = (req.headers['x-user-id'] || '').toString().trim();

//     if (!message) {
//       return res.status(400).json({ error: 'Missing message' });
//     }

//     let empid = '';
//     let name  = '';

//     if (userId) {
//       // Normal path: look up user by Firestore document id
//       const userSnap = await db.collection('users').doc(userId).get();
//       if (!userSnap.exists) {
//         return res.status(404).json({ error: 'User not found in users DB' });
//       }
//       const user = userSnap.data() || {};
//       empid = (user.empid || '').toString();
//       name  = (user.name  || '').toString();
//     } else {
//       // Fallback path: accept metadata directly
//       empid = (req.headers['x-empid'] || req.body.empid || '').toString().trim();
//       name  = (req.headers['x-name']  || req.body.name  || '').toString().trim();

//       if (!empid && !name) {
//         return res.status(400).json({
//           error:
//             'Missing user id and emp meta. Provide x-user-id OR x-empid/x-name (or empid/name in body).',
//         });
//       }
//     }

//     const feedback = {
//       empid,
//       name,
//       message,
//       date: new Date(),
//       response: '',
//       visibility: ['admin'],
//     };

//     const docRef = await db.collection('feedbacks').add(feedback);
//     return res.status(201).json({ id: docRef.id });
//   } catch (err) {
//     console.error('[feedback:create] error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };

// exports.getAllFeedback = async (req, res) => {
//   try {
//     const db = req.app.locals.db;
//     const snapshot = await db.collection('feedbacks').orderBy('date', 'desc').get();

//     const feedbackList = snapshot.docs.map((doc) => {
//       const data = doc.data() || {};
//       return {
//         id: doc.id,
//         empid: data.empid || '',
//         name: data.name || '',
//         message: data.message || '',
//         response: data.response || '',
//         visibility: data.visibility || ['admin'],
//         date:
//           data.date && typeof data.date.toDate === 'function'
//             ? data.date.toDate().toISOString()
//             : new Date().toISOString(),
//       };
//     });

//     return res.json(feedbackList);
//   } catch (err) {
//     console.error('[feedback:getAll] error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };
exports.createFeedback = async (req, res) => {
  try {
    const db = req.app.locals.db;
    const message = (req.body?.message || '').toString().trim();
    const headerUserId = (req.headers['x-user-id'] || '').toString().trim();
    const headerEmpId  = (req.headers['x-empid']   || '').toString().trim();
    const headerName   = (req.headers['x-name']    || '').toString().trim();

    if (!message) {
      return res.status(400).json({ error: 'Missing message' });
    }

    let empid = '';
    let name  = '';

    if (headerUserId) {
      // Look up users/<id> to resolve empid + name
      const snap = await db.collection('users').doc(headerUserId).get();
      if (!snap.exists) {
        return res.status(404).json({ error: 'User not found in users DB' });
      }
      const u = snap.data() || {};
      empid = (u.empid || '').toString();
      name  = (u.name  || '').toString();
    } else {
      // Accept direct emp meta via headers (or body fallbacks if you ever need)
      empid = headerEmpId || (req.body?.empid || '').toString();
      name  = headerName  || (req.body?.name  || '').toString();
    }

    if (!empid || !name) {
      return res.status(400).json({
        error: 'Missing user id and emp meta. Provide x-user-id OR x-empid/x-name (or empid/name in body).',
      });
    }

    const doc = {
      empid,
      name,
      message,
      date: new Date(),
      response: '',
      visibility: ['admin'],
    };

    const ref = await db.collection('feedbacks').add(doc);
    return res.status(201).json({ id: ref.id });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.getAllFeedback = async (req, res) => {
  try {
    const db = req.app.locals.db;
    const snap = await db.collection('feedbacks').orderBy('date', 'desc').get();

    const data = snap.docs.map(d => {
      const x = d.data();
      // date may be Firestore Timestamp or JS Date
      let iso = '';
      if (x.date && typeof x.date.toDate === 'function') iso = x.date.toDate().toISOString();
      else if (x.date instanceof Date) iso = x.date.toISOString();

      return {
        id: d.id,
        empid: x.empid || '',
        name: x.name || '',
        message: x.message || '',
        response: x.response || '',
        visibility: Array.isArray(x.visibility) ? x.visibility : [],
        date: iso,
      };
    });

    return res.json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

