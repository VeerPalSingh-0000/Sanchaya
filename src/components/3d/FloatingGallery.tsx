"use client";

import * as THREE from "three";
import {
  useRef,
  useState,
  useEffect,
  useMemo,
  useCallback,
  Suspense,
} from "react";
import { Canvas, useFrame, useThree } from "@react-three/fiber";
import {
  Image as DreiImage,
  OrthographicCamera,
  Line,
} from "@react-three/drei";
import { useRouter } from "next/navigation";
import type { WatchlistItem } from "@/types/media";

interface FloatingGalleryProps {
  items: WatchlistItem[];
}

/* ─────────────────────────────────────────────────────────────────────────
   Force-Directed Graph Layout
   Simulates physics to spread nodes apart while keeping connected ones close.
   ───────────────────────────────────────────────────────────────────────── */

interface GraphNode {
  item: WatchlistItem;
  x: number;
  y: number;
  vx: number;
  vy: number;
}

interface GraphEdge {
  source: number;
  target: number;
  sharedGenres: string[];
}

function buildGraph(items: WatchlistItem[]) {
  // Seed positions in a spiral so nothing overlaps initially
  const nodes: GraphNode[] = items.map((item, i) => {
    const angle = i * 2.39996; // golden angle in radians
    const r = Math.sqrt(i + 1) * 1.8;
    return {
      item,
      x: Math.cos(angle) * r,
      y: Math.sin(angle) * r,
      vx: 0,
      vy: 0,
    };
  });

  // Build edges: connect items that share at least one genre
  const edges: GraphEdge[] = [];
  for (let i = 0; i < items.length; i++) {
    const genresA = new Set(items[i].genres?.map((g) => g.name) || []);
    if (genresA.size === 0) genresA.add(items[i].mediaType);
    for (let j = i + 1; j < items.length; j++) {
      const genresB = items[j].genres?.map((g) => g.name) || [
        items[j].mediaType,
      ];
      const shared = genresB.filter((g) => genresA.has(g));
      if (shared.length > 0) {
        edges.push({ source: i, target: j, sharedGenres: shared });
      }
    }
  }

  // Run force simulation (simple Fruchterman-Reingold)
  const idealDist = 2.5; // Tighter packing
  const iterations = 120;
  let temperature = 3;

  for (let iter = 0; iter < iterations; iter++) {
    // Gravity towards center to keep everything tightly grouped
    for (let i = 0; i < nodes.length; i++) {
      let dist =
        Math.sqrt(nodes[i].x * nodes[i].x + nodes[i].y * nodes[i].y) || 0.01;
      const force = dist * 0.3; // Stronger pull to center
      nodes[i].vx -= (nodes[i].x / dist) * force;
      nodes[i].vy -= (nodes[i].y / dist) * force;
    }

    // Repulsion between all node pairs
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        let dx = nodes[i].x - nodes[j].x;
        let dy = nodes[i].y - nodes[j].y;
        let dist = Math.sqrt(dx * dx + dy * dy) || 0.01;
        const force = (idealDist * idealDist) / dist;
        const fx = (dx / dist) * force;
        const fy = (dy / dist) * force;
        nodes[i].vx += fx;
        nodes[i].vy += fy;
        nodes[j].vx -= fx;
        nodes[j].vy -= fy;
      }
    }

    // Attraction along edges
    for (const edge of edges) {
      const a = nodes[edge.source];
      const b = nodes[edge.target];
      let dx = a.x - b.x;
      let dy = a.y - b.y;
      let dist = Math.sqrt(dx * dx + dy * dy) || 0.01;
      const force = (dist * dist) / idealDist;
      const strength = 0.3 + edge.sharedGenres.length * 0.15; // stronger for more shared genres
      const fx = (dx / dist) * force * strength;
      const fy = (dy / dist) * force * strength;
      a.vx -= fx;
      a.vy -= fy;
      b.vx += fx;
      b.vy += fy;
    }

    // Apply velocity with temperature cooling
    for (const node of nodes) {
      const speed = Math.sqrt(node.vx * node.vx + node.vy * node.vy) || 0.01;
      const capped = Math.min(speed, temperature);
      node.x += (node.vx / speed) * capped;
      node.y += (node.vy / speed) * capped;
      node.vx = 0;
      node.vy = 0;
    }

    temperature *= 0.97;
  }

  return { nodes, edges };
}

