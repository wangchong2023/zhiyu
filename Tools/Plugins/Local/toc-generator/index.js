/**
 * [Local] TOC Generator - 目录生成器
 * 
 * 功能：自动扫描 Markdown 文档中的所有标题并生成目录
 * 类型：本地插件（无需网络）
 */

var stats = {
    totalGenerated: 0,
    lastGeneratedTime: null
};

// 生成目录
function generateTOC(content) {
    if (!content || typeof content !== 'string') return content;
    
    var lines = content.split('\n');
    var toc = [];
    var hasHeadings = false;
    
    // 扫描所有标题
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        var match = line.match(/^(#{1,6})\s+(.+)$/);
        
        if (match) {
            hasHeadings = true;
            var level = match[1].length;
            var title = match[2];
            var indent = '  '.repeat(level - 1);
            var slug = title.toLowerCase().replace(/[^\w一-龥]+/g, '-');
            
            toc.push(indent + '- [' + title + '](#' + slug + ')');
        }
    }
    
    if (!hasHeadings) {
        ZhiYu.log('[TOC] 未发现标题，无需生成目录');
        return content;
    }
    
    // 检查是否已存在目录
    if (content.indexOf('<!-- TOC -->') > -1) {
        // 更新现有目录
        var startIdx = content.indexOf('<!-- TOC -->');
        var endIdx = content.indexOf('<!-- /TOC -->', startIdx);
        
        if (endIdx > -1) {
            var before = content.substring(0, startIdx);
            var after = content.substring(endIdx + 13);
            var newTOC = '<!-- TOC -->\n\n' + toc.join('\n') + '\n\n<!-- /TOC -->';
            content = before + newTOC + after;
            ZhiYu.log('[TOC] 已更新目录，共 ' + toc.length + ' 个标题');
        }
    } else {
        // 插入新目录（在第一个标题之前）
        var firstHeadingIdx = -1;
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].match(/^#{1,6}\s+/)) {
                firstHeadingIdx = i;
                break;
            }
        }
        
        if (firstHeadingIdx > -1) {
            var newTOC = '<!-- TOC -->\n\n' + toc.join('\n') + '\n\n<!-- /TOC -->\n\n';
            lines.splice(firstHeadingIdx, 0, newTOC);
            content = lines.join('\n');
            ZhiYu.log('[TOC] 已生成目录，共 ' + toc.length + ' 个标题');
        }
    }
    
    stats.totalGenerated++;
    stats.lastGeneratedTime = new Date().toISOString();
    
    return content;
}

// 生命周期
function onLoad() {
    ZhiYu.log('[TOC Generator] v1.0.0 已加载 - 本地插件');
    
    ZhiYu.registerCommand('generate-toc', 'generateTOCCommand');
    ZhiYu.registerRibbonItem('list.bullet.indent', '生成目录', 'showTOCStats');
    
    var saved = ZhiYu.loadData('stats');
    if (saved) {
        try {
            stats = JSON.parse(saved);
        } catch (e) {}
    }
}

function onUnload() {
    ZhiYu.saveData('stats', JSON.stringify(stats));
    ZhiYu.log('[TOC Generator] 已卸载');
}

function preProcess(content) {
    return generateTOC(content);
}

function postProcess(content) {
    return content;
}

function generateTOCCommand() {
    ZhiYu.log('[TOC] 手动触发目录生成');
}

function showTOCStats() {
    var msg = '目录生成统计\n\n';
    msg += '总生成次数: ' + stats.totalGenerated + '\n';
    msg += '最后生成: ' + (stats.lastGeneratedTime || '未生成');
    ZhiYu.showMessage(msg);
}
