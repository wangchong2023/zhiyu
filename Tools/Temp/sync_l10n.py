import json
import os

def update_xcstrings(file_path, new_keys):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    strings = data.get('strings', {})
    for key, (zh, en) in new_keys.items():
        if key not in strings:
            strings[key] = {
                "extractionState": "manual",
                "localizations": {
                    "en": {
                        "stringUnit": {
                            "state": "translated",
                            "value": en
                        }
                    },
                    "zh-Hans": {
                        "stringUnit": {
                            "state": "translated",
                            "value": zh
                        }
                    }
                }
            }
    
    data['strings'] = strings
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

ai_keys = {
    "modelStore.title": ("AI 端侧模型中枢", "AI On-Device Model Hub"),
    "modelStore.myModels": ("我的模型", "My Models"),
    "modelStore.store": ("模型商店", "Model Store"),
    "modelStore.noReadyModels": ("暂无就绪模型", "No Models Ready"),
    "modelStore.downloadGuide": ("请切换至「模型商店」下载轻量级端侧底座（推荐 Gemma-2B）", "Switch to 'Store' to download a lightweight base (Gemma-2B recommended)"),
    "modelStore.physicalMemory": ("物理设备总运存", "Total Physical Memory"),
    "modelStore.adaptiveGuardActive": ("苹果芯片端侧大模型自适应护栏已激活 🛡️", "Apple Silicon Adaptive Guard Active 🛡️"),
    "modelStore.developer": ("开发商", "Vendor"),
    "modelStore.storageOccupied": ("占用空间", "Storage"),
    "modelStore.localReady": ("已就绪", "Ready"),
    "modelStore.colon": ("：", ": "),
    "modelStore.bullet": ("  •  ", "  •  "),
    "modelStore.shieldEmoji": ("🛡️", "🛡️"),
    "modelStore.cloudEmoji": ("☁️", "☁️"),
    "modelStore.task.semanticChunking": ("语义分块", "Semantic Chunking"),
    "modelStore.task.backlinkDiscovery": ("发现回链", "Link Discovery"),
    "modelStore.task.localChat": ("端侧对话", "Local Chat"),
    "modelStore.task.hybridChat": ("端云混合对话", "Hybrid Chat"),
    "modelStore.alert.physicalGuardTitle": ("物理防爆拦截警告 🛡️", "Physical Safety Intercept 🛡️"),
    "modelStore.alert.physicalGuardMessage": ("模型「%@」需要至少 %@ GB 的物理运行内存。\n\n当前设备运存不足（%@ GB），强行加载将引发极高的 OOM（闪退崩溃）风险，系统已自动实施护栏物理拦截。", "Model '%@' requires at least %@ GB of RAM.\n\nCurrent device has %@ GB. Loading this would cause high OOM (crash) risk. Adaptive Guard has intercepted this download."),
    "modelStore.alert.understand": ("明白", "Got it"),
    "modelStore.status.waiting": ("等待队列中...", "Waiting in queue..."),
    "modelStore.status.paused": ("已暂停", "Paused"),
    "modelStore.status.verifying": ("指纹防爆校验中...", "Verifying fingerprint..."),
    "modelStore.status.failed": ("失败", "Failed"),
    "modelStore.action.get": ("获取", "Get"),
    "modelStore.action.activeBase": ("当前活跃底座", "Active Base"),
    "modelStore.action.setAsBase": ("设为底座", "Set as Base"),
    "modelStore.action.cannotRun": ("无法运行", "Incompatible"),
    "modelStore.banner.restricted": ("物理拦截：当前设备物理内存无法承载本模型（需至少 %@ GB）", "Intercepted: Device RAM insufficient for this model (requires %@ GB)"),
    "modelStore.banner.warning": ("临界警告：该模型大小接近本机运存极值，运行可能发热、轻微卡顿。", "Warning: Model size near device limit. May cause heat or lag."),
    "controlCenter.title": ("AI 运行控制中枢", "AI Control Center"),
    "controlCenter.activeBase": ("当前活跃大模型底座", "Active Model Base"),
    "controlCenter.localReady": ("端侧大模型安全就绪", "On-Device Model Ready"),
    "controlCenter.cloudFallback": ("端侧权重未就绪，流转至云端", "On-Device weights missing, falling back to Cloud"),
    "controlCenter.cloudEscalation": ("云端深度考据提权", "Cloud Reasoning Escalation"),
    "controlCenter.cloudEscalationDesc": ("在合成实验室中智能加速，自动分流复杂推理", "Smart acceleration in Lab, auto-offload complex reasoning"),
    "controlCenter.adaptiveGuard": ("苹果芯片自适应护栏已激活", "Apple Silicon Adaptive Guard Active"),
    "controlCenter.gotoStore": ("前往 AI 模型商店", "Go to AI Model Store"),
    "remoteConfig.fallback.gemmaDesc": ("谷歌极速端侧推理模型，完美契合日常笔记语义分块和高频润色。", "Google's fast on-device model, perfect for semantic chunking and polishing."),
    "remoteConfig.fallback.llamaDesc": ("Meta 端侧主力大模型，具备极高的综合逻辑链考据及多跳问答推理表现。", "Meta's flagship on-device model, excellent reasoning and multi-hop QA."),
    "remoteConfig.fallback.phiDesc": ("微软高性价比推理大模型，语言合成精炼，对端侧 RAG 架构高度亲和。", "Microsoft's efficient model, concise synthesis, RAG friendly."),
    "remoteConfig.fallback.skill1.name": ("📂 语义切块与自动标签", "📂 Semantic Chunking & Tags"),
    "remoteConfig.fallback.skill1.desc": ("将录入的长笔记进行离线语义理解打标，建立主权概念索引。", "Understand and tag long notes offline, build sovereign concept index."),
    "remoteConfig.fallback.skill1.prompt": ("你是一位资深的知识组织专家。请精炼地阅读用户输入的笔记内容：\n{{input}}\n按照语义划分为若干段落，并提取 3-5 个核心标签，输出格式必须严格符合 JSON Schema 约束。", "You are a knowledge organization expert. Read the input:\n{{input}}\nChunk into paragraphs and extract 3-5 tags in JSON Schema format."),
    "remoteConfig.fallback.skill2.name": ("🔬 幻灯片与 Quiz 闪电合成", "🔬 Slides & Quiz Synthesis"),
    "remoteConfig.fallback.skill2.desc": ("一键将本地笔记深度转换为结构化的 Markdown 演讲稿或小测试题库。", "Convert local notes to structured Markdown slides or quiz pools."),
    "remoteConfig.fallback.skill2.prompt": ("你是一位精通多领域的学术规划大师。请深度分析以下文献知识库中的重点：\n{{input}}\n提取核心知识脉络，为用户一键生成一份包含 '# 标题' 和 '## 分栏幻灯片' 规范的演讲稿，结构需逻辑自闭环。", "You are an academic planning master. Analyze:\n{{input}}\nExtract core threads and generate a '# Title' / '## Slide' speech."),
    "remoteConfig.fallback.skill3.name": ("🔗 图谱潜在链接发现", "🔗 Graph Link Discovery"),
    "remoteConfig.fallback.skill3.desc": ("深度扫描本地主权知识库，自动探寻笔记与笔记之间隐藏的逻辑关联性。", "Scan local vault to discover hidden logical links between notes."),
    "remoteConfig.fallback.skill3.prompt": ("你是一位博古通今的概念联结导师。根据给定的笔记详情进行离线概念提取：\n{{input}}\n识别出文章中隐含的其他高价值概念短语，并在合适位置以 [[反向链接实体]] 的双向链格式将其锚定包装。", "You are a concept connection mentor. Extract concepts from:\n{{input}}\nWrap high-value phrases in [[Wikilink]] format."),
}

