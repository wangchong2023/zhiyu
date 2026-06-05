/**
 * [Remote] Link Preview - 链接预览
 * 
 * 功能：自动获取 URL 的 meta 信息并生成预览卡片
 * 类型：远程插件（需要网络权限）
 */

var cache = {};

// 获取链接预览
function fetchLinkPreview(url) {
    // 检查缓存
    if (cache[url]) {
        ZhiYu.log('[Link Preview] 使用缓存: ' + url);
        return cache[url];
    }
    
    ZhiYu.log('[Link Preview] 正在获取: ' + url);
    
    // 使用 ZhiYu.fetch 获取网页内容
    var html = ZhiYu.fetch(url);
    if (!html) {
        return null;
    }
    
    // 解析 meta 标签
    var title = extractMeta(html, 'og:title') || extractMeta(html, 'title') || url;
    var description = extractMeta(html, 'og:description') || extractMeta(html, 'description') || '';
    var image = extractMeta(html, 'og:image') || '';
    
    var preview = {
        url: url,
        title: title,
        description: description,
        image: image
    };
    
    // 缓存结果
    cache[url] = preview;
    
    return preview;
}

// 提取 meta 信息
function extractMeta(html, property) {
    var patterns = [
        new RegExp('<meta[^>]+property=["\']' + property + '["\'][^>]+content=["\']([^"\']+)["\']', 'i'),
        new RegExp('<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']' + property + '["\']', 'i'),
        new RegExp('<meta[^>]+name=["\']' + property + '["\'][^>]+content=["\']([^"\']+)["\']', 'i')
    ];
    
    for (var i = 0; i < patterns.length; i++) {
        var match = html.match(patterns[i]);
        if (match && match[1]) {
            return match[1];
        }
    }
    
    return null;
}

// 生成预览卡片
function generatePreviewCard(preview) {
    if (!preview) return '';
    
    var card = '\n\n---\n\n';
    card += '🔗 **链接预览**\n\n';
    card += '**' + preview.title + '**\n\n';
    
    if (preview.description) {
        card += preview.description.substring(0, 150);
        if (preview.description.length > 150) card += '...';
        card += '\n\n';
    }
    
    if (preview.image) {
        card += '![预览图](' + preview.image + ')\n\n';
    }
    
    card += '🌐 [访问链接](' + preview.url + ')\n\n';
    card += '---\n\n';
    
    return card;
}

// 生命周期
function onLoad() {
    ZhiYu.log('[Link Preview] v1.0.0 已加载 - 远程插件（需要网络）');
    
    ZhiYu.registerCommand('preview-link', 'previewLinkCommand');
    ZhiYu.registerRibbonItem('link', '预览链接', 'previewCurrentLink');
    
    var saved = ZhiYu.loadData('cache');
    if (saved) {
        try {
            cache = JSON.parse(saved);
            ZhiYu.log('[Link Preview] 已加载缓存，共 ' + Object.keys(cache).length + ' 条');
        } catch (e) {}
    }
}

function onUnload() {
    ZhiYu.saveData('cache', JSON.stringify(cache));
    ZhiYu.log('[Link Preview] 已卸载，缓存已保存');
}

function postProcess(content) {
    // 在后处理阶段自动为链接添加预览
    var urlPattern = /\bhttps?:\/\/[^\s<>"{}|\\^`\[\]]+/g;
    var urls = content.match(urlPattern);
    
    if (!urls || urls.length === 0) return content;
    
    // 处理第一个链接
    var firstUrl = urls[0];
    if (!content.includes('<!-- link-preview:' + firstUrl + ' -->')) {
        var preview = fetchLinkPreview(firstUrl);
        if (preview) {
            var card = '<!-- link-preview:' + firstUrl + ' -->' + generatePreviewCard(preview);
            content += '\n' + card;
            ZhiYu.log('[Link Preview] 已添加预览卡片');
        }
    }
    
    return content;
}

function previewLinkCommand() {
    ZhiYu.showMessage('请在文档中添加 URL，保存后将自动生成预览卡片');
}

function previewCurrentLink() {
    var cacheSize = Object.keys(cache).length;
    ZhiYu.showMessage('链接预览缓存\n\n已缓存: ' + cacheSize + ' 个链接');
}
