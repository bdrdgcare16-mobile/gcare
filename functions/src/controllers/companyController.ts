import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import { v4 as uuidv4 } from 'uuid';
import * as path from 'path';
import { storage } from '../config/firebase';
import { defineString } from 'firebase-functions/params';

const db = admin.firestore();
const BUCKET = defineString('APP_STORAGE_BUCKET');

interface CompanyProfile {
  id?: string;
  companyName: string;
  email: string;
  phone: string;
  website?: string;
  logoUrl?: string;
  adminName: string;
  designation: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

export const saveCompanyProfile = async (req: Request, res: Response): Promise<Response> => {
  try {
    const {
      companyName,
      email,
      phone,
      website,
      adminName,
      designation,
    } = req.body;

    // Validate required fields
    if (!companyName || !email || !phone || !adminName || !designation) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const companyData: Partial<CompanyProfile> = {
      companyName,
      email,
      phone,
      website: website || '',
      adminName,
      designation,
      updatedAt: admin.firestore.Timestamp.now(),
    };

    // Handle file upload if exists
    if (req.file) {
      const file = req.file;
      const fileName = `company/logo-${Date.now()}${path.extname(file.originalname)}`;
      const bucket = storage.bucket(BUCKET.value());
      const fileUpload = bucket.file(fileName);

      const blobStream = fileUpload.createWriteStream({
        metadata: {
          contentType: file.mimetype,
        },
      });

      await new Promise((resolve, reject) => {
        blobStream.on('error', (error) => {
          console.error('Error uploading file:', error);
          reject('Error uploading file');
        });

        blobStream.on('finish', () => {
          // Make the file public and get the public URL
          fileUpload.makePublic().then(() => {
            const publicUrl = `https://storage.googleapis.com/${BUCKET.value()}/${fileName}`;
            companyData.logoUrl = publicUrl;
            resolve(publicUrl);
          });
        });

        blobStream.end(file.buffer);
      });
    }

    // Check if company profile already exists
    const companySnapshot = await db.collection('companies').limit(1).get();
    let companyId: string;

    if (!companySnapshot.empty) {
      // Update existing company
      companyId = companySnapshot.docs[0].id;
      await db.collection('companies').doc(companyId).update(companyData);
    } else {
      // Create new company
      companyId = uuidv4();
      companyData.id = companyId;
      companyData.createdAt = admin.firestore.Timestamp.now();
      await db.collection('companies').doc(companyId).set(companyData);
    }

    // Get the updated/created company data
    const companyDoc = await db.collection('companies').doc(companyId).get();
    const company = { id: companyDoc.id, ...companyDoc.data() };

    return res.status(200).json({ 
      message: 'Company profile saved successfully',
      company 
    });
  } catch (error) {
    console.error('Error saving company profile:', error);
    return res.status(500).json({ error: 'Failed to save company profile' });
  }
};

export const getCompanyProfile = async (req: Request, res: Response): Promise<Response> => {
  try {
    const companySnapshot = await db.collection('companies').limit(1).get();
    
    if (companySnapshot.empty) {
      return res.status(404).json({ error: 'Company profile not found' });
    }

    const companyDoc = companySnapshot.docs[0];
    const company = { id: companyDoc.id, ...companyDoc.data() };

    return res.status(200).json(company);
  } catch (error) {
    console.error('Error fetching company profile:', error);
    return res.status(500).json({ error: 'Failed to fetch company profile' });
  }
};