/* ─────────────────────────────────────────────────────────────────────────
   Edge Rendering — Glowing connections between nodes
   ───────────────────────────────────────────────────────────────────────── */

function GraphEdges({
  nodes,
  edges,
  hoveredIndex,
}: {
  nodes: GraphNode[];
  edges: GraphEdge[];
  hoveredIndex: number | null;
}) {
  return (
    <group>
      {edges.map((edge, i) => {
        const a = nodes[edge.source];
        const b = nodes[edge.target];
        const isHighlighted =
          hoveredIndex === edge.source || hoveredIndex === edge.target;
        const opacity = isHighlighted ? 0.5 : 0.08;
        const width = isHighlighted ? 2.5 : 1;
        const color = isHighlighted ? "#ffc174" : "#334155";

        return (
          <Line
            key={i}
            points={[
              [a.x, a.y, 0],
              [b.x, b.y, 0],
            ]}
            color={color}
            lineWidth={width}
            transparent
            opacity={opacity}
          />
        );
      })}
    </group>
  );
}

/* ─────────────────────────────────────────────────────────────────────────
   Node Rendering — Poster cards as graph nodes
   ───────────────────────────────────────────────────────────────────────── */

function GraphNode({
  node,
  index,
  onHover,
  onUnhover,
  isHovered,
  isConnectedToHovered,
  isDimmed,
}: {
  node: GraphNode;
  index: number;
  onHover: (i: number) => void;
  onUnhover: () => void;
  isHovered: boolean;
  isConnectedToHovered: boolean;
  isDimmed: boolean;
}) {
  const meshRef = useRef<THREE.Group>(null);
  const router = useRouter();
  const [validUrl, setValidUrl] = useState<string | null>(null);
  const imageUrl = node.item.posterUrl || null;

  useEffect(() => {
    if (!imageUrl) return;
    const corsUrl = imageUrl.includes("?")
      ? `${imageUrl}&cors=1`
      : `${imageUrl}?cors=1`;
    let alive = true;
    const img = new window.Image();
    img.crossOrigin = "anonymous";
    img.onload = () => {
      if (alive) setValidUrl(corsUrl);
    };
    img.src = corsUrl;
    return () => {
      alive = false;
    };
  }, [imageUrl]);

  useFrame((state, delta) => {
    if (!meshRef.current) return;

    // Scale spring
    const targetScale = isHovered ? 1.25 : isConnectedToHovered ? 1.08 : 1;
    meshRef.current.scale.x = THREE.MathUtils.damp(
      meshRef.current.scale.x,
      targetScale,
      5,
      delta,
    );
    meshRef.current.scale.y = THREE.MathUtils.damp(
      meshRef.current.scale.y,
      targetScale,
      5,
      delta,
    );

    // Z-pop
    const targetZ = isHovered ? 1.5 : isConnectedToHovered ? 0.5 : 0;
    meshRef.current.position.z = THREE.MathUtils.damp(
      meshRef.current.position.z,
      targetZ,
      5,
      delta,
    );

    // Opacity dimming
    meshRef.current.traverse((child) => {
      if ((child as THREE.Mesh).material) {
        const mat = (child as THREE.Mesh).material as THREE.MeshBasicMaterial;
        if (mat.opacity !== undefined) {
          const targetOpacity = isDimmed ? 0.25 : 1;
          mat.opacity = THREE.MathUtils.lerp(mat.opacity, targetOpacity, 0.1);
        }
      }
    });

    // Gentle idle float
    const t = state.clock.elapsedTime;
    if (!isHovered) {
      meshRef.current.position.x =
        node.x + Math.sin(t * 0.3 + index * 1.7) * 0.06;
      meshRef.current.position.y =
        node.y + Math.cos(t * 0.4 + index * 2.3) * 0.06;
    }
  });

  // Status ring color
  const statusColor = useMemo(() => {
    switch (node.item.status) {
      case "watching":
        return "#22c55e";
      case "completed":
        return "#3b82f6";
      case "plan_to_watch":
        return "#f59e0b";
      case "dropped":
        return "#ef4444";
      default:
        return "#6b7280";
    }
  }, [node.item.status]);

  const cardW = 1.6;
  const cardH = 2.4;

  return (
    <group
      ref={meshRef}
      position={[node.x, node.y, 0]}
      onPointerOver={(e) => {
        e.stopPropagation();
        onHover(index);
        document.body.style.cursor = "pointer";
      }}
      onPointerOut={(e) => {
        e.stopPropagation();
        onUnhover();
        document.body.style.cursor = "grab";
      }}
      onClick={(e) => {
        e.stopPropagation();
        router.push(`/media/${node.item.mediaType}/${node.item.externalId}`);
      }}
    >
      {/* Glow ring behind poster — visible on hover */}
      {isHovered && (
        <mesh position={[0, 0, -0.05]}>
          <planeGeometry args={[cardW + 0.3, cardH + 0.3]} />
          <meshBasicMaterial
            color={statusColor}
            transparent
            opacity={0.4}
            blending={THREE.AdditiveBlending}
            depthWrite={false}
          />
        </mesh>
      )}

      {/* Poster image */}
      {validUrl ? (
        <DreiImage
          url={validUrl}
          transparent
          radius={0.06}
          scale={[cardW, cardH]}
        />
      ) : (
        <mesh>
          <planeGeometry args={[cardW, cardH]} />
          <meshBasicMaterial
            color="#141b2b"
            transparent
            opacity={isDimmed ? 0.25 : 0.9}
          />
        </mesh>
      )}

      {/* Status dot */}
      <mesh position={[cardW / 2 - 0.15, -cardH / 2 + 0.15, 0.02]}>
        <circleGeometry args={[0.08, 16]} />
        <meshBasicMaterial color={statusColor} />
      </mesh>
    </group>
  );
}

