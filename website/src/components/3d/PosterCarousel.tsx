'use client';

import * as THREE from 'three';
import { useRef, useState, Suspense } from 'react';
import { Canvas, useFrame, useThree } from '@react-three/fiber';
import { Image as DreiImage, ContactShadows, Stars } from '@react-three/drei';
import { useRouter } from 'next/navigation';
import type { Media } from '@/types/media';

interface PosterCarouselProps {
  items: Media[];
}

function CarouselItems({ items, targetRotation }: { items: Media[], targetRotation: React.MutableRefObject<number> }) {
  const group = useRef<THREE.Group>(null);
  const isDragging = useRef(false);
  
  // Calculate dynamic radius to prevent overlap
  const itemWidth = 2.4;
  const gap = 0.2;
  const circumference = items.length * (itemWidth + gap);
  const radius = Math.max(4, circumference / (Math.PI * 2));

  useFrame((state) => {
    if (group.current) {
      // Smoothly interpolate current rotation to the target rotation set by dragging
      group.current.rotation.y = THREE.MathUtils.lerp(
        group.current.rotation.y,
        targetRotation.current,
        0.1
      );
      
      // Gentle floating animation for the whole group
      group.current.position.y = Math.sin(state.clock.elapsedTime * 0.5) * 0.2;
    }
  });

  return (
    <group ref={group} position={[0, 0, -radius]}>
      {items.map((item, i) => (
        <CarouselItem 
          key={item.id || item.externalId} 
          media={item} 
          index={i} 
          total={items.length}
          radius={radius}
          isDragging={isDragging.current}
        />
      ))}
    </group>
  );
}

function CarouselItem({ media, index, total, radius, isDragging }: any) {
  const meshRef = useRef<THREE.Mesh>(null);
  const router = useRouter();
  const [hovered, setHovered] = useState(false);
  const { viewport } = useThree();

  const angle = (index / total) * Math.PI * 2;
  const x = Math.sin(angle) * radius;
  const z = Math.cos(angle) * radius;

  const isMobile = viewport.width < 5;
  const cardScale = isMobile ? 1.0 : 1.4;
  const width = 1.8 * cardScale;
  const height = 2.7 * cardScale;

  const imageUrl = media.posterUrl || media.posterPath 
    ? (media.posterUrl || `https://image.tmdb.org/t/p/w500${media.posterPath}`)
    : null;

  useFrame((state) => {
    if (meshRef.current) {
      const targetScale = hovered ? 1.08 : 1;
      meshRef.current.scale.lerp(new THREE.Vector3(targetScale, targetScale, targetScale), 0.1);
      
      const time = state.clock.getElapsedTime();
      meshRef.current.position.y = Math.sin(time * 2 + index) * 0.05;
      
      const targetRotationY = angle;
      meshRef.current.rotation.y = targetRotationY;
      meshRef.current.rotation.x = THREE.MathUtils.lerp(meshRef.current.rotation.x, hovered ? -0.05 : 0, 0.1);
    }
  });

  return (
    <group position={[x, 0, z]}>
      <mesh
        ref={meshRef}
        onPointerOver={(e) => { e.stopPropagation(); setHovered(true); document.body.style.cursor = 'pointer'; }}
        onPointerOut={(e) => { e.stopPropagation(); setHovered(false); document.body.style.cursor = 'grab'; }}
        onClick={(e) => {
          e.stopPropagation();
          if (!isDragging) {
            router.push(`/media/${media.type || (media as any).mediaType || 'movie'}/${media.externalId || media.id}`);
          }
        }}
      >
        {imageUrl ? (
          <DreiImage
            url={imageUrl}
            transparent
            scale={[width, height]}
          />
        ) : (
          <mesh>
            <planeGeometry args={[width, height]} />
            <meshBasicMaterial color="#111827" />
          </mesh>
        )}
      </mesh>
    </group>
  );
}

export default function PosterCarousel({ items }: PosterCarouselProps) {
  const targetRotation = useRef(0);
  const isDragging = useRef(false);
  const previousClientX = useRef(0);

  if (!items || items.length === 0) return null;

  const handlePointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    isDragging.current = true;
    previousClientX.current = e.clientX;
    (e.currentTarget as HTMLElement).style.cursor = 'grabbing';
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!isDragging.current) return;
    const deltaX = e.clientX - previousClientX.current;
    // Update target rotation (drag left rotates right)
    targetRotation.current += deltaX * 0.005;
    previousClientX.current = e.clientX;
  };

  const handlePointerUp = (e: React.PointerEvent<HTMLDivElement>) => {
    isDragging.current = false;
    (e.currentTarget as HTMLElement).style.cursor = 'grab';
  };
  
  return (
    <div 
      style={{ width: '100%', height: '55vh', minHeight: '400px', cursor: 'grab', position: 'relative', marginTop: '-1rem', marginBottom: '2rem', touchAction: 'none' }} 
      onPointerDown={handlePointerDown} 
      onPointerMove={handlePointerMove} 
      onPointerUp={handlePointerUp} 
      onPointerLeave={handlePointerUp}
    >
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-background z-10 pointer-events-none" style={{ bottom: '-20%' }} />
      <Canvas camera={{ position: [0, 0, 7.5], fov: 45 }}>
        <fog attach="fog" args={['#09090b', 8, 30]} />
        <ambientLight intensity={0.5} />
        <spotLight position={[0, 10, 0]} intensity={1} penumbra={1} />
        <Stars radius={100} depth={50} count={3000} factor={4} saturation={0} fade speed={1} />
        <Suspense fallback={null}>
          <CarouselItems items={items} targetRotation={targetRotation} />
          <ContactShadows resolution={1024} scale={50} blur={2} opacity={0.5} far={10} color="#000000" position={[0, -3.5, 0]} />
        </Suspense>
      </Canvas>
    </div>
  );
}
