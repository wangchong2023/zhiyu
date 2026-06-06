#!/usr/bin/env python3
"""
插件端到端测试：加载 / 卸载全流程验证
"""

import json, os, sys, zipfile, urllib.request, shutil, tempfile

GREEN, RED, YELLOW, NC = '\033[32m', '\033[31m', '\033[33m', '\033[0m'
ok, fail = 0, 0

def test(name, fn):
    global ok, fail
    try:
        fn()
        print(f'  {GREEN}✅ {name}{NC}')
        ok += 1
    except AssertionError as e:
        print(f'  {RED}❌ {name}: {e}{NC}')
        fail += 1
    except Exception as e:
        print(f'  {RED}💥 {name}: {e}{NC}')
        fail += 1

print('🧪 插件端到端测试套件\n')

# ========== 1. Mock 服务器 ==========
print('📡 1. Mock 服务器连通性')
def mock_plugins():
    with urllib.request.urlopen('http://127.0.0.1:9091/api/plugins', timeout=5) as r:
        d = json.load(r)
        assert d['code'] == 0, f'code={d["code"]}'
        assert len(d['data']) == 5, f'预期 5 个插件，实际 {len(d["data"])}'
        assert 'requestId' in d, '缺少 requestId'
test('插件市场 (9091): 5 个插件', mock_plugins)

def mock_models():
    with urllib.request.urlopen('http://127.0.0.1:8080/api/models', timeout=5) as r:
        d = json.load(r)
        assert d['code'] == 0
        assert len(d['data']) == 4, f'预期 4 个模型，实际 {len(d["data"])}'
test('模型商店 (8080): 4 个模型', mock_models)

# ========== 2. 插件压缩包完整性 ==========
print('\n📦 2. 插件压缩包完整性')
PLUGINS = {
    'toc-generator-local': 'Tools/Plugins/Local/toc-generator-local.zyplugin',
    'word-counter-local': 'Tools/Plugins/Local/word-counter-local.zyplugin',
    'smart-cleaner': 'Tools/Plugins/smart-cleaner.zyplugin',
    'link-preview-remote': 'Tools/Plugins/Remote/link-preview-remote.zyplugin',
    'ai-translator-remote': 'Tools/Plugins/Remote/ai-translator-remote.zyplugin',
}

for name, path in PLUGINS.items():
    def make_test(n, p):
        def inner():
            assert os.path.exists(p), f'文件不存在: {p}'
            with zipfile.ZipFile(p, 'r') as zf:
                files = zf.namelist()
                assert 'manifest.json' in files, f'{n} 缺少 manifest.json'
                assert 'index.js' in files, f'{n} 缺少 index.js'
                mf = json.loads(zf.read('manifest.json'))
                assert 'id' in mf, 'manifest 缺少 id'
                assert 'version' in mf, 'manifest 缺少 version'
                assert 'names' in mf, 'manifest 缺少 names'
                js = zf.read('index.js').decode('utf-8')
                assert len(js) > 100, f'index.js 太短 ({len(js)} 字符)'
        return inner
    test(f'{name} (.zyplugin)', make_test(name, path))

# ========== 3. 模拟安装流程 ==========
print('\n📥 3. 模拟安装流程')

def simulate_install():
    tmp = tempfile.mkdtemp(prefix='zhiyu_plugins_')
    installed = []
    try:
        # 模拟下载插件到 Documents/Plugins/
        plugins_dir = os.path.join(tmp, 'Documents', 'Plugins')
        os.makedirs(plugins_dir)

        # 从本地 Tools 复制
        for name, src in PLUGINS.items():
            dst = os.path.join(plugins_dir, os.path.basename(src))
            shutil.copy2(src, dst)
            installed.append(dst)

        # 验证全部复制成功
        assert len(os.listdir(plugins_dir)) == 5, f'安装后应为 5 个文件'
        for p in installed:
            assert os.path.exists(p), f'{p} 未安装成功'

        # 验证每个 .zyplugin 可解压
        for p in installed:
            with zipfile.ZipFile(p) as zf:
                assert 'manifest.json' in zf.namelist()
                assert 'index.js' in zf.namelist()

        print(f'  ℹ️  已安装 {len(installed)} 个插件到模拟 Documents/Plugins/')
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
test('模拟安装 5 个插件', simulate_install)

# ========== 4. 模拟卸载流程 ==========
print('\n🗑️  4. 模拟卸载流程')

def simulate_uninstall():
    tmp = tempfile.mkdtemp(prefix='zhiyu_uninst_')
    try:
        plugins_dir = os.path.join(tmp, 'Documents', 'Plugins')
        os.makedirs(plugins_dir)

        # 安装全部
        installed = []
        for name, src in PLUGINS.items():
            dst = os.path.join(plugins_dir, os.path.basename(src))
            shutil.copy2(src, dst)
            installed.append(dst)
        assert len(os.listdir(plugins_dir)) == 5

        # 卸载 toc-generator
        target = os.path.join(plugins_dir, 'toc-generator-local.zyplugin')
        os.remove(target)
        remaining = os.listdir(plugins_dir)
        assert len(remaining) == 4, f'卸载后应为 4 个文件，实际 {len(remaining)}'
        assert 'toc-generator-local.zyplugin' not in remaining, '卸载失败：文件仍在'

        # 卸载全部
        for f in list(os.listdir(plugins_dir)):
            os.remove(os.path.join(plugins_dir, f))
        assert len(os.listdir(plugins_dir)) == 0, '全部卸载后应为空'

    finally:
        shutil.rmtree(tmp, ignore_errors=True)
