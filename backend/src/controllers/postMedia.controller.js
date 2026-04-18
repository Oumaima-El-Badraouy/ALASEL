import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import multer from 'multer';
import { sniffVideoExtension } from '../utils/videoSniff.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const UPLOAD_SUB = path.join(__dirname, '..', '..', 'uploads', 'posts');

/** Extensions de fichiers vidéo courantes (upload gallery / messagerie). */
const VIDEO_FILENAME_EXT =
  /\.(mp4|m4v|mov|qt|webm|mkv|3gp|3g2|avi|mpeg|mpg|mpe|m1v|vob|ts|mts|m2ts|flv|wmv|asf|ogv|divx|xvid)$/i;

/** MIME → extension quand le nom de fichier n’en a pas. */
const MIME_TO_EXT = {
  'video/mp4': '.mp4',
  'video/x-m4v': '.m4v',
  'video/quicktime': '.mov',
  'video/webm': '.webm',
  'video/x-matroska': '.mkv',
  'video/matroska': '.mkv',
  'video/3gpp': '.3gp',
  'video/3gpp2': '.3g2',
  'video/x-msvideo': '.avi',
  'video/avi': '.avi',
  'video/msvideo': '.avi',
  'video/mpeg': '.mpeg',
  'video/mpg': '.mpeg',
  'video/x-mpeg': '.mpeg',
  'video/mp2t': '.ts',
  'video/vnd.dlna.mpeg-tts': '.ts',
  'video/x-flv': '.flv',
  'video/x-ms-wmv': '.wmv',
  'video/wmv': '.wmv',
  'video/ogg': '.ogv',
  'video/x-ms-asf': '.asf',
  'video/asf': '.asf',
};

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
    let ext = path.extname(file.originalname || '').toLowerCase();
    if (!ext && file.mimetype) {
      ext = MIME_TO_EXT[file.mimetype] || null;
    }
    if (!ext) ext = '.bin';
    const name = `${Date.now()}_${Math.random().toString(36).slice(2, 10)}${ext}`;
    cb(null, name);
  },
});

function acceptVideoUpload(_req, file, cb) {
  const mime = file.mimetype || '';
  if (mime.startsWith('video/')) {
    cb(null, true);
    return;
  }
  const name = String(file.originalname || '').toLowerCase();
  if (VIDEO_FILENAME_EXT.test(name)) {
    cb(null, true);
    return;
  }
  // Souvent sur Android sans extension ni MIME fiable — on valide après coup par magic bytes.
  if (mime === 'application/octet-stream' || mime === 'binary/octet-stream' || !mime) {
    cb(null, true);
    return;
  }
  cb(new Error('Not a video file'));
}

export const videoUpload = multer({
  storage,
  limits: { fileSize: 25 * 1024 * 1024 },
  fileFilter: acceptVideoUpload,
});

export function uploadPostVideo(req, res) {
  const file = req.file;
  if (!file) {
    return res.status(400).json({ error: 'Missing video file (field name: video)' });
  }

  const mimeVideo = file.mimetype && String(file.mimetype).startsWith('video/');
  const sniffed = sniffVideoExtension(file.path);

  if (sniffed === null && !mimeVideo) {
    try {
      fs.unlinkSync(file.path);
    } catch (_) {}
    return res.status(400).json({ error: 'Unrecognized video format (not a supported container)' });
  }

  // MIME vidéo mais conteneur non reconnu par sniff : au moins une extension lisible pour l’URL.
  if (sniffed === null && mimeVideo) {
    const cur = path.extname(file.filename).toLowerCase();
    const want = MIME_TO_EXT[file.mimetype] || '.mp4';
    if (cur === '.bin' || cur === '') {
      const base = path.basename(file.filename, cur);
      const newFilename = `${base}${want}`;
      const newPath = path.join(UPLOAD_SUB, newFilename);
      try {
        fs.renameSync(file.path, newPath);
        file.filename = newFilename;
        file.path = newPath;
      } catch (e) {
        try {
          fs.unlinkSync(file.path);
        } catch (_) {}
        return res.status(500).json({ error: e.message });
      }
    }
  }

  if (sniffed !== null) {
    const cur = path.extname(file.filename).toLowerCase();
    if (cur !== sniffed) {
      const base = path.basename(file.filename, cur);
      const newFilename = `${base}${sniffed}`;
      const newPath = path.join(UPLOAD_SUB, newFilename);
      try {
        fs.renameSync(file.path, newPath);
        file.filename = newFilename;
        file.path = newPath;
      } catch (e) {
        try {
          fs.unlinkSync(file.path);
        } catch (_) {}
        return res.status(500).json({ error: e.message });
      }
    }
  }

  const pubPath = `/uploads/posts/${file.filename}`;
  const base = `${req.protocol}://${req.get('host')}`;
  return res.json({ url: `${base}${pubPath}` });
}

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
