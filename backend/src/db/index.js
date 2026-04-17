import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const MEMORY = process.env.MEMORY_STORE === '1';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, '..', '..', 'data');
const MEMORY_SNAPSHOT = path.join(DATA_DIR, 'memory-snapshot.json');

/** @type {Map<string, Map<string, object>>} */
const mem = new Map();

function col(name) {
  if (!mem.has(name)) mem.set(name, new Map());
  return mem.get(name);
}

/** @type {ReturnType<typeof setTimeout> | null} */
let snapshotTimer = null;

function persistMemorySnapshotSync() {
  if (!MEMORY) return;
  try {
    if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
    const collections = {};
    for (const [name, map] of mem.entries()) {
      collections[name] = Object.fromEntries(map);
    }
    fs.writeFileSync(MEMORY_SNAPSHOT, JSON.stringify({ collections, at: new Date().toISOString() }), 'utf8');
  } catch (e) {
    console.warn('[db] memory snapshot save failed:', e.message);
  }
}

function scheduleMemorySnapshot() {
  if (!MEMORY) return;
  clearTimeout(snapshotTimer);
  snapshotTimer = setTimeout(() => {
    snapshotTimer = null;
    persistMemorySnapshotSync();
  }, 350);
}

/** Load MEMORY_STORE data from disk (likes, comments, users, posts, …). Call before seed. */
export function loadMemorySnapshot() {
  if (!MEMORY || !fs.existsSync(MEMORY_SNAPSHOT)) return;
  try {
    const raw = JSON.parse(fs.readFileSync(MEMORY_SNAPSHOT, 'utf8'));
    const collections = raw.collections || {};
    for (const [name, entries] of Object.entries(collections)) {
      const m = col(name);
      for (const [id, row] of Object.entries(entries)) {
        m.set(id, row);
      }
    }
    console.log('[db] memory snapshot loaded');
  } catch (e) {
    console.warn('[db] memory snapshot load failed:', e.message);
  }
}

/** Flush pending snapshot (e.g. before process exit). */
export function flushMemorySnapshotSync() {
  if (!MEMORY) return;
  clearTimeout(snapshotTimer);
  snapshotTimer = null;
  persistMemorySnapshotSync();
}

async function getDb() {
  const { getDb: g } = await import('../config/firebase.js');
  return g();
}

export function useMemory() {
  return MEMORY;
}

export async function docGet(collection, id) {
  if (MEMORY) {
    const c = col(collection);
    return c.get(id) ?? null;
  }
  const db = await getDb();
  const snap = await db.collection(collection).doc(id).get();
  return snap.exists ? { id: snap.id, ...snap.data() } : null;
}

export async function docSet(collection, id, data, merge = true) {
  if (MEMORY) {
    const c = col(collection);
    const prev = c.get(id) || {};
    c.set(id, merge ? { ...prev, ...data, id } : { ...data, id });
    scheduleMemorySnapshot();
    return;
  }
  const db = await getDb();
  await db.collection(collection).doc(id).set(data, { merge });
}

export async function queryWhere(collection, field, op, value, limit = 50) {
  if (MEMORY) {
    const c = col(collection);
    return [...c.values()].filter((d) => {
      const v = d[field];
      if (op === '==') return v === value;
      if (op === 'array-contains') return Array.isArray(v) && v.includes(value);
      return true;
    }).slice(0, limit);
  }
  const db = await getDb();
  const snap = await db.collection(collection).where(field, op, value).limit(limit).get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function queryAll(collection, limit = 200) {
  if (MEMORY) {
    return [...col(collection).values()].slice(0, limit);
  }
  const db = await getDb();
  const snap = await db.collection(collection).limit(limit).get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function addDoc(collection, data) {
  if (MEMORY) {
    const id = `mem_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
    const row = { ...data, id };
    col(collection).set(id, row);
    scheduleMemorySnapshot();
    return id;
  }
  const db = await getDb();
  const ref = await db.collection(collection).add(data);
  return ref.id;
}

export async function docDelete(collection, id) {
  if (MEMORY) {
    col(collection).delete(id);
    scheduleMemorySnapshot();
    return;
  }
  const db = await getDb();
  await db.collection(collection).doc(id).delete();
}

/** Scan users by email (lowercase) — OK for MVP / memory store */
export async function findUserByEmail(email) {
  const e = String(email || '').trim().toLowerCase();
  if (!e) return null;
  if (MEMORY) {
    for (const row of col('users').values()) {
      if (String(row.email || '').toLowerCase() === e) return row;
    }
    return null;
  }
  const db = await getDb();
  const snap = await db.collection('users').where('email', '==', e).limit(1).get();
  if (snap.empty) return null;
  const d = snap.docs[0];
  return { id: d.id, ...d.data() };
}
