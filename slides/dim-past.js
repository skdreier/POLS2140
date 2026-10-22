// Slides tagged {.dim-past}: each revealed fragment turns grey once the
// next one appears (the current one stays dark). Load once per deck with
//   ```{=html}
//   <script src="dim-past.js"></script>
//   ```
(function () {
  if (window.__dimPastLoaded) return;
  window.__dimPastLoaded = true;
  function init() {
    if (!(window.Reveal && Reveal.isReady && Reveal.isReady())) { setTimeout(init, 100); return; }
    function apply() {
      // An always-visible lead block (.dim-lead) greys as soon as the slide's first fragment shows.
      document.querySelectorAll('section.dim-past .dim-lead').forEach(function (d) {
        var on = !!d.closest('section').querySelector('.fragment.visible');
        [d].concat(Array.prototype.slice.call(d.querySelectorAll('*'))).forEach(function (el) {
          if (on) el.style.setProperty('color', '#999999', 'important');
          else el.style.removeProperty('color');
        });
      });
      document.querySelectorAll('section.dim-past .fragment').forEach(function (f) {
        // A line stays dark while it, or a click-step nested inside it (e.g. an answer on the same line), is current.
        var past = f.classList.contains('visible') && !f.classList.contains('current-fragment')
                   && !f.querySelector('.fragment.current-fragment');
        f.style.color = past ? '#999999' : (f.classList.contains('visible') ? '#1a1a1a' : '');
        f.querySelectorAll('.hl, .hl2, .gr1, a').forEach(function (s) {
          if (past) s.style.setProperty('color', '#999999', 'important');
          else s.style.removeProperty('color');
        });
      });
    }
    Reveal.on('fragmentshown', apply);
    Reveal.on('fragmenthidden', apply);
    Reveal.on('slidechanged', apply);
    apply();
  }
  init();
})();
