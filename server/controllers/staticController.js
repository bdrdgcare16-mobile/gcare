const admin = require('firebase-admin');
const db = admin.firestore();

// 🔹 Get Terms and Conditions
exports.getTerms = async (req, res) => {
  try {
    const docRef = db.doc('staticContent/terms&conditions');
    const snapshot = await docRef.get();

    if (!snapshot.exists) {
      return res.status(404).json({ message: 'Terms not found' });
    }

    return res.status(200).json({ content: snapshot.data().content });
  } catch (error) {
    console.error('Error fetching terms:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// 🔹 Get Privacy Policy
exports.getPrivacy = async (req, res) => {
  try {
    const docRef = db.doc('staticContent/privacypolicy');
    const snapshot = await docRef.get();

    if (!snapshot.exists) {
      return res.status(404).json({ message: 'Privacy policy not found' });
    }

    return res.status(200).json({ content: snapshot.data().content });
  } catch (error) {
    console.error('Error fetching privacy policy:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};
