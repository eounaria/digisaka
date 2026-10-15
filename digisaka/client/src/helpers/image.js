// Read a File as the base64 payload the scheduler upload expects (no data: prefix).
export function fileToPayload(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(new Error('Could not read the image.'));
    reader.onload = () => resolve({ img_name: file.name, img: String(reader.result).split(',')[1] ?? '' });
    reader.readAsDataURL(file);
  });
}
