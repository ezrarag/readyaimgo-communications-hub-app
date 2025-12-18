/**
 * Firebase Admin initialization and utilities
 * Server-only module for Firestore operations
 */

import { initializeApp, getApps, cert, App } from 'firebase-admin/app';
import { getFirestore, Firestore } from 'firebase-admin/firestore';

let adminDb: Firestore | null = null;

/**
 * Initialize Firebase Admin SDK with singleton pattern
 */
function initializeFirebaseAdmin(): Firestore {
  if (adminDb) {
    return adminDb;
  }

  // Check if already initialized
  const existingApp = getApps()[0];
  if (existingApp) {
    adminDb = getFirestore(existingApp);
    return adminDb;
  }

  // Validate required environment variables
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (!projectId || !clientEmail || !privateKey) {
    throw new Error(
      'Missing Firebase Admin configuration. Please set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY environment variables.'
    );
  }

  // Initialize Firebase Admin
  try {
    const app: App = initializeApp({
      credential: cert({
        projectId,
        clientEmail,
        // Handle newline escaping in private key
        privateKey: privateKey.replace(/\\n/g, '\n'),
      }),
    });

    adminDb = getFirestore(app);
    return adminDb;
  } catch (error) {
    console.error('Failed to initialize Firebase Admin:', error);
    throw error;
  }
}

/**
 * Get Firestore database instance
 */
export function getAdminDb(): Firestore {
  return initializeFirebaseAdmin();
}




