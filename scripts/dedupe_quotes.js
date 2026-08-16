const fs = require('fs');
const path = require('path');

const file = path.resolve(__dirname, '..', 'quotes.json');
const raw = fs.readFileSync(file, 'utf8');
const quotes = JSON.parse(raw);

const seen = new Set();
const deduped = quotes.filter(q => {
  const key = (q.text || '').trim();
  if (seen.has(key)) return false;
  seen.add(key);
  return true;
});

fs.writeFileSync(file, JSON.stringify(deduped, null, 2), 'utf8');
console.log(`Deduped quotes: ${quotes.length} -> ${deduped.length}`);
