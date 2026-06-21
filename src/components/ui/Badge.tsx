'use client';

import { type ReactNode } from 'react';

type BadgeVariant = 'genre' | 'status' | 'rating' | 'type';

interface BadgeProps {
  variant?: BadgeVariant;
  /** For status variant, choose the specific status for the right color */
  status?: 'watching' | 'completed' | 'plan-to-watch' | 'dropped' | 'on-hold';
  children: ReactNode;
  className?: string;
}

const variantClassMap: Record<BadgeVariant, string> = {
  genre: 'badge-genre',
  status: 'badge-status-watching', // default, overridden by status prop
  rating: 'badge-rating',
  type: 'badge-type',
};

const statusClassMap: Record<NonNullable<BadgeProps['status']>, string> = {
  watching: 'badge-status-watching',
  completed: 'badge-status-completed',
  'plan-to-watch': 'badge-status-plan-to-watch',
  dropped: 'badge-status-dropped',
  'on-hold': 'badge-status-on-hold',
};

export default function Badge({
  variant = 'genre',
  status,
  children,
  className = '',
}: BadgeProps) {
  let colorClass: string;

  if (variant === 'status' && status) {
    colorClass = statusClassMap[status];
  } else {
    colorClass = variantClassMap[variant];
  }

  const classes = ['badge', colorClass, className].filter(Boolean).join(' ');

  return <span className={classes}>{children}</span>;
}
