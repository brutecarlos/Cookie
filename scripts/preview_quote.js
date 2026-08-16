// Usage: node preview_quote.js [installTimestamp] [seed]
// Example: node preview_quote.js 1660000000000 12345
const fs = require('fs');
const path = require('path');

const quotes = JSON.parse(fs.readFileSync(path.resolve(__dirname, '..', 'quotes.json')));

function pickQuote(installTime, seed, asOfDate = Date.now()){
  const installDate = new Date(Number(installTime));
  installDate.setHours(0,0,0,0);
  const today = new Date(Number(asOfDate));
  today.setHours(0,0,0,0);
  const daysSince = Math.floor((today - installDate) / 86400000);
  const idx = ((Number(seed) % quotes.length) + daysSince) % quotes.length;
  return { idx, quote: quotes[idx] };
}

const [,, installArg, seedArg, asOfArg] = process.argv;
const install = installArg || Date.now();
const seed = seedArg || Math.floor(Math.random()*1e9);
const asOf = asOfArg || Date.now();

const res = pickQuote(install, seed, asOf);
console.log('install:', new Date(Number(install)).toISOString());
console.log('seed:', seed);
console.log('asOf:', new Date(Number(asOf)).toISOString());
console.log('index:', res.idx);
console.log('quote:', res.quote.text);
