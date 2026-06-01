#!/usr/bin/env python3
import os
import re
import sys
import subprocess

# 翻译字典：将常见中文模式映射为英文
TRANSLATIONS = {
    "任务失败且已达最大重试次数": "Task failed and reached max retries",
    "即将进行第": "About to perform retry",
    "次重试": "retry",
    "等待": "waiting",
    "秒": "seconds",
    "数据库初始化严重失败": "Critical database initialization failure",
    "数据库初始化失败": "Database initialization failed",
    "正在重试": "Retrying",
    "已达最大重试次数": "Reached maximum retries",
    "处理器": "Processor",
    "执行完毕": "Execution completed",
    "正在同步": "Syncing",
    "同步成功": "Sync successful",
    "同步失败": "Sync failed",
    "权限不足": "Permission denied",
    "非法访问": "Illegal access",
    "认证成功": "Auth successful",
    "认证失败": "Auth failed",
    "页面": "Page",
    "标签": "Tags",
    "模型": "Model",
    "商店": "Store",
    "下载": "Download",
    "暂停": "Pause",
    "恢复": "Resume",
    "取消": "Cancel",
    "验证": "Verify",
    "指纹": "Fingerprint",
    "校验": "Verification",
    "耗时": "duration",
    "科学": "Science",
    "物理": "Physics",
    "数学": "Math",
    "艺术": "Art",
    "文学": "Literature",
    "历史": "History",
    "自然": "Nature",
    "代码": "Code",
    "编程": "Programming",
    "正确答案": "Correct Answer",
    "答案": "Answer",
    "解释": "Explanation",
    "内容": "Content",
    "待扩充内容": "Content to be expanded",
    "问题": "Question",
    "关联概念": "Related Concepts",
    "依赖于": "Depends on",
    "核心": "Core",
    "对接": "Integrates with",
    "基础": "Foundation",
    "正在初始化": "Initializing",
    "正在加载": "Loading",
    "加载成功": "Loaded successfully",
    "加载失败": "Failed to load",
    "执行失败": "Execution failed",
    "任务失败": "Task failed",
    "处理任务": "Processing task",
    "正在处理": "Processing",
    "创建成功": "Created successfully",
    "写入失败": "Write failed",
    "存储失败": "Storage failed",
    "删除失败": "Delete failed",
    "已创建": "Created",
    "已挂载": "Mounted",
    "插件": "Plugin",
    "数据库": "Database",
    "笔记本": "Notebook",
    "由于": "due to",
    "错误": "Error",
    "严重错误": "Critical error",
    "成功": "successfully",
    "失败": "failed",
    "尝试调用": "Attempting to call",
    "物理隔离": "Physically isolated",
    "流程": "process",
    "类型": "type",
    "开始": "Starting",
    "完成": "Completed",
    "统计": "Statistics",
    "计算完成": "Calculation completed",
    "链接": "links",
    "数据清理": "Data cleanup",
    "解析失败": "Parsing failed",
    "密码登录": "Password login",
    "验证码": "Verification code",
    "发送": "Send",
    "统一认证": "Unified auth",
    "不支持的": "Unsupported",
    "第三方登录策略": "third-party auth strategy",
    "存储 Token": "Storing Token",
    "忽略": "Ignoring",
    "强行通过": "Forcing bypass",
    "未配置": "not configured",
    "正在导入文件": "Importing file",
    "无法读取内容": "Unable to read content",
    "自动备份": "Auto backup",
    "恢复备份": "Restore backup",
    "未命名网页": "Untitled Web Page",
    "压测": "Stress test",
    "文档": "documents",
    "已注入": "Injected",
    "总耗时": "Total time",
    "平均速度": "Average speed",
    "搜索性能": "Search performance",
    "响应延迟": "Latency",
    "召回数量": "Results count",
    "检索延迟超过": "Search latency exceeded",
    "红线": "threshold",
    "数据洞察": "Data Insight",
    "图片语义": "Image Semantics",
    "你是一个": "You are a",
    "专业": "professional",
    "专家": "expert",
    "请分析": "Please analyze",
    "并提供": "and provide",
    "根据": "based on",
    "推测": "infer",
    "作用": "role",
    "监测到": "Detected",
    "切换": "switch",
    "清空内存并重载": "clearing memory and reloading",
    "识别到新": "Detected new",
    "自动注入": "auto injecting",
    "冷启动演示数据": "cold start demo data",
    "安全拦截": "Security interception",
    "尝试修改": "attempting to modify",
    "权限": "permission",
    "已被物理隔离": "has been physically isolated",
    "强制回收内存资源": "forcing memory recovery",
    "处于封禁黑名单中": "is blacklisted",
    "拒绝加载": "loading rejected",
    "检测到": "Detected",
    "已启用": "enabled",
    "正在监听事件": "Listening for event",
    "调用过于频繁": "called too frequently",
    "已自动降级": "automatically downgraded",
    "执行超时": "execution timed out",
    "已被物理挂起": "has been physically suspended",
    "执行异常": "execution anomaly",
    "已自动跳过": "automatically skipped",
}

