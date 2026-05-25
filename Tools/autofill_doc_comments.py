#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  autofill_doc_comments.py
#  ZhiYu
#
#  系统层级：Tools 开发者辅助工具
#  核心职责：为缺失 /// 中文文档注释的非私有函数自动生成文档注释并写入源文件。
#

import os
import re
import sys

# ─── 中文注释生成规则 ───────────────────────────────────────────

# 动词前缀 → 中文映射
VERB_MAP = {
    "fetch": "获取",
    "get": "获取",
    "load": "加载",
    "save": "保存",
    "store": "存储",
    "delete": "删除",
    "remove": "移除",
    "clear": "清除",
    "reset": "重置",
    "update": "更新",
    "refresh": "刷新",
    "create": "创建",
    "make": "创建",
    "add": "添加",
    "insert": "插入",
    "append": "追加",
    "register": "注册",
    "unregister": "注销",
    "start": "启动",
    "stop": "停止",
    "begin": "开始",
    "end": "结束",
    "pause": "暂停",
    "resume": "恢复",
    "cancel": "取消",
    "apply": "应用",
    "execute": "执行",
    "perform": "执行",
    "run": "运行",
    "handle": "处理",
    "process": "处理",
    "parse": "解析",
    "extract": "提取",
    "generate": "生成",
    "build": "构建",
    "compile": "编译",
    "export": "导出",
    "import": "导入",
    "convert": "转换",
    "format": "格式化",
    "validate": "校验",
    "verify": "验证",
    "check": "检查",
    "search": "搜索",
    "find": "查找",
    "filter": "过滤",
    "sort": "排序",
    "index": "索引",
    "deindex": "取消索引",
    "log": "记录日志",
    "send": "发送",
    "receive": "接收",
    "notify": "通知",
    "observe": "观察",
    "watch": "监听",
    "track": "追踪",
    "monitor": "监控",
    "evaluate": "评估",
    "compute": "计算",
    "calculate": "计算",
    "count": "计数",
    "measure": "测量",
    "scan": "扫描",
    "detect": "检测",
    "recognize": "识别",
    "render": "渲染",
    "draw": "绘制",
    "display": "显示",
    "show": "展示",
    "present": "呈现",
    "dismiss": "关闭",
    "hide": "隐藏",
    "open": "打开",
    "close": "关闭",
    "connect": "连接",
    "disconnect": "断开",
    "sync": "同步",
    "merge": "合并",
    "split": "拆分",
    "copy": "复制",
    "move": "移动",
    "rename": "重命名",
    "replace": "替换",
    "swap": "交换",
    "toggle": "切换",
    "select": "选择",
    "deselect": "取消选择",
    "activate": "激活",
    "deactivate": "停用",
    "enable": "启用",
    "disable": "禁用",
    "configure": "配置",
    "setup": "设置",
    "initialize": "初始化",
    "init": "初始化",
    "prepare": "准备",
    "clean": "清理",
    "purge": "清除",
    "release": "释放",
    "allocate": "分配",
    "schedule": "调度",
    "request": "请求",
    "respond": "响应",
    "resolve": "解析",
    "reject": "拒绝",
    "accept": "接受",
    "approve": "审批",
    "grant": "授予",
    "revoke": "撤销",
    "authenticate": "认证",
    "authorize": "授权",
    "encrypt": "加密",
    "decrypt": "解密",
    "sign": "签名",
    "verify": "验证",
    "seal": "密封",
    "protect": "保护",
    "restore": "恢复",
    "recover": "恢复",
    "backup": "备份",
    "archive": "归档",
    "unarchive": "解档",
    "compress": "压缩",
    "decompress": "解压",
    "encode": "编码",
    "decode": "解码",
    "serialize": "序列化",
    "deserialize": "反序列化",
    "describe": "描述",
    "debug": "调试",
    "test": "测试",
    "mock": "模拟",
    "stub": "桩实现",
    "prefetch": "预取",
    "preload": "预加载",
    "cache": "缓存",
    "invalidate": "使失效",
    "evict": "驱逐",
    "pin": "固定",
    "unpin": "取消固定",
    "bookmark": "添加书签",
    "favorite": "收藏",
    "pin": "置顶",
    "share": "分享",
    "collaborate": "协作",
    "publish": "发布",
    "subscribe": "订阅",
    "unsubscribe": "退订",
    "join": "加入",
    "leave": "离开",
    "invite": "邀请",
    "block": "阻塞",
    "intercept": "拦截",
    "retry": "重试",
    "rollback": "回滚",
    "revert": "还原",
    "undo": "撤销",
    "redo": "重做",
    "commit": "提交",
    "push": "推送",
    "pull": "拉取",
    "fetch": "拉取",
    "download": "下载",
    "upload": "上传",
    "install": "安装",
    "uninstall": "卸载",
    "migrate": "迁移",
    "upgrade": "升级",
    "downgrade": "降级",
    "transform": "变换",
    "animate": "动画",
    "transition": "转场",
    "navigate": "导航",
    "route": "路由",
    "redirect": "重定向",
    "deepLink": "深度链接",
    "crawl": "抓取",
    "scrape": "爬取",
    "ingest": "导入摄取",
    "digest": "消化",
    "enrich": "增强",
    "synthesize": "合成",
    "summarize": "摘要",
    "translate": "翻译",
    "localize": "本地化",
    "customize": "自定义",
    "personalize": "个性化",
    "optimize": "优化",
    "refactor": "重构",
    "simplify": "简化",
    "normalize": "规范化",
    "sanitize": "清洗",
    "escape": "转义",
    "quote": "引用",
    "wrap": "包装",
    "unwrap": "解包",
    "flatten": "展平",
    "group": "分组",
    "chunk": "分块",
    "paginate": "分页",
    "traverse": "遍历",
    "enumerate": "枚举",
    "reduce": "归约",
    "map": "映射",
    "filter": "过滤",
    "collect": "收集",
    "accumulate": "累积",
    "aggregate": "聚合",
    "compose": "组合",
    "decompose": "分解",
    "assemble": "装配",
    "disassemble": "拆解",
    "attach": "附加",
    "detach": "分离",
    "bind": "绑定",
    "unbind": "解绑",
    "link": "链接",
    "unlink": "断开链接",
    "associate": "关联",
    "disassociate": "取消关联",
    "relate": "关联",
    "correlate": "关联",
    "match": "匹配",
    "compare": "比较",
    "diff": "对比差异",
    "equal": "判等",
    "hash": "哈希",
    "randomize": "随机化",
    "shuffle": "打乱",
    "sample": "采样",
    "pick": "选取",
    "choose": "选择",
    "deduplicate": "去重",
    "unique": "去重",
    "merge": "合并",
    "compact": "紧凑化",
    "flatten": "展平",
    "nest": "嵌套",
    "clip": "裁剪",
    "crop": "裁剪",
    "resize": "调整大小",
    "scale": "缩放",
    "rotate": "旋转",
    "flip": "翻转",
    "mirror": "镜像",
    "tint": "着色",
    "blend": "混合",
    "fade": "渐变",
    "highlight": "高亮",
    "dim": "变暗",
    "blur": "模糊",
    "sharpen": "锐化",
    "mask": "遮罩",
    "overlay": "叠加",
    "underline": "下划线",
    "strikethrough": "删除线",
}

