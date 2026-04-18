import fs from 'fs';

/**
 * Déduit une extension de conteneur à partir des premiers octets (sans FFmpeg).
 * Couvre les formats les plus courants sur mobile / web.
 */
export function sniffVideoExtension(absPath) {
  let fd;
  try {
    fd = fs.openSync(absPath, 'r');
    const buf = Buffer.alloc(512);
    const n = fs.readSync(fd, buf, 0, 512, 0);
    if (n < 12) return null;

    // ISO-BMFF (MP4 / MOV / M4V / 3GP familles)
    if (buf[4] === 0x66 && buf[5] === 0x74 && buf[6] === 0x79 && buf[7] === 0x70) {
      if (n >= 12) {
        const brand = buf.slice(8, 12).toString('ascii').toLowerCase();
        if (brand.includes('qt') || brand.startsWith('qt')) return '.mov';
        if (brand.includes('3gp') || brand.includes('3g2')) return '.3gp';
      }
      return '.mp4';
    }

    // EBML — WebM ou Matroska (MKV)
    if (buf[0] === 0x1a && buf[1] === 0x45 && buf[2] === 0xdf && buf[3] === 0xa3) {
      return '.mkv';
    }

    // RIFF … AVI
    if (
      buf[0] === 0x52 &&
      buf[1] === 0x49 &&
      buf[2] === 0x46 &&
      buf[3] === 0x46 &&
      n >= 12 &&
      buf[8] === 0x41 &&
      buf[9] === 0x56 &&
      buf[10] === 0x49
    ) {
      return '.avi';
    }

    // MPEG program stream
    if (buf[0] === 0x00 && buf[1] === 0x00 && buf[2] === 0x01 && buf[3] === 0xba) {
      return '.mpeg';
    }

    // MPEG transport stream (sync byte 0x47)
    if (buf[0] === 0x47 && n > 188 && buf[188] === 0x47) {
      return '.ts';
    }

    // FLV
    if (buf[0] === 0x46 && buf[1] === 0x4c && buf[2] === 0x56) {
      return '.flv';
    }

    // ASF / WMV souvent commencent par GUID ; entête simple 0x30 0x26 …
    if (buf[0] === 0x30 && buf[1] === 0x26 && buf[2] === 0xb2 && buf[3] === 0x75) {
      return '.wmv';
    }

    return null;
  } catch {
    return null;
  } finally {
    if (fd != null) {
      try {
        fs.closeSync(fd);
      } catch (_) {}
    }
  }
}
