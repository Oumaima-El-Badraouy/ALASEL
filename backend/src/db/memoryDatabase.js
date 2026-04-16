/**
 * Minimal in-memory document store for hackathon demos (USE_MEMORY=1).
 * Not for production — use Firestore when credentials exist.
 */

const collections = new Map();

function col(name) {
  if (!collections.has(name)) collections.set(name, new Map());
  return collections.get(name);
}

function genId() {
  return `mem_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 9)}`;
}

export const memoryDb = {
  async getDoc(collectionName, id) {
    const doc = col(collectionName).get(id);
    return doc ? { id, data: () => doc } : null;
  },

  async setDoc(collectionName, id, data, merge = false) {
    const c = col(collectionName);
    const prev = c.get(id) || {};
    c.set(id, merge ? { ...prev, ...data } : { ...data });
  },

  async updateDoc(collectionName, id, patch) {
    const c = col(collectionName);
    const prev = c.get(id);
    if (!prev) throw new Error('NOT_FOUND');
    c.set(id, { ...prev, ...patch });
  },

  async deleteDoc(collectionName, id) {
    col(collectionName).delete(id);
  },

  async addDoc(collectionName, data) {
    const id = genId();
    col(collectionName).set(id, { ...data });
    return id;
  },

  /** Simple query: [{ field, op, value }] op is '==' or 'in' */
  async query(collectionName, filters = []) {
    let rows = [...col(collectionName).entries()].map(([id, data]) => ({ id, ...data }));
    for (const f of filters) {
      if (f.op === '==') {
        rows = rows.filter((r) => r[f.field] === f.value);
      } else if (f.op === 'in') {
        const arr = f.value;
        rows = rows.filter((r) => arr.includes(r[f.field]));
      }
    }
    return rows;
  },

  async listAll(collectionName) {
    return [...col(collectionName).entries()].map(([id, data]) => ({ id, ...data }));
  },
};
