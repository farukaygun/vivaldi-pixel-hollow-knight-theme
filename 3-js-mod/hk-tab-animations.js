/*
 * Pixel Hollow Knight [Animated] - Vivaldi JS mod
 * Sekme açılış ve kapanış animasyonu: Chrome/Edge gibi açılan sekme büyüyerek,
 * kapanan sekme daralarak gelir/gider; arkasındaki sekmeler onunla birlikte kayar.
 * Vivaldi kapanan sekmeyi DOM'dan anında siler; bu mod silinen sekmenin bir
 * kopyasını aynı yere koyar, daraltıp soldurur ve ardından kaldırır.
 */
(() => {
  const DURATION = 200;
  // Tek seferde bundan fazla sekme eklenir/silinirse (açılış, çalışma alanı değişimi vb.) animasyon yok
  const MAX_BATCH = 3;
  // Sekmenin gerçekten kapandığının (tabs.onRemoved) beklenme süresi
  const CONFIRM_TIMEOUT = 400;
  const MAX_LIFETIME = 1000;

  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const easeOut = (t) => 1 - (1 - t) ** 3;

  const style = document.createElement('style');
  style.textContent = `
    .hk-tab-closing,
    .hk-tab-closing * {
      animation: none !important;
      transition: none !important;
      pointer-events: none !important;
    }
  `;
  document.head.appendChild(style);

  // Şimdiye kadar sekme şeridinde görülen sekmeler; görülmemiş olan yeni açılmıştır
  const knownTabs = new Set();

  // tabs.onRemoved, DOM'dan silinmeden önce ya da sonra gelebilir
  const removedTabs = new Map();
  const waiters = new Map();

  chrome.tabs.onRemoved.addListener((tabId) => {
    const now = performance.now();
    removedTabs.set(tabId, now);
    for (const [id, time] of removedTabs) {
      if (now - time > 2000) removedTabs.delete(id);
    }
    waiters.get(tabId)?.(true);
    waiters.delete(tabId);
  });

  function wasClosed(tabId) {
    if (removedTabs.has(tabId)) return Promise.resolve(true);
    return new Promise((resolve) => {
      waiters.set(tabId, resolve);
      setTimeout(() => {
        if (waiters.get(tabId) === resolve) {
          waiters.delete(tabId);
          resolve(false);
        }
      }, CONFIRM_TIMEOUT);
    });
  }

  function tabIdOf(node) {
    const wrapper = node.matches('.tab-wrapper[id^="tab-"]')
      ? node
      : node.querySelector('.tab-wrapper[id^="tab-"]');
    if (!wrapper) return null;
    const id = Number(wrapper.id.slice(4));
    return Number.isInteger(id) ? id : null;
  }

  function axisOf(strip) {
    const orientation = strip.getAttribute('aria-orientation');
    const horizontal = orientation
      ? orientation === 'horizontal'
      : !strip.closest('#tabs-tabbar-container.left, #tabs-tabbar-container.right');
    return horizontal
      ? { pos: '--PositionX', sizeVar: '--Width', size: 'width', translate: (v) => `${v}px 0` }
      : { pos: '--PositionY', sizeVar: '--Height', size: 'height', translate: (v) => `0 ${v}px` };
  }

  const readPos = (el, axis) => parseFloat(el.style.getPropertyValue(axis.pos)) || 0;
  const readSize = (el, axis) => parseFloat(el.style.getPropertyValue(axis.sizeVar)) || 0;

  // Yan yana iki sekme arasındaki boşluk
  function estimateGap(positions, axis) {
    for (let i = 0; i + 1 < positions.length; i++) {
      const gap = readPos(positions[i + 1], axis) - readPos(positions[i], axis) - readSize(positions[i], axis);
      if (gap >= 0 && gap < 20) return gap;
    }
    return 0;
  }

  /*
   * position: canlandırılacak .tab-position; container: sekmelerin bulunduğu öğe
   * from/to: başlangıç ve bitiş boyutu (kapanış: tam → 0, açılış: 0 → tam)
   * Arkadaki ilk sekme Vivaldi'nin yay animasyonuyla kayıyorsa boyut onu takip eder (follow);
   * Vivaldi sekmeleri yerine atlattıysa onları kendimiz kaydırırız (push);
   * arkada sekme yoksa kendi süremizle canlandırırız (timed).
   */
  function animateTab({ position, container, from, to, fullSize, gap: knownGap, onFinish }) {
    const axis = axisOf(container.closest('.tab-strip'));
    const pos = readPos(position, axis);
    const closing = to < from;

    const after = [...container.querySelectorAll('.tab-position')]
      .filter((el) => el !== position && !el.closest('.hk-tab-closing') && readPos(el, axis) >= pos - 1)
      .sort((a, b) => readPos(a, axis) - readPos(b, axis));
    const neighbor = after[0];
    const neighborPos = neighbor ? readPos(neighbor, axis) : 0;
    const gap = knownGap ?? estimateGap(after, axis);

    // Kapanışta komşu henüz eski yerinde (sekmenin arkasında), açılışta yeni sekmenin üstünde duruyorsa
    // Vivaldi onu yay animasyonuyla kaydıracak demektir
    let mode = 'timed';
    if (neighbor) {
      const neighborWaiting = closing
        ? neighborPos - pos > fullSize / 2
        : neighborPos - pos < fullSize / 2;
      mode = neighborWaiting ? 'follow' : 'push';
    }

    const born = performance.now();
    let start = born;
    let startSize = from;
    let lastNeighborPos = neighborPos;
    let moved = false;
    let done = false;

    function setSize(size) {
      const clamped = Math.max(0, Math.min(fullSize, size));
      position.style.setProperty(axis.size, `${clamped}px`, 'important');
      position.style.opacity = String(clamped / fullSize);
    }

    function setOffset(size) {
      const offset = ((size - to) * (fullSize + gap)) / fullSize;
      after.forEach((el) => el.style.setProperty('translate', axis.translate(offset)));
    }

    function finish() {
      if (done) return;
      done = true;
      position.style.removeProperty(axis.size);
      position.style.removeProperty('opacity');
      if (mode === 'push') after.forEach((el) => el.style.removeProperty('translate'));
      onFinish?.();
    }

    function frame(now) {
      if (done) return;
      if (!position.isConnected || now - born > MAX_LIFETIME) return finish();

      if (mode === 'follow') {
        const current = neighbor.isConnected ? readPos(neighbor, axis) : pos;
        const delta = Math.abs(current - lastNeighborPos);
        lastNeighborPos = current;
        if (delta > 0.5) moved = true;
        const size = current - pos - gap;

        if (Math.abs(size - to) <= 0.5) return finish();
        if ((moved && delta <= 0.5) || (!moved && now - start > 100)) {
          // Komşu durdu (ya da hiç kıpırdamadı): kalan kısmı kendi süremizle bitir
          mode = 'timed';
          start = now;
          startSize = moved ? Math.max(0, Math.min(fullSize, size)) : startSize;
        } else {
          setSize(size);
          return requestAnimationFrame(frame);
        }
      }

      const progress = easeOut(Math.min(1, (now - start) / DURATION));
      const size = startSize + (to - startSize) * progress;
      setSize(size);
      if (mode === 'push') setOffset(size);
      if (progress >= 1) return finish();
      requestAnimationFrame(frame);
    }

    // İlk kare boyanmadan önce başlangıç durumunu uygula
    setSize(from);
    if (mode === 'push') setOffset(from);
    requestAnimationFrame(frame);

    return { cancel: finish };
  }

  function animateClose(record, node, tabId) {
    const ghost = node.cloneNode(true);
    ghost.classList.add('hk-tab-closing');
    ghost.setAttribute('aria-hidden', 'true');
    ghost.removeAttribute('id');
    ghost.querySelectorAll('[id]').forEach((el) => el.removeAttribute('id'));

    const next = record.nextSibling;
    if (next && next.parentNode === record.target) {
      record.target.insertBefore(ghost, next);
    } else {
      record.target.appendChild(ghost);
    }

    const position = ghost.matches('.tab-position') ? ghost : ghost.querySelector('.tab-position');
    if (!position) {
      ghost.remove();
      return;
    }
    // Yerine kayan sekmeler kopyanın üstünde kalsın
    position.style.zIndex = '0';

    const axis = axisOf(record.target.closest('.tab-strip'));
    const fullSize = position.getBoundingClientRect()[axis.size];
    if (fullSize < 1) {
      ghost.remove();
      return;
    }

    // Komşu henüz eski yerindeyse aradaki boşluk kesin olarak bilinir
    const pos = readPos(position, axis);
    const next2 = [...record.target.querySelectorAll('.tab-position')]
      .filter((el) => !el.closest('.hk-tab-closing') && readPos(el, axis) >= pos - 1)
      .sort((a, b) => readPos(a, axis) - readPos(b, axis))[0];
    const exactGap = next2 ? readPos(next2, axis) - pos - fullSize : -1;

    const animation = animateTab({
      position,
      container: record.target,
      from: fullSize,
      to: 0,
      fullSize,
      gap: exactGap >= 0 && exactGap < 20 ? exactGap : undefined,
      onFinish: () => ghost.remove(),
    });

    // Sekme kapanmadıysa (başka pencereye/yığına taşındı vb.) kopyayı kaldır
    wasClosed(tabId).then((closed) => {
      if (!closed) animation.cancel();
    });
  }

  function animateOpen(record, node) {
    const position = node.matches('.tab-position') ? node : node.querySelector('.tab-position');
    if (!position || position.classList.contains('is-pinned')) return;

    const axis = axisOf(record.target.closest('.tab-strip'));
    // Vivaldi yeni sekmeyi 0 genişlikle başlatabilir; o zaman tam boyutu başka bir sekmeden al
    let fullSize = readSize(position, axis);
    if (fullSize < 2) {
      const sibling = [...record.target.querySelectorAll('.tab-position:not(.is-pinned)')]
        .find((el) => el !== position && !el.closest('.hk-tab-closing') && readSize(el, axis) > 1);
      fullSize = sibling ? readSize(sibling, axis) : 0;
    }
    if (fullSize < 2) return;

    animateTab({ position, container: record.target, from: 0, to: fullSize, fullSize });
  }

  const observer = new MutationObserver((records) => {
    const closing = [];
    const opening = [];

    for (const record of records) {
      if (!record.target.closest?.('.tab-strip')) continue;

      for (const node of record.removedNodes) {
        // React'in yer değiştirdiği (yeniden eklenen) düğümler kapanmış sayılmaz
        if (node.nodeType !== Node.ELEMENT_NODE || node.isConnected) continue;
        if (node.classList.contains('hk-tab-closing')) continue;
        const tabId = tabIdOf(node);
        if (tabId !== null) closing.push({ record, node, tabId });
      }

      for (const node of record.addedNodes) {
        if (node.nodeType !== Node.ELEMENT_NODE || node.classList.contains('hk-tab-closing')) continue;
        const tabId = tabIdOf(node);
        if (tabId === null || knownTabs.has(tabId)) continue;
        knownTabs.add(tabId);
        opening.push({ record, node });
      }
    }

    if (reducedMotion.matches) return;
    if (closing.length && closing.length <= MAX_BATCH) {
      for (const { record, node, tabId } of closing) animateClose(record, node, tabId);
    }
    if (opening.length && opening.length <= MAX_BATCH) {
      for (const { record, node } of opening) animateOpen(record, node);
    }
  });

  function start() {
    document.querySelectorAll('.tab-wrapper[id^="tab-"]').forEach((el) => {
      const id = Number(el.id.slice(4));
      if (Number.isInteger(id)) knownTabs.add(id);
    });
    observer.observe(document.body, { childList: true, subtree: true });
  }

  if (document.body) {
    start();
  } else {
    document.addEventListener('DOMContentLoaded', start, { once: true });
  }
})();