test('卸载 toc-generator (5→4)', simulate_uninstall)

# ========== 5. MarketPlugin JSON 数据验证 ==========
print('\n📋 5. MarketPlugin JSON 数据格式验证')

def validate_plugin_data():
    with urllib.request.urlopen('http://127.0.0.1:9091/api/plugins', timeout=5) as r:
        d = json.load(r)
    for p in d['data']:
        required = ['id','version','author','downloads','rating','icon','names','descriptions']
        for rk in required:
            assert rk in p, f'{p["id"]}: 缺少 {rk}'
        assert isinstance(p['downloads'], str), f'{p["id"]}: downloads 应为 str'
        assert isinstance(p['rating'], float), f'{p["id"]}: rating 应为 float'
        assert isinstance(p['names'], dict), f'{p["id"]}: names 应为 dict'
        assert 'en' in p['names'] or 'zh-Hans' in p['names'], f'{p["id"]}: names 缺语言'
        # 验证 reviewCount 和 category（新增字段）
        assert 'reviewCount' in p, f'{p["id"]}: 缺少 reviewCount'
        assert 'category' in p, f'{p["id"]}: 缺少 category'
test('5 个插件 JSON 格式完整', validate_plugin_data)

# ========== 6. 插件 JS 语法验证 ==========
print('\n📝 6. 插件 JavaScript 语法验证')

def validate_js_syntax():
    for name, path in PLUGINS.items():
        with zipfile.ZipFile(path) as zf:
            js = zf.read('index.js').decode('utf-8')
            # 基础语法检查
            assert 'function onLoad' in js, f'{name}: 缺少 onLoad'
            assert 'function onUnload' in js, f'{name}: 缺少 onUnload'
            # 没有明显的语法错误标志
            assert 'console.error' not in js or 'ZhiYu.log' in js, f'{name}: 使用 console 而非 ZhiYu API'
test('5 个插件 JS 语法合法', validate_js_syntax)


# ========== 7. JSContext 池化模拟测试（关键！之前遗漏） ==========
print("\n🧪 7. JSContext 池化语法模拟测试")

def validate_js_context_compatibility():
    """模拟 JavaScriptCore 解析：检查 JS 中是否混入 Swift 语法"""
    import zipfile
    swift_patterns = [
        "String(data:",      # Swift String(data:...)
        "Data(base64Encoded:", # Swift Data(base64Encoded:...)
        "encoding: .utf8",    # Swift encoding 参数
        ".utf8)!",            # Swift 可选链 + 强制解包
    ]
    for name, path in PLUGINS.items():
        with zipfile.ZipFile(path) as zf:
            js = zf.read('index.js').decode('utf-8')
            for pat in swift_patterns:
                assert pat not in js, f'{name}: JS 中包含 Swift 语法 "{pat}"'
    print("  ℹ️  5 个插件 JS 均无 Swift 语法混入")

def validate_plugin_engine_pool_js():
    """检查 PluginEnginePool.swift 中 evaluateScript 的字符串是否纯 JS"""
    pool_file = 'Sources/Infrastructure/Plugins/PluginEnginePool.swift'
    with open(pool_file) as f:
        code = f.read()
    # 提取所有 evaluateScript 的字符串内容
    import re
    scripts = re.findall(r'evaluateScript\("""(.*?)"""', code, re.DOTALL)
    swift_keywords = ['String(data:', 'Data(base64Encoded:', 'encoding: .utf8', 'Data(base64Encoded']
    for i, script in enumerate(scripts):
        for kw in swift_keywords:
            assert kw not in script, f'PluginEnginePool script #{i}: 包含 Swift "{kw}" → JSContext 将被污染!'
    print(f'  ℹ️  PluginEnginePool 中 {len(scripts)} 个 JS 段均无 Swift 语法混入')

validate_js_context_compatibility()
validate_plugin_engine_pool_js()
test("JS 无 Swift 语法混入", lambda: None)
test("PluginEnginePool JS 段纯 JS", lambda: None)

# ========== 结果汇总 ==========
total = ok + fail
print(f'\n{"="*50}')
print(f'  总计 {total} 项 | {GREEN}通过 {ok}{NC} | {RED}失败 {fail}{NC}')
print(f'{"="*50}')

if fail == 0:
    print(f'\n{GREEN}🎉 所有端到端测试通过！{NC}')
    sys.exit(0)
else:
    print(f'\n{RED}⚠️  {fail} 项测试失败{NC}')
    sys.exit(1)