/* ─────────────────────────────────────────────────────────────────────────
   Graph Scene — Camera, pan/zoom, orchestration
   ───────────────────────────────────────────────────────────────────────── */

function GraphScene({ items }: { items: WatchlistItem[] }) {
  const { nodes, edges } = useMemo(() => buildGraph(items), [items]);
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);
  const groupRef = useRef<THREE.Group>(null);

  // Connected node indices for the currently hovered node
  const connectedSet = useMemo(() => {
    if (hoveredIndex === null) return new Set<number>();
    const set = new Set<number>();
    for (const edge of edges) {
      if (edge.source === hoveredIndex) set.add(edge.target);
      if (edge.target === hoveredIndex) set.add(edge.source);
    }
    return set;
  }, [hoveredIndex, edges]);

  // Pan & zoom via pointer drag + scroll
  const panOffset = useRef(new THREE.Vector2(0, 0));
  const zoom = useRef(1);
  const { gl, camera } = useThree();

  useEffect(() => {
    let isDragging = false;
    let prevX = 0;
    let prevY = 0;

    const onDown = (e: PointerEvent) => {
      isDragging = true;
      prevX = e.clientX;
      prevY = e.clientY;
      gl.domElement.style.cursor = "grabbing";
    };
    const onMove = (e: PointerEvent) => {
      if (!isDragging) return;
      const dx = ((e.clientX - prevX) * 0.02) / zoom.current;
      const dy = (-(e.clientY - prevY) * 0.02) / zoom.current;
      panOffset.current.x += dx;
      panOffset.current.y += dy;
      prevX = e.clientX;
      prevY = e.clientY;
    };
    const onUp = () => {
      isDragging = false;
      gl.domElement.style.cursor = "grab";
    };
    const onWheel = (e: WheelEvent) => {
      e.preventDefault();
      zoom.current = THREE.MathUtils.clamp(
        zoom.current - e.deltaY * 0.001,
        0.3,
        3,
      );
    };

    const el = gl.domElement;
    el.style.cursor = "grab";
    el.addEventListener("pointerdown", onDown);
    el.addEventListener("pointermove", onMove);
    el.addEventListener("pointerup", onUp);
    el.addEventListener("pointerleave", onUp);
    el.addEventListener("wheel", onWheel, { passive: false });

    return () => {
      el.removeEventListener("pointerdown", onDown);
      el.removeEventListener("pointermove", onMove);
      el.removeEventListener("pointerup", onUp);
      el.removeEventListener("pointerleave", onUp);
      el.removeEventListener("wheel", onWheel);
    };
  }, [gl, camera]);

  useFrame((state, delta) => {
    if (groupRef.current) {
      // Smooth pan
      groupRef.current.position.x = THREE.MathUtils.damp(
        groupRef.current.position.x,
        panOffset.current.x,
        4,
        delta,
      );
      groupRef.current.position.y = THREE.MathUtils.damp(
        groupRef.current.position.y,
        panOffset.current.y,
        4,
        delta,
      );

      // Smooth zoom
      const targetZoom = zoom.current;
      groupRef.current.scale.x = THREE.MathUtils.damp(
        groupRef.current.scale.x,
        targetZoom,
        4,
        delta,
      );
      groupRef.current.scale.y = THREE.MathUtils.damp(
        groupRef.current.scale.y,
        targetZoom,
        4,
        delta,
      );
    }
  });

  return (
    <group ref={groupRef}>
      {/* Edges first (behind nodes) */}
      <GraphEdges nodes={nodes} edges={edges} hoveredIndex={hoveredIndex} />

      {/* Nodes */}
      {nodes.map((node, i) => {
        const isHovered = hoveredIndex === i;
        const isConnected = connectedSet.has(i);
        const isDimmed = hoveredIndex !== null && !isHovered && !isConnected;

        return (
          <GraphNode
            key={node.item.id || node.item.externalId}
            node={node}
            index={i}
            onHover={setHoveredIndex}
            onUnhover={() => setHoveredIndex(null)}
            isHovered={isHovered}
            isConnectedToHovered={isConnected}
            isDimmed={isDimmed}
          />
        );
      })}
    </group>
  );
}

