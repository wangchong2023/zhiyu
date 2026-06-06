var stats = {total: 0};
function onLoad() {
    ZhiYu.log('[Code Highlighter] v1.5.2 loaded');
    var s = ZhiYu.loadData('stats');
    if (s) { try { stats = JSON.parse(s); } catch(e) {} }
}
function onUnload() {
    ZhiYu.saveData('stats', JSON.stringify(stats));
}
function preProcess(content) {
    ZhiYu.log('[Code Highlighter] Processing...');
    stats.total++;
    return content;
}
