(function(){
  const AUTO_CLOSE_MS = 10000;
  let closeTimer = null;
  let progressInterval = null;

  async function init(){
    try{
      const resp = await fetch(chrome.runtime.getURL('quotes.json'));
      const quotes = await resp.json();

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
        const q = quotes[idx] || { text: 'No quote available.' };

        renderQuote(q);
        startAutoClose();
      });
    }catch(e){
      const quoteEl = document.getElementById('quote');
      quoteEl.textContent = 'Error loading quotes.';
    }
  }

  function renderQuote(q){
    const quoteEl = document.getElementById('quote');
    const authorEl = document.getElementById('author');
    quoteEl.textContent = q.text;
    authorEl.textContent = q.author ? '— ' + q.author : '';

    const copyBtn = document.getElementById('copy');
    const shareBtn = document.getElementById('share');
    copyBtn.addEventListener('click', async () => {
      try{
        await navigator.clipboard.writeText(q.text + (q.author? ' ' + q.author : ''));
        flashButton(copyBtn, 'Copied');
      }catch(e){
        const ta = document.createElement('textarea');
        ta.value = q.text;
        document.body.appendChild(ta);
        ta.select();
        document.execCommand('copy');
        ta.remove();
        flashButton(copyBtn, 'Copied');
      }
    });

    shareBtn.addEventListener('click', async () => {
      const payload = { text: q.text + (q.author? ' ' + q.author : '') };
      if (navigator.share) {
        try{ await navigator.share(payload); }catch(e){}
      } else {
        try{ await navigator.clipboard.writeText(payload.text); flashButton(shareBtn,'Copied'); }
        catch(e){ flashButton(shareBtn,'Copied'); }
      }
    });

    // autoOpen toggle handling
    const autoOpenEl = document.getElementById('autoOpen');
    if (autoOpenEl) {
      chrome.storage.local.get(['autoOpen'], (res) => {
        const v = (typeof res.autoOpen === 'undefined') ? true : !!res.autoOpen;
        autoOpenEl.checked = v;
      });

      autoOpenEl.addEventListener('change', () => {
        chrome.storage.local.set({ autoOpen: !!autoOpenEl.checked });
      });
    }

    // notify background that popup opened (no-op: anonymous stats disabled)
  }

  function flashButton(btn, text){
    const prev = btn.textContent;
    btn.textContent = text;
    setTimeout(()=> btn.textContent = prev, 1000);
  }

  function startAutoClose(){
    const start = Date.now();
    const bar = document.getElementById('progressBar');
    bar.style.width = '0%';
    progressInterval = setInterval(()=>{
      const elapsed = Date.now() - start;
      const pct = Math.min(100, (elapsed / AUTO_CLOSE_MS) * 100);
      bar.style.width = pct + '%';
      if (elapsed >= AUTO_CLOSE_MS) {
        clearInterval(progressInterval);
      }
    }, 80);

    closeTimer = setTimeout(()=>{
      closePopup();
    }, AUTO_CLOSE_MS);
  }

  function closePopup(){
    if (progressInterval) clearInterval(progressInterval);
    if (closeTimer) clearTimeout(closeTimer);
    document.body.classList.add('closing');
    setTimeout(()=>{
      try{ window.close(); }catch(e){}
    }, 260);
  }

  // manual dismiss
  document.addEventListener('click', (e) => {
    if (e.target && e.target.id === 'dismiss'){
      closePopup();
    }
  });

  // init
  init();
})();