common_keys = {
    "demo.relatedConcepts": ("关联概念", "Related Concepts"),
    "demo.dependsOn": ("依赖于", "Depends On"),
    "demo.core": ("核心", "Core"),
    "demo.integratesWith": ("对接", "Integrates With"),
    "demo.foundation": ("基础", "Foundation"),
    "system.pencil.trigger": ("✏️ Apple Pencil 双击触发", "✏️ Apple Pencil Double Tap"),
    "system.divider": (" — ", " — "),
    "system.pipe": ("｜", " | "),
    "tags.ai": ("AI", "AI"),
    "tags.agent": ("智能体", "Agent"),
    "tags.planning": ("规划", "Planning"),
    "tags.memory": ("记忆", "Memory"),
    "tags.rag": ("RAG", "RAG"),
    "tags.toolUse": ("工具调用", "ToolUse"),
    "tags.llm": ("大模型", "LLM"),
    "tags.architecture": ("架构", "Architecture"),
    "tags.tools": ("工具", "Tools"),
    "tags.nlp": ("自然语言处理", "NLP"),
    "tags.storage": ("存储", "Storage"),
    "tags.security": ("安全", "Security"),
    "tags.theory": ("理论", "Theory"),
    "tags.network": ("网络", "Network"),
    "tags.protocol": ("协议", "Protocol"),
    "tags.quality": ("质量", "Quality"),
    "tags.visual": ("视觉", "Visual"),
    "tags.performance": ("性能", "Performance"),
}

update_xcstrings('Sources/Localization/Catalogs/AI.xcstrings', ai_keys)
update_xcstrings('Sources/Localization/Catalogs/Common.xcstrings', common_keys)
print("Updated .xcstrings files successfully.")
