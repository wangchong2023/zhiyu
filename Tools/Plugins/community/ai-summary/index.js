var stats = {total: 0};
function onLoad() {
    ZhiYu.log('[AI Summary] v2.1.0 loaded');
    ZhiYu.registerCommand('summarize', 'doSummarize');
    var s = ZhiYu.loadData('stats');
    if (s) { try { stats = JSON.parse(s); } catch(e) {} }
}
function onUnload() {
    ZhiYu.saveData('stats', JSON.stringify(stats));
}
function postProcess(content) {
    ZhiYu.log('[AI Summary] Processing...');
    stats.total++;
    return content;
}
function doSummarize() { ZhiYu.showMessage('Summary: ' + stats.total + ' docs processed'); }
