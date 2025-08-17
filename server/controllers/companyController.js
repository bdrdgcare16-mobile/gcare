// const admin = require('firebase-admin');         // ✅ FIXED: Correct import
// const db = admin.firestore();                    // ✅ FIXED: Get Firestore instance

// // 🔸 Save or update company profile
// exports.saveOrUpdateCompanyProfile = async (req, res) => {
//    console.log('👉 req.file =', req.file);
//    console.log('👉 req.body =', req.body);
//   try {
//     console.log('👉 Incoming Company Data:', req.body);         // ✅ Debug log
//     console.log('📩 Logged-in User:', req.user);                // ✅ Debug log
//     console.log('🖼️ Logo File:', req.file?.filename);           // ✅ Debug log
//     console.log('📤 Uploaded file:', req.file);                 // ✅ Debug log

//     const {
//       companyName,
//       email,
//       phone,
//       website,
//       adminName,
//       designation,
//     } = req.body;

//     const adminEmail = req.user?.email; // ✅ Use email from token
//     if (!adminEmail) {
//       return res.status(400).json({ error: 'Missing admin email' });
//     }

//     // const logo = req.file ? `/uploads/${req.file.filename}` : '';
//     const logo = req.file ? `/uploads/company_logo/${req.file.filename}` : '';
//     const companyRef = db.doc(`companyProfile/${adminEmail}`); // ✅ FIXED

//     const data = {
//       companyName,
//       email,
//       phone,
//       website,
//       adminName,
//       designation,
//       updatedAt: new Date().toISOString(),
//       filled: true,
//     };

//     if (req.file) {
//       data.logo = logo;
//     }

//     await companyRef.set(data, { merge: true });

//     return res.status(200).json({ message: 'Company profile saved successfully', data });
//   } catch (error) {
//     console.error('❌ Error saving company profile:', error);
//     return res.status(500).json({ error: error.message || 'Internal server error' });
//   }
// };

// // 🔸 Get company profile
// exports.getCompanyProfile = async (req, res) => {
//   try {
//     const adminEmail = req.user?.email;
//     if (!adminEmail) {
//       return res.status(400).json({ error: 'Missing admin email' });
//     }

//     const companyRef = db.doc(`companyProfile/${adminEmail}`); // ✅ FIXED
//     const snapshot = await companyRef.get();

//     if (!snapshot.exists) {
//       return res.status(404).json({ message: 'Company profile not found' });
//     }

//     return res.status(200).json(snapshot.data());
//   } catch (error) {
//     console.error('❌ Error fetching company profile:', error);
//     return res.status(500).json({ error: 'Internal server error' });
//   }
// };

// // 🔸 Check if already filled
// exports.isCompanyProfileFilled = async (req, res) => {
//   try {
//     const adminEmail = req.user?.email;
//     if (!adminEmail) {
//       return res.status(400).json({ error: 'Missing admin email' });
//     }

//     const docRef = db.doc(`companyProfile/${adminEmail}`); // ✅ FIXED
//     const docSnap = await docRef.get();

//     const filled = docSnap.exists && docSnap.data().filled === true;

//     return res.status(200).json({ filled });
//   } catch (error) {
//     console.error('❌ Error checking company profile:', error);
//     return res.status(500).json({ error: 'Internal server error' });
//   }
// };
const admin = require('firebase-admin');
const db    = admin.firestore();

// 🔸 Save or update company profile
exports.saveOrUpdateCompanyProfile = async (req, res) => {
  console.log('👉 req.file =', req.file);
  console.log('👉 req.body =', req.body);

  try {
    const {
      companyName,
      email,
      phone,
      website,
      adminName,
      designation,
    } = req.body;

    const adminEmail = req.user?.email;
    if (!adminEmail) {
      return res.status(400).json({ error: 'Missing admin email' });
    }

    // ◀️ Change is right here:
    const logo = req.file ? `/uploads/company_logo/${req.file.filename}` : '';

    const companyRef = db.doc(`companyProfile/${adminEmail}`);
    const data = {
      companyName,
      email,
      phone,
      website,
      adminName,
      designation,
      updatedAt: new Date().toISOString(),
      filled: true,
    };
    if (req.file) {
      data.logo = logo;
    }

    await companyRef.set(data, { merge: true });
    return res.status(200).json({ message: 'Company profile saved successfully', data });
  } catch (error) {
    console.error('❌ Error saving company profile:', error);
    return res.status(500).json({ error: error.message || 'Internal server error' });
  }
};

// 🔸 Get company profile
exports.getCompanyProfile = async (req, res) => {
  try {
    const adminEmail = req.user?.email;
    if (!adminEmail) {
      return res.status(400).json({ error: 'Missing admin email' });
    }
    const companyRef = db.doc(`companyProfile/${adminEmail}`);
    const snapshot  = await companyRef.get();
    if (!snapshot.exists) {
      return res.status(404).json({ message: 'Company profile not found' });
    }
    return res.status(200).json(snapshot.data());
  } catch (error) {
    console.error('❌ Error fetching company profile:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// 🔸 Check if already filled
exports.isCompanyProfileFilled = async (req, res) => {
  try {
    const adminEmail = req.user?.email;
    if (!adminEmail) {
      return res.status(400).json({ error: 'Missing admin email' });
    }
    const docRef  = db.doc(`companyProfile/${adminEmail}`);
    const docSnap = await docRef.get();
    const filled  = docSnap.exists && docSnap.data().filled === true;
    return res.status(200).json({ filled });
  } catch (error) {
    console.error('❌ Error checking company profile:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};