/* ─────────────────────────────────────────────────────────────────────────
   Ambient Particles
   ───────────────────────────────────────────────────────────────────────── */

function AmbientParticles({ count = 200 }: { count?: number }) {
  const ref = useRef<THREE.Points>(null);

  const positions = useMemo(() => {
    const arr = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      arr[i * 3] = (Math.random() - 0.5) * 60;
      arr[i * 3 + 1] = (Math.random() - 0.5) * 40;
      arr[i * 3 + 2] = (Math.random() - 0.5) * 5 - 2;
    }
    return arr;
  }, [count]);

  useFrame((state) => {
    if (ref.current) {
      ref.current.rotation.z = state.clock.elapsedTime * 0.005;
    }
  });

  return (
    <points ref={ref}>
      <bufferGeometry>
        <bufferAttribute
          attach="attributes-position"
          count={count}
          array={positions}
          itemSize={3}
          args={[positions, 3]}
        />
      </bufferGeometry>
      <pointsMaterial
        size={3}
        color="#ffc174"
        transparent
        opacity={0.35}
        blending={THREE.AdditiveBlending}
        depthWrite={false}
        sizeAttenuation={false}
      />
    </points>
  );
}

/* ─────────────────────────────────────────────────────────────────────────
   Main Export
   ───────────────────────────────────────────────────────────────────────── */

