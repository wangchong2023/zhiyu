/**
 * [Remote] AI Translator - AI 翻译器
 * 
 * 功能：使用 AI 服务自动翻译选中的文本
 * 类型：远程插件（需要 AI 访问权限）
 */

var stats = {
    totalTranslations: 0,
    languages: {}
};

// 翻译文本
function translateText(text, targetLang) {
    if (!text || !targetLang) return text;
    
    ZhiYu.log('[AI Translator] 翻译到 ' + targetLang + ': ' + text.substring(0, 30) + '...');
    
    // 构建提示词
    var prompt = 'Translate the following text to ' + targetLang + '. Only return the translation, no explanations:\n\n' + text;
    
    // 调用 AI 服务
    var result = ZhiYu.requestAI(prompt);
    
    if (result) {
        stats.totalTranslations++;
        stats.languages[targetLang] = (stats.languages[targetLang] || 0) + 1;
        
        ZhiYu.log('[AI Translator] 翻译完成');
        return result;
    }
    
    ZhiYu.log('[AI Translator] 翻译失败');
    return text;
}

// 检测语言
function detectLanguage(text) {
    var chineseChars = text.match(/[一-龥]/g);
    if (chineseChars && chineseChars.length > text.length * 0.3) {
        return 'zh';
    }
    return 'en';
}

// 自动翻译
function autoTranslate(content) {
    // 查找翻译标记
    var pattern = /<!-- translate:(\w+) -->\n([\s\S]+?)\n<!-- \/translate -->/g;
    var match;
    var modified = content;
    
    while ((match = pattern.exec(content)) !== null) {
        var targetLang = match[1];
        var textToTranslate = match[2];
        
        var translated = translateText(textToTranslate, targetLang);
        
        if (translated !== textToTranslate) {
            var replacement = '<!-- translate:' + targetLang + ' -->\n' + 
                              textToTranslate + '\n\n' +
                              '**译文 (' + targetLang + '):**\n\n' +
                              translated + '\n' +
                              '<!-- /translate -->';
            
            modified = modified.replace(match[0], replacement);
        }
    }
    
    return modified;
}

// 生命周期
function onLoad() {
    ZhiYu.log('[AI Translator] v1.0.0 已加载 - 远程插件（需要 AI）');
    
    ZhiYu.registerCommand('translate-to-en', 'translateToEnglish');
    ZhiYu.registerCommand('translate-to-zh', 'translateToChinese');
    ZhiYu.registerRibbonItem('globe', 'AI 翻译', 'showTranslationStats');
    
    var saved = ZhiYu.loadData('stats');
    if (saved) {
        try {
            stats = JSON.parse(saved);
        } catch (e) {}
    }
}

function onUnload() {
    ZhiYu.saveData('stats', JSON.stringify(stats));
    ZhiYu.log('[AI Translator] 已卸载');
}

function postProcess(content) {
    return autoTranslate(content);
}

function translateToEnglish() {
    ZhiYu.showMessage('使用方法：\n\n<!-- translate:en -->\n你的文本\n<!-- /translate -->');
}

function translateToChinese() {
    ZhiYu.showMessage('使用方法：\n\n<!-- translate:zh -->\nYour text\n<!-- /translate -->');
}

function showTranslationStats() {
    var msg = 'AI 翻译统计\n\n';
    msg += '总翻译次数: ' + stats.totalTranslations + '\n\n';
    msg += '语言分布:\n';
    
    for (var lang in stats.languages) {
        msg += '  ' + lang + ': ' + stats.languages[lang] + ' 次\n';
    }
    
    ZhiYu.showMessage(msg);
}
