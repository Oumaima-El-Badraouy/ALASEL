import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import multer from 'multer';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const UPLOAD_SUB = path.join(__dirname, '..', '..', 'uploads', 'posts');

function ensureDir() {
  if (!fs.existsSync(UPLOAD_SUB)) {
    fs.mkdirSync(UPLOAD_SUB, { recursive: true });
  }
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    ensureDir();
    cb(null, UPLOAD_SUB);
  },
  filename: (_req, file, cb) => {
    let ext = path.extname(file.originalname || '');
    if (!ext && file.mimetype) {
      const m = {
        'video/mp4': '.mp4',
        'video/quicktime': '.mov',
        'video/webm': '.webm',
        'video/3gpp': '.3gp',
        'video/x-matroska': '.mkv',
      };
      ext = m[file.mimetype] || '.mp4';
    }
    if (!ext) ext = '.mp4';
    const name = `${Date.now()}_${Math.random().toString(36).slice(2, 10)}${ext}`;
    cb(null, name);
  },
});

export const videoUpload = multer({
  storage,
  limits: { fileSize: 25 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (file.mimetype && file.mimetype.startsWith('video/')) {
      cb(null, true);
      return;
    }
    cb(new Error('Not a video file'));
  },
});

export function uploadPostVideo(req, res) {
  const file = req.file;
  if (!file) {
    return res.status(400).json({ error: 'Missing video file (field name: video)' });
  }
  const pubPath = `/uploads/posts/${file.filename}`;
  const base = `${req.protocol}://${req.get('host')}`;
  return res.json({ url: `${base}${pubPath}` });
}

/** Express error handler after multer routes */
export function uploadPostVideoError(err, req, res, next) {
  if (!err) return next();
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ error: 'Video too large (max 25 MB)' });
  }
  if (err.message === 'Not a video file') {
    return res.status(400).json({ error: err.message });
  }
  next(err);
}