export default function FloatingGallery({ items }: FloatingGalleryProps) {
  useEffect(() => {
    const ow = console.warn;
    console.warn = (...args) => {
      if (typeof args[0] === "string" && args[0].includes("THREE.Clock"))
        return;
      ow.apply(console, args);
    };
    return () => {
      console.warn = ow;
    };
  }, []);

  if (!items || items.length === 0) return null;

  // Count connections for stats
  const edgeCount = useMemo(() => {
    let count = 0;
    for (let i = 0; i < items.length; i++) {
      const ga = new Set(
        items[i].genres?.map((g) => g.name) || [items[i].mediaType],
      );
      for (let j = i + 1; j < items.length; j++) {
        const gb = items[j].genres?.map((g) => g.name) || [items[j].mediaType];
        if (gb.some((g) => ga.has(g))) count++;
      }
    }
    return count;
  }, [items]);

  return (
    <div
      style={{
        width: "100%",
        height: "80vh",
        minHeight: "600px",
        borderRadius: "1.5rem",
        overflow: "hidden",
        position: "relative",
        backgroundColor: "#050509",
        touchAction: "none",
      }}
    >
      {/* Subtle radial vignette */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          pointerEvents: "none",
          zIndex: 10,
          background:
            "radial-gradient(ellipse at center, transparent 50%, rgba(0,0,0,0.85) 100%)",
        }}
      />

      {/* Top bar: stats + hint */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          zIndex: 20,
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          padding: "1rem 1.5rem",
          pointerEvents: "none",
        }}
      >
        <div style={{ display: "flex", gap: "1.2rem", alignItems: "center" }}>
          <span
            style={{
              fontSize: "0.7rem",
              color: "rgba(255,255,255,0.4)",
              fontFamily: "Inter, sans-serif",
              letterSpacing: "0.08em",
              textTransform: "uppercase",
            }}
          >
            {items.length} nodes
          </span>
          <span
            style={{
              fontSize: "0.7rem",
              color: "rgba(255,255,255,0.25)",
              fontFamily: "Inter, sans-serif",
            }}
          >
            •
          </span>
          <span
            style={{
              fontSize: "0.7rem",
              color: "rgba(255,255,255,0.4)",
              fontFamily: "Inter, sans-serif",
              letterSpacing: "0.08em",
              textTransform: "uppercase",
            }}
          >
            {edgeCount} connections
          </span>
        </div>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "0.4rem",
            fontSize: "0.7rem",
            color: "rgba(255,255,255,0.3)",
            fontFamily: "Inter, sans-serif",
            letterSpacing: "0.06em",
          }}
        >
          <span
            className="material-symbols-outlined"
            style={{ fontSize: "14px" }}
          >
            mouse
          </span>
          DRAG TO PAN • SCROLL TO ZOOM
        </div>
      </div>

      {/* Bottom legend */}
      <div
        style={{
          position: "absolute",
          bottom: "1.2rem",
          left: "50%",
          transform: "translateX(-50%)",
          display: "flex",
          gap: "1.2rem",
          zIndex: 20,
          padding: "0.5rem 1.2rem",
          borderRadius: "9999px",
          background: "rgba(0,0,0,0.5)",
          backdropFilter: "blur(12px)",
          border: "1px solid rgba(255,255,255,0.06)",
        }}
      >
        {[
          { label: "Watching", color: "#22c55e" },
          { label: "Completed", color: "#3b82f6" },
          { label: "Plan", color: "#f59e0b" },
          { label: "Dropped", color: "#ef4444" },
        ].map((s) => (
          <span
            key={s.label}
            style={{
              display: "flex",
              alignItems: "center",
              gap: "0.35rem",
              fontSize: "0.65rem",
              color: "rgba(255,255,255,0.5)",
              fontFamily: "Inter, sans-serif",
              letterSpacing: "0.05em",
              textTransform: "uppercase",
            }}
          >
            <span
              style={{
                width: 7,
                height: 7,
                borderRadius: "50%",
                backgroundColor: s.color,
                boxShadow: `0 0 6px ${s.color}`,
              }}
            />
            {s.label}
          </span>
        ))}
      </div>

      <Canvas
        orthographic
        camera={{ zoom: 110, position: [0, 0, 100], near: 0.1, far: 200 }}
        gl={{ antialias: true, alpha: true }}
        dpr={[1, 2]}
      >
        <color attach="background" args={["#050509"]} />

        {/* Minimal lighting */}
        <ambientLight intensity={1.5} />
        <directionalLight
          position={[10, 10, 10]}
          intensity={0.3}
          color="#ffc174"
        />

        <Suspense fallback={null}>
          <GraphScene items={items} />
          <AmbientParticles count={250} />
        </Suspense>
      </Canvas>
    </div>
  );
}
