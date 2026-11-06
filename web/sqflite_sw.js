(function(){
  if (typeof self !== 'undefined' && self.sqfliteSwLoaded) return;
  self.sqfliteSwLoaded = true;
  self.addEventListener('message', function(event) {
    const data = event.data || {};
    if (data.type === 'sqflite-ready') {
      self.postMessage({ type: 'sqflite-ready' });
    }
  });
})();