# 特殊函数名模式 → 固定注释
SPECIAL_PATTERNS = {
    # SwiftUI / 协议委托
    r"^body$": "视图主体",
    r"^content$": "内容视图",
    r"^preview$": "预览",
    r"^navigationTitle$": "导航标题",
    r"^onAppear$": "视图出现回调",
    r"^onDisappear$": "视图消失回调",
    # 本地化
    r"^tr$": "本地化翻译",
    r"^trf$": "本地化格式化翻译",
    # 生命周期
    r"^viewDidLoad$": "视图加载完成",
    r"^viewWillAppear$": "视图即将显示",
    r"^viewDidAppear$": "视图已显示",
    r"^viewWillDisappear$": "视图即将消失",
    r"^viewDidDisappear$": "视图已消失",
    # Equatable/Hashable
    r"^equal[s]?$": "判等比较",
    r"^hash$": "计算哈希值",
    r"^hashValue$": "哈希值",
    # Codable
    r"^encode$": "编码",
    r"^decode$": "解码",
    # CustomStringConvertible
    r"^description$": "描述信息",
    # Init
    r"^init$": "初始化",
    # Deinit
    r"^deinit$": "析构",
    # Subscriber
    r"^receive$": "接收订阅值",
    # Iterator
    r"^next$": "获取下一个元素",
}

