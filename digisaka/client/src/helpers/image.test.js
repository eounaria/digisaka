import { describe, it, expect, vi, afterEach } from 'vitest';
import { fileToPayload } from './image.js';

afterEach(() => vi.unstubAllGlobals());

function fakeReader(result, fail) {
  return class { readAsDataURL() { this.result = result; setTimeout(() => (fail ? this.onerror() : this.onload())); } };
}

describe('fileToPayload', () => {
  it('returns the file name and base64 without the data: prefix', async () => {
    vi.stubGlobal('FileReader', fakeReader('data:image/jpeg;base64,QUJD'));
    expect(await fileToPayload({ name: 'leaf.jpg' })).toEqual({ img_name: 'leaf.jpg', img: 'QUJD' });
  });
  it('rejects with a readable message when the file cannot be read', async () => {
    vi.stubGlobal('FileReader', fakeReader('', true));
    await expect(fileToPayload({ name: 'x.jpg' })).rejects.toThrow('Could not read the image.');
  });
});
