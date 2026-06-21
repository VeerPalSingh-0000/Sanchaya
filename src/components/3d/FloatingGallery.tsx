'use client';

import * as THREE from 'three';
import { useRef, useState, useEffect, useMemo, Suspense } from 'react';
import { Canvas, useFrame, useThree } from '@react-three/fiber';
import { Image as DreiImage, Environment, ContactShadows } from '@react-three/drei';
import { useRouter } from 'next/navigation';
import type { WatchlistItem } from '@/types/media';

interface FloatingGalleryProps {
  items: WatchlistItem[];
}

function GalleryItems({ items }: { items: WatchlistItem[] }) {
  const { viewport } = useThree();
  const groupRef = useRef<THREE.Group>(null);
  
  // Arrange items in a neat curved wall (cylinder section)
  const radius = Math.max(8, items.length * 0.8);
  const angleStep = (Math.PI * 0.8) / Math.max(1, items.length - 1); // Spread across 80% of a half-circle
  const startAngle = -(Math.PI * 0.8) / 2;

  useFrame((state) => {
    if (groupRef.current) {
      // Gentle floating animation for the entire wall
      groupRef.current.position.y = Math.sin(state.clock.elapsedTime * 0.5) * 0.2;
      
      // Parallax rotation based on mouse
      const targetRotationY = (state.pointer.x * Math.PI) / 8;
      const targetRotationX = -(state.pointer.y * Math.PI) / 16;
      
      groupRef.current.rotation.y = THREE.MathUtils.lerp(groupRef.current.rotation.y, targetRotationY, 0.05);
      groupRef.current.rotation.x = THREE.MathUtils.lerp(groupRef.current.rotation.x, targetRotationX, 0.05);
    }
  });

  return (
    <group ref={groupRef} position={[0, 0, -radius + 4]}>
      {items.map((item, i) => {
        // Stagger heights slightly
        const yOffset = (i % 2 === 0 ? 0.5 : -0.5) * (Math.random() * 0.5 + 0.5);
        const angle = startAngle + i * angleStep;
        
        const x = Math.sin(angle) * radius;
        const z = Math.cos(angle) * radius;
        
        return (
          <group key={item.id || item.externalId} position={[x, yOffset, z]} rotation={[0, angle, 0]}>
            <GalleryItem item={item} index={i} />
          </group>
        );
      })}
    </group>
  );
}

function GalleryItem({ item, index }: { item: WatchlistItem; index: number }) {
  const meshRef = useRef<THREE.Mesh>(null);
  const router = useRouter();
  const [hovered, setHovered] = useState(false);
  const [validUrl, setValidUrl] = useState<string | null>(null);
  const [failed, setFailed] = useState(false);

  const imageUrl = item.posterUrl || null;

  useEffect(() => {
    if (!imageUrl) {
      setFailed(true);
      return;
    }
    // Bypass browser disk cache for CORS by appending a query string.
    // If the image was previously loaded via standard HTML without crossOrigin,
    // the cached version lacks CORS headers and will block WebGL.
    const corsUrl = imageUrl.includes('?') ? `${imageUrl}&cors=1` : `${imageUrl}?cors=1`;

    let isMounted = true;
    const img = new window.Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      if (isMounted) setValidUrl(corsUrl);
    };
    img.onerror = () => {
      if (isMounted) setFailed(true);
    };
    img.src = corsUrl;
    return () => {
      isMounted = false;
    };
  }, [imageUrl]);

  useFrame((state) => {
    if (meshRef.current) {
      // Pop forward and scale up on hover
      const targetScale = hovered ? 1.15 : 1;
      const targetZ = hovered ? 1.5 : 0;
      
      meshRef.current.scale.lerp(new THREE.Vector3(targetScale, targetScale, targetScale), 0.15);
      meshRef.current.position.z = THREE.MathUtils.lerp(meshRef.current.position.z, targetZ, 0.15);
      
      // Individual subtle float
      const time = state.clock.getElapsedTime();
      if (!hovered) {
        meshRef.current.position.y = THREE.MathUtils.lerp(
          meshRef.current.position.y,
          Math.sin(time * 1.5 + index) * 0.1,
          0.1
        );
      }
    }
  });

  const fallbackMesh = (
    <mesh>
      <planeGeometry args={[2.2, 3.3]} />
      <meshStandardMaterial color="#1e293b" roughness={0.2} metalness={0.8} />
    </mesh>
  );

  return (
    <mesh
      ref={meshRef}
      onPointerOver={(e) => { e.stopPropagation(); setHovered(true); document.body.style.cursor = 'pointer'; }}
      onPointerOut={(e) => { e.stopPropagation(); setHovered(false); document.body.style.cursor = 'auto'; }}
      onClick={(e) => {
        e.stopPropagation();
        router.push(`/media/${item.mediaType}/${item.externalId}`);
      }}
    >
      {validUrl ? (
        <DreiImage
          url={validUrl}
          transparent
          radius={0.15}
          scale={[2.2, 3.3]}
        />
      ) : fallbackMesh}
    </mesh>
  );
}

export default function FloatingGallery({ items }: FloatingGalleryProps) {
  useEffect(() => {
    const originalWarn = console.warn;
    console.warn = (...args) => {
      if (typeof args[0] === 'string' && args[0].includes('THREE.Clock')) return;
      originalWarn.apply(console, args);
    };
    return () => {
      console.warn = originalWarn;
    };
  }, []);

  if (!items || items.length === 0) return null;
  
  return (
    <div style={{ width: '100%', height: '70vh', minHeight: '500px', borderRadius: '1rem', overflow: 'hidden', position: 'relative', background: 'radial-gradient(circle at center, rgba(30,41,59,0.3) 0%, rgba(15,23,42,0.8) 100%)', border: '1px solid rgba(255,255,255,0.05)' }}>
      <Canvas camera={{ position: [0, 0, 8], fov: 50 }}>
        <fog attach="fog" args={['#0f172a', 5, 25]} />
        <ambientLight intensity={0.6} />
        <spotLight position={[0, 10, 10]} intensity={1.5} penumbra={1} color="#a855f7" />
        <spotLight position={[-10, -10, 10]} intensity={1} penumbra={1} color="#00d4ff" />
        
        <Suspense fallback={null}>
          <GalleryItems items={items} />
          <ContactShadows resolution={1024} scale={30} blur={2.5} opacity={0.6} far={15} color="#000000" position={[0, -3.5, 0]} />
          <Environment preset="city" />
        </Suspense>
      </Canvas>
    </div>
  );
}
