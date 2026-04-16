const MEMORY = process.env.MEMORY_STORE === '1';

async function getDb() {
  const { getDb: g } = await import('../config/firebase.js');
  return g();
}

/** @type {Map<string, Map<string, object>>} */
const mem = new Map();

function col(name) {
  if (!mem.has(name)) mem.set(name, new Map());
  return mem.get(name);
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
    return id;
  }
  const db = await getDb();
  const ref = await db.collection(collection).add(data);
  return ref.id;
}