# 后缀推断
SUFFIX_MAP = {
    "View": "视图",
    "Store": "数据仓库",
    "Service": "服务",
    "Manager": "管理器",
    "Repository": "数据仓库",
    "Coordinator": "协调器",
    "Provider": "提供者",
    "Builder": "构建器",
    "Factory": "工厂",
    "Handler": "处理器",
    "Delegate": "代理",
    "Adapter": "适配器",
    "Plugin": "插件",
    "Module": "模块",
    "Component": "组件",
    "Controller": "控制器",
    "Presenter": "呈现器",
    "Router": "路由器",
    "Gateway": "网关",
    "Client": "客户端",
    "Server": "服务端",
    "Cache": "缓存",
    "Index": "索引",
    "Token": "令牌",
    "Key": "密钥",
    "URL": "链接",
    "Path": "路径",
    "File": "文件",
    "Data": "数据",
    "Record": "记录",
    "Entry": "条目",
    "Item": "项目",
    "Page": "页面",
    "Note": "笔记",
    "Tag": "标签",
    "Task": "任务",
    "Event": "事件",
    "Message": "消息",
    "Notification": "通知",
    "Request": "请求",
    "Response": "响应",
    "Result": "结果",
    "Error": "错误",
    "Warning": "警告",
    "Config": "配置",
    "Setting": "设置",
    "Option": "选项",
    "Preference": "偏好",
    "Permission": "权限",
    "Policy": "策略",
    "Rule": "规则",
    "Filter": "过滤器",
    "Sort": "排序规则",
    "Format": "格式",
    "Template": "模板",
    "Layout": "布局",
    "Style": "样式",
    "Theme": "主题",
    "Color": "颜色",
    "Font": "字体",
    "Icon": "图标",
    "Image": "图片",
    "Thumbnail": "缩略图",
    "Preview": "预览",
    "Status": "状态",
    "Progress": "进度",
    "Score": "分数",
    "Count": "计数",
    "Size": "大小",
    "Length": "长度",
    "Width": "宽度",
    "Height": "高度",
    "Position": "位置",
    "Frame": "帧",
    "Bounds": "边界",
    "Rect": "矩形",
    "Point": "点",
    "Vector": "向量",
    "Matrix": "矩阵",
    "Graph": "图谱",
    "Node": "节点",
    "Edge": "边",
    "Link": "链接",
    "Connection": "连接",
}


def is_private_func(line):
    """判断是否为私有函数"""
    return "private func" in line or "fileprivate func" in line


def is_func_declaration(line):
    """判断是否为函数声明"""
    stripped = line.strip()
    if stripped.startswith("//") or stripped.startswith("/*") or stripped.startswith("*"):
        return False
    return "func " in line


def has_existing_doc_comment(lines, func_idx):
    """检查函数前是否已有 /// 文档注释"""
    check_idx = func_idx - 1
    while check_idx >= 0:
        prev_line = lines[check_idx].strip()
        if prev_line == "":
            check_idx -= 1
            continue
        elif prev_line.startswith("///"):
            return True
        elif prev_line.startswith("//") or prev_line.endswith("*/"):
            check_idx -= 1
            continue
        else:
            return False
    return False


def extract_func_name(line):
    """从函数声明行提取函数名"""
    func_pattern = re.compile(r'(?:public\s+|internal\s+|open\s+|@objc\s+|@MainActor\s+|nonisolated\s+|static\s+|override\s+|@ViewBuilder\s+|@Binding\s+|@discardableResult\s+|async\s+|throws\s+|@\w+\s+)*func\s+([a-zA-Z0-9_]+)\b')
    match = func_pattern.search(line)
    return match.group(1) if match else None


