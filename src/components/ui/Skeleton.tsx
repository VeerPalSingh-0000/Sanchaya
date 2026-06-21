'use client';

import type { CSSProperties } from 'react';

/* ─── Base Skeleton ─── */
interface SkeletonProps {
  width?: string | number;
  height?: string | number;
  borderRadius?: string | number;
  className?: string;
  style?: CSSProperties;
}

export function Skeleton({
  width = '100%',
  height = 16,
  borderRadius,
  className = '',
  style,
}: SkeletonProps) {
  return (
    <div
      className={`skeleton ${className}`}
      aria-hidden="true"
      style={{
        width: typeof width === 'number' ? `${width}px` : width,
        height: typeof height === 'number' ? `${height}px` : height,
        borderRadius:
          borderRadius !== undefined
            ? typeof borderRadius === 'number'
              ? `${borderRadius}px`
              : borderRadius
            : undefined,
        ...style,
      }}
    />
  );
}

/* ─── Media Card Skeleton ─── */
interface MediaCardSkeletonProps {
  className?: string;
}

export function MediaCardSkeleton({ className = '' }: MediaCardSkeletonProps) {
  return (
    <div
      className={`glass-card ${className}`}
      aria-hidden="true"
      style={{
        overflow: 'hidden',
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      {/* Poster area */}
      <Skeleton
        width="100%"
        height={260}
        borderRadius="0"
        style={{ borderRadius: 'var(--radius-lg) var(--radius-lg) 0 0' }}
      />

      {/* Text content */}
      <div
        style={{
          padding: '14px',
          display: 'flex',
          flexDirection: 'column',
          gap: 8,
        }}
      >
        {/* Title */}
        <Skeleton width="80%" height={16} borderRadius={6} />
        {/* Subtitle */}
        <Skeleton width="55%" height={12} borderRadius={6} />
        {/* Badge row */}
        <div style={{ display: 'flex', gap: 6, marginTop: 4 }}>
          <Skeleton width={52} height={20} borderRadius={999} />
          <Skeleton width={40} height={20} borderRadius={999} />
        </div>
      </div>
    </div>
  );
}

/* ─── Media Detail Skeleton ─── */
interface MediaDetailSkeletonProps {
  className?: string;
}

export function MediaDetailSkeleton({
  className = '',
}: MediaDetailSkeletonProps) {
  return (
    <div className={className} aria-hidden="true">
      {/* Backdrop area */}
      <Skeleton width="100%" height={320} borderRadius="var(--radius-lg)" />

      <div
        style={{
          display: 'flex',
          gap: 32,
          marginTop: -80,
          padding: '0 24px',
          position: 'relative',
          zIndex: 1,
          flexWrap: 'wrap',
        }}
      >
        {/* Poster */}
        <Skeleton
          width={200}
          height={300}
          borderRadius="var(--radius-lg)"
          style={{ flexShrink: 0 }}
        />

        {/* Info column */}
        <div
          style={{
            flex: 1,
            minWidth: 240,
            display: 'flex',
            flexDirection: 'column',
            gap: 14,
            paddingTop: 90,
          }}
        >
          <Skeleton width="60%" height={28} borderRadius={8} />
          <Skeleton width="40%" height={16} borderRadius={6} />

          <div style={{ display: 'flex', gap: 8, marginTop: 4 }}>
            <Skeleton width={64} height={24} borderRadius={999} />
            <Skeleton width={48} height={24} borderRadius={999} />
            <Skeleton width={56} height={24} borderRadius={999} />
          </div>

          <Skeleton width="100%" height={14} borderRadius={6} />
          <Skeleton width="100%" height={14} borderRadius={6} />
          <Skeleton width="75%" height={14} borderRadius={6} />
        </div>
      </div>
    </div>
  );
}
