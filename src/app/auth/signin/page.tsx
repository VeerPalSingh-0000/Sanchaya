import { redirect } from 'next/navigation';
import { auth } from '@/lib/auth';
import SignInClient from './SignInClient';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Sign In | Sanchaya',
  description: 'Sign in to Sanchaya to track your favorite movies, series, and anime.',
};

export default async function SignInPage() {
  const session = await auth();

  if (session) {
    redirect('/');
  }

  return <SignInClient />;
}