def extract_params(line):
    """从函数签名提取参数名列表"""
    # Match content between ( and ) after func name
    paren_match = re.search(r'func\s+\w+\s*(?:<[^>]*>)?\s*\(([^)]*)\)', line)
    if not paren_match:
        return []
    params_str = paren_match.group(1)
    params = []
    for param in params_str.split(','):
        param = param.strip()
        if not param or param == '':
            continue
        # Extract external parameter name (the one caller uses)
        # Patterns: "label name: Type", "_ name: Type", "name: Type"
        pm = re.match(r'(?:_\s+)?(\w+)\s*:', param)
        if pm:
            pname = pm.group(1)
            if pname not in ('_ ', '_'):
                params.append(pname)
    return params


def extract_return_type(line):
    """从函数签名提取返回类型"""
    ret_match = re.search(r'\)\s*(?:async\s+)?(?:throws\s+)?->\s*(.+?)\s*\{', line)
    if ret_match:
        ret = ret_match.group(1).strip()
        return ret
    return None


def camel_to_words(name):
    """驼峰命名转分词列表"""
    # Handle acronyms: URL → URL, PDF → PDF, etc.
    words = re.sub(r'([a-z])([A-Z])', r'\1 \2', name)
    words = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1 \2', words)
    return words.split()


def infer_param_label(param_name):
    """根据参数名推断中文标签"""
    words = camel_to_words(param_name)
    labels = []
    for w in words:
        lower = w.lower()
        if lower in VERB_MAP:
            labels.append(VERB_MAP[lower])
        elif lower in SUFFIX_MAP:
            labels.append(SUFFIX_MAP[lower])
        else:
            # Keep as-is for proper nouns or unknown words
            labels.append(w)
    return ''.join(labels) if labels else param_name


def generate_comment(func_name, params, return_type, signature, file_path):
    """根据函数名、参数、返回类型生成中文 /// 文档注释"""

    # 1. 检查特殊模式
    for pattern, comment in SPECIAL_PATTERNS.items():
        if re.match(pattern, func_name):
            doc = comment
            # Add params
            if params:
                param_lines = []
                for p in params:
                    param_lines.append(f"/// - Parameter {p}: {infer_param_label(p)}")
                doc += "\n" + "\n".join(param_lines)
            if return_type and return_type != 'Void':
                doc += f"\n/// - Returns: 返回值"
            return doc

    # 2. 检查是否是 delegate/数据源方法 (含 session/delegate/view 等)
    delegate_patterns = [
        r'session\(',
        r'webView\(',
        r'tableView\(',
        r'collectionView\(',
        r'navigationController\(',
        r'sessionDidBecomeInactive',
        r'sessionDidDeactivate',
        r'sessionWasLost',
        r'didReceive',
        r'didFinish',
        r'didFail',
        r'didChange',
        r'didUpdate',
        r'didSelect',
        r'didDeselect',
        r'didAdd',
        r'didRemove',
        r'didComplete',
        r'didCancel',
        r'didError',
    ]
    for dp in delegate_patterns:
        if re.search(dp, signature):
            # 生成委托方法注释
            words = camel_to_words(func_name)
            doc = ''.join([VERB_MAP.get(w.lower(), w) for w in words]) + "回调"
            if params:
                param_lines = [f"/// - Parameter {p}: {infer_param_label(p)}" for p in params]
                doc += "\n" + "\n".join(param_lines)
            return doc

    # 3. 基于函数名推断
    words = camel_to_words(func_name)

    # 尝试匹配动词前缀
    verb = None
    verb_cn = None
    rest_words = words

    if words:
        first_lower = words[0].lower()
        if first_lower in VERB_MAP:
            verb = first_lower
            verb_cn = VERB_MAP[first_lower]
            rest_words = words[1:]
        # Try first two words as verb (e.g., "set up", "log out")
        elif len(words) >= 2:
            two_word = (words[0] + words[1]).lower()
            if two_word in VERB_MAP:
                verb = two_word
                verb_cn = VERB_MAP[two_word]
                rest_words = words[2:]

    if verb_cn and rest_words:
        # 有动词 + 宾语
        object_parts = []
        for w in rest_words:
            lower = w.lower()
            if lower in SUFFIX_MAP:
                object_parts.append(SUFFIX_MAP[lower])
            elif lower in VERB_MAP:
                object_parts.append(VERB_MAP[lower])
            else:
                object_parts.append(w)
        doc = verb_cn + ''.join(object_parts)
    elif verb_cn:
        # 仅有动词
        doc = verb_cn
    elif rest_words:
        # 无动词前缀，用名词拼接
        parts = []
        for w in rest_words:
            lower = w.lower()
            if lower in SUFFIX_MAP:
                parts.append(SUFFIX_MAP[lower])
            elif lower in VERB_MAP:
                parts.append(VERB_MAP[lower])
            else:
                parts.append(w)
        doc = ''.join(parts)
    else:
        doc = func_name

    # 4. 添加参数说明
    if params:
        param_lines = []
        for p in params:
            param_lines.append(f"/// - Parameter {p}: {infer_param_label(p)}")
        doc += "\n" + "\n".join(param_lines)

    # 5. 添加返回值说明
    if return_type and return_type not in ('Void', '()', 'some View', 'some View '):
        if 'some View' in return_type:
            doc += f"\n/// - Returns: 视图"
        elif return_type.startswith('['):
            doc += f"\n/// - Returns: 列表"
        elif return_type == 'Bool':
            doc += f"\n/// - Returns: 是否成功"
        elif return_type == 'String':
            doc += f"\n/// - Returns: 字符串"
        elif return_type == 'Int' or return_type == 'Double' or return_type == 'Float':
            doc += f"\n/// - Returns: 数值"
        elif return_type == 'URL':
            doc += f"\n/// - Returns: 链接"
        elif return_type == 'Data':
            doc += f"\n/// - Returns: 数据"
        elif return_type == 'Date':
            doc += f"\n/// - Returns: 日期"
        elif return_type == 'UUID':
            doc += f"\n/// - Returns: 唯一标识"
        elif '?' in return_type:
            doc += f"\n/// - Returns: 可选值"
        else:
            doc += f"\n/// - Returns: 返回值"

    return doc