# 标点符号映射
PUNCTUATION = {
    "：": ": ",
    "，": ", ",
    "。": ". ",
    "（": " (",
    "）": ") ",
    "｜": " | ",
}

# 需要物理移除或替换的 Emoji/特殊字符
EMOJI_MAP = {
    "❌": "[Error]",
    "⚠️": "[Warning]",
    "✅": "[Success]",
    "🚀": "[Start]",
    "🔄": "[Sync]",
    "🏗️": "[Arch]",
    "🏛️": "[App]",
    "🎬": "[Init]",
    "📦": "[Package]",
    "🌍": "[Global]",
    "🌱": "[Seed]",
    "🗑️": "[Delete]",
    "🔌": "[Plugin]",
    "🗣️": "[Speech]",
    "🔍": "[Search]",
    "ℹ️": "[Info]",
    "⏳": "[Wait]",
    "📝": "[Log]",
    "📊": "[Stats]",
    "🛡️": "[Guard]",
    "🚫": "[Deny]",
    "🔴": "[Stop]",
    "📓": "[Note]",
    "📚": "[Library]",
    "💡": "[Idea]",
    "🧠": "[Brain]",
    "✍️": "[Write]",
    "🎨": "[Art]",
    "🌟": "[Star]",
    "🛠️": "[Tools]",
    "📅": "[Date]",
    "🎯": "[Target]",
    "🔥": "[Crit]",
    "🌈": "[Rainbow]",
    "🧩": "[Puzzle]",
    "｜": " | ",
    "—": " - ",
    "©": "(c)",
}

def translate_message(msg):
    # 1. 替换 Emoji 为英文标识
    for emoji, tag in EMOJI_MAP.items():
        msg = msg.replace(emoji, tag)
    
    # 2. 替换标点
    for zh, en in PUNCTUATION.items():
        msg = msg.replace(zh, en)
        
    # 3. 替换词汇
    # 按长度降序排列，防止子串误伤
    sorted_keys = sorted(TRANSLATIONS.keys(), key=len, reverse=True)
    for zh in sorted_keys:
        msg = msg.replace(zh, TRANSLATIONS[zh])
    
    # 4. 彻底移除任何非 ASCII
    msg = "".join([c if ord(c) < 128 else " " for c in msg])
    
    # 5. 清理多余空格
    msg = re.sub(r'\s+', ' ', msg).strip()
    return msg

def fix_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 查找所有字符串字面量
    # 匹配模式： " ... [非ASCII] ... "
    def replacer(match):
        full_string = match.group(0)
        inner_content = match.group(1)
        
        # 如果包含非 ASCII
        if any(ord(c) > 127 for c in inner_content):
            # 翻译内容
            translated = translate_message(inner_content)
            # 如果翻译后变空了，给个占位符
            if not translated.strip():
                translated = "Non-ASCII Content"
            return f'"{translated}"'
        return full_string

    new_content = re.sub(r'"([^"\\]*(?:\\.[^"\\]*)*)"', replacer, content)
    
    # 同时将 print(...) 转换为 Logger.shared.info(...)
    new_content = re.sub(r'print\("([^"]*)"\)', r'Logger.shared.info("\1")', new_content)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

def main():
    # 获取审计报告中的文件列表
    result = subprocess.run(['./env/venv/bin/python3', 'Tools/check_localization.py'], capture_output=True, text=True)
    
    files_to_fix = set()
    for line in result.stdout.split('\n'):
        if line.startswith('📂'):
            path = line.replace('📂', '').strip()
            if os.path.exists(path):
                files_to_fix.add(path)
    
    count = 0
    for file_path in files_to_fix:
        if fix_file(file_path):
            print(f"✅ Fixed: {file_path}")
            count += 1
    
    print(f"\nTotal files patched: {count}")

if __name__ == '__main__':
    main()
