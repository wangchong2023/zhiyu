/**
 * [Local] Word Counter - 字数统计
 * 
 * 功能：实时统计 Markdown 文档的字数、字符数、段落数
 * 类型：本地插件（无需网络）
 */

var stats = {
    totalCounts: 0,
    history: []
};

// 统计文档
function countWords(content) {
    if (!content || typeof content !== 'string') {
        return {
            words: 0,
            characters: 0,
            paragraphs: 0,
            lines: 0
        };
    }
    
    // 移除 Markdown 语法
    var cleaned = content
        .replace(/```[\s\S]*?```/g, '')  // 代码块
        .replace(/`[^`]+`/g, '')          // 行内代码
        .replace(/!\[.*?\]\(.*?\)/g, '')  // 图片
        .replace(/\[.*?\]\(.*?\)/g, '')   // 链接
        .replace(/[#*_~`]/g, '')          // Markdown 符号
        .trim();
    
    // 字数统计（中英文混合）
    var chineseChars = cleaned.match(/[一-龥]/g) || [];
    var englishWords = cleaned.match(/[a-zA-Z]+/g) || [];
    var words = chineseChars.length + englishWords.length;
    
    // 字符统计（不含空格）
    var characters = cleaned.replace(/\s+/g, '').length;
    
    // 段落统计
    var paragraphs = content.split(/\n\n+/).filter(function(p) {
        return p.trim().length > 0;
    }).length;
    
    // 行数统计
    var lines = content.split('\n').length;
    
    return {
        words: words,
        characters: characters,
        paragraphs: paragraphs,
        lines: lines
    };
}

// 生命周期
function onLoad() {
    ZhiYu.log('[Word Counter] v1.0.0 已加载 - 本地插件');
    
    ZhiYu.registerRibbonItem('textformat.123', '字数统计', 'showWordCount');
    ZhiYu.registerCommand('count-words', 'showWordCountCommand');
    
    var saved = ZhiYu.loadData('stats');
    if (saved) {
        try {
            stats = JSON.parse(saved);
        } catch (e) {}
    }
}

function onUnload() {
    ZhiYu.saveData('stats', JSON.stringify(stats));
    ZhiYu.log('[Word Counter] 已卸载');
}

function postProcess(content) {
    // 在后处理阶段统计
    var result = countWords(content);
    stats.totalCounts++;
    stats.history.push({
        time: new Date().toISOString(),
        words: result.words,
        characters: result.characters
    });
    
    // 只保留最近 10 次记录
    if (stats.history.length > 10) {
        stats.history = stats.history.slice(-10);
    }
    
    return content;
}

function showWordCount() {
    var msg = '字数统计\n\n';
    msg += '统计次数: ' + stats.totalCounts + '\n';
    
    if (stats.history.length > 0) {
        var last = stats.history[stats.history.length - 1];
        msg += '\n最近统计:\n';
        msg += '字数: ' + last.words + '\n';
        msg += '字符数: ' + last.characters + '\n';
        msg += '时间: ' + last.time.substring(0, 19).replace('T', ' ');
    }
    
    ZhiYu.showMessage(msg);
}

function showWordCountCommand() {
    showWordCount();
}