def get_indent(lines, func_idx):
    """获取函数行的缩进"""
    line = lines[func_idx]
    indent_match = re.match(r'^(\s*)', line)
    return indent_match.group(1) if indent_match else ""


def autofill_file(file_path):
    """为单个文件中缺失 /// 注释的函数自动填充"""
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    modified = False
    insertions = []  # (line_idx, text_to_insert)

    for idx, line in enumerate(lines):
        if is_func_declaration(line) and not is_private_func(line):
            # Check for existing doc comment
            if has_existing_doc_comment(lines, idx):
                continue

            func_name = extract_func_name(line)
            if func_name is None:
                continue

            params = extract_params(line)
            return_type = extract_return_type(line)

            # Generate the comment
            comment_text = generate_comment(func_name, params, return_type, line.strip(), file_path)
            indent = get_indent(lines, idx)

            # Build insertion lines — each line must have `/// ` prefix
            comment_lines = []
            for cl in comment_text.split('\n'):
                comment_lines.append(f"{indent}/// {cl}\n")

            # Add blank line separator before /// if previous line is not blank or ///
            prev_line = lines[idx - 1].strip() if idx > 0 else ""
            if prev_line and not prev_line.startswith("///") and not prev_line.startswith("//"):
                comment_lines.insert(0, "\n")

            insertions.append((idx, comment_lines))
            modified = True

    if modified:
        # Apply insertions in reverse order to preserve indices
        for idx, comment_lines in reversed(insertions):
            for i, cl in enumerate(comment_lines):
                lines.insert(idx + i, cl)

        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)

    return modified, len(insertions)


def main():
    workspace = "/Users/constantine/Documents/work/code/projects/ZhiYu"
    sources_dir = os.path.join(workspace, "Sources")

    total_files = 0
    total_inserted = 0

    for root, dirs, files in os.walk(sources_dir):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for file in files:
            if file.endswith('.swift'):
                file_path = os.path.join(root, file)
                modified, count = autofill_file(file_path)
                if modified:
                    total_files += 1
                    total_inserted += count
                    relative = os.path.relpath(file_path, workspace)
                    print(f"  ✏️  {relative}: +{count} 条注释")

    print(f"\n✅ 完成！共修改 {total_files} 个文件，插入 {total_inserted} 条文档注释。")


if __name__ == "__main__":
    main()
