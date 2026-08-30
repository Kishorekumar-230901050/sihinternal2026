import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  sendPasswordResetEmail,
  updateProfile,
  User,
  UserCredential,
} from 'firebase/auth';
import { auth } from './firebase';

/**
 * Register a new user with email and password
 */
export const registerUser = async (
  email: string,
  password: string,
  displayName?: string
): Promise<UserCredential> => {
  const userCredential = await createUserWithEmailAndPassword(auth, email, password);
  
  // Update profile with display name if provided
  if (displayName && userCredential.user) {
    await updateProfile(userCredential.user, { displayName });
  }
  
  return userCredential;
};

/**
 * Login user with email and password
 */
export const loginUser = async (
  email: string,
  password: string
): Promise<UserCredential> => {
  return signInWithEmailAndPassword(auth, email, password);
};

/**
 * Logout the current user
 */
export const logoutUser = async (): Promise<void> => {
  return signOut(auth);
};

/**
 * Send password reset email
 */
export const resetPassword = async (email: string): Promise<void> => {
  return sendPasswordResetEmail(auth, email);
};

/**
 * Update user profile information
 */
export const updateUserProfile = async (
  user: User,
  updates: { displayName?: string; photoURL?: string }
): Promise<void> => {
  return updateProfile(user, updates);
};

/**
 * Get the current authenticated user
 */
export const getCurrentUser = (): User | null => {
  return auth.currentUser;
};

/**
 * Subscribe to authentication state changes
 */
export const onAuthStateChanged = (callback: (user: User | null) => void): (() => void) => {
  return auth.onAuthStateChanged(callback);
};

/**
 * Get ID token for API calls
 */
export const getIdToken = async (forceRefresh: boolean = false): Promise<string> => {
  const user = auth.currentUser;
  if (!user) {
    throw new Error('No user authenticated');
  }
  return user.getIdToken(forceRefresh);
};
