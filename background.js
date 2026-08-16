chrome.runtime.onInstalled.addListener(() => {
  chrome.storage.local.get(['installInfo'], (res) => {
    if (!res || !res.installInfo) {
      const info = { installTime: Date.now(), seed: Math.floor(Math.random() * 1e9) };
      chrome.storage.local.set({ installInfo: info });
    }
  });
});

// Ensure installInfo exists when the worker starts (defensive)
chrome.runtime.onStartup.addListener(() => {
  chrome.storage.local.get(['installInfo'], (res) => {
    if (!res || !res.installInfo) {
      const info = { installTime: Date.now(), seed: Math.floor(Math.random() * 1e9) };
      chrome.storage.local.set({ installInfo: info });
    }
  });
});

// DAILY SHOW: show popup once per day at first browser start or at midnight when browser stays open.
function toDateKey(d) {
  const dt = new Date(d);
  return dt.getFullYear() + '-' + String(dt.getMonth()+1).padStart(2,'0') + '-' + String(dt.getDate()).padStart(2,'0');
}

// get today's quote deterministically using installInfo and bundled quotes.json
async function getTodayQuote() {
  try{
    const resp = await fetch(chrome.runtime.getURL('quotes.json'));
    const quotes = await resp.json();
    return new Promise((resolve) => {
      chrome.storage.local.get(['installInfo'], (res) => {
        let info = res && res.installInfo;
        if (!info) {
          info = { installTime: Date.now(), seed: Math.floor(Math.random() * 1e9) };
          chrome.storage.local.set({ installInfo: info });
        }

        const installDate = new Date(info.installTime);
        installDate.setHours(0,0,0,0);
        const today = new Date();
        today.setHours(0,0,0,0);
        const daysSince = Math.floor((today - installDate) / 86400000);
        const idx = ((info.seed % quotes.length) + daysSince) % quotes.length;
        resolve(quotes[idx] || { text: 'No quote available.', author: '' });
      });
    });
  }catch(e){
    return { text: 'No quote available.', author: '' };
  }
}

async function tryShowOnceToday() {
  chrome.storage.local.get(['lastShownDate','autoOpen'], async (res) => {
    const last = res && res.lastShownDate;
    let autoOpen = res && (typeof res.autoOpen !== 'undefined' ? res.autoOpen : undefined);
    const todayKey = toDateKey(Date.now());
    if (last === todayKey) return; // already shown today

    // default autoOpen to true on first run
    if (typeof autoOpen === 'undefined') {
      autoOpen = true;
      chrome.storage.local.set({ autoOpen: true });
    }

    const quote = await getTodayQuote();

    // if autoOpen is enabled, try to open popup; otherwise show notification
    if (autoOpen) {
      try {
        if (chrome.action && chrome.action.openPopup) {
              chrome.action.openPopup(() => {
                chrome.storage.local.set({ lastShownDate: todayKey });
              });
          return;
        } else if (chrome.browserAction && chrome.browserAction.openPopup) {
              chrome.browserAction.openPopup(() => {
                chrome.storage.local.set({ lastShownDate: todayKey });
              });
          return;
        }
      } catch (e) {
        // fall through to notification fallback
      }
    }

    // Notification fallback (or if autoOpen disabled)
    try {
      const id = 'cookie-daily';
      const title = 'Cookie — Today\'s thought';
      const message = quote.text + (quote.author ? ' — ' + quote.author : '');
      chrome.notifications.create(id, {
        type: 'basic',
        iconUrl: chrome.runtime.getURL('icons/icon128.svg'),
        title,
        message,
        priority: 0
      }, () => {
        // mark shown
        chrome.storage.local.set({ lastShownDate: todayKey });
        // auto-clear after 10s
        setTimeout(() => chrome.notifications.clear(id), 10000);
      });
    } catch (e) {
      // last resort: just set lastShownDate so we don't spam
      chrome.storage.local.set({ lastShownDate: todayKey });
    }
  });
}

function scheduleNextMidnightAlarm() {
  const now = new Date();
  const next = new Date(now);
  next.setHours(24,0,0,0); // next midnight
  const when = next.getTime();
  // create or replace alarm
  chrome.alarms.create('dailyShow', { when });
}

// On startup and install attempt to show once per day and schedule next midnight alarm
chrome.runtime.onStartup.addListener(() => {
  tryShowOnceToday();
  scheduleNextMidnightAlarm();
});

chrome.runtime.onInstalled.addListener((details) => {
  tryShowOnceToday();
  scheduleNextMidnightAlarm();
});

chrome.alarms.onAlarm.addListener((alarm) => {
  if (!alarm || alarm.name !== 'dailyShow') return;
  tryShowOnceToday();
  scheduleNextMidnightAlarm();
});

// Local anonymous counters and export-only stats (no network calls)
// No anonymous stats collection: analytics/export removed.
