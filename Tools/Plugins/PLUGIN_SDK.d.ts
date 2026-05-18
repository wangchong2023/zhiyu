/**
 * 智宇 (ZhiYu) 插件开发类型定义文件 (TS Definition)
 * 用于在 VS Code 等编辑器中提供智能代码补全 (IntelliSense)
 */

declare namespace ZhiYu {
    /**
     * 在控制台打印一条调试日志
     * @param message 消息内容
     */
    function log(message: string): void;

    /**
     * 向智宇申请 AI 大模型访问权限
     * @param prompt 提问词
     * @returns AI 返回的文本内容，若无权限或执行失败则返回 null
     */
    function requestAIAccess(prompt: string): Promise<string | null>;

    /**
     * 搜索当前知识库中的页面
     * @param query 搜索关键词
     * @returns 匹配的页面对象数组
     */
    function queryPages(query: string): Promise<any[]>;

    /**
     * 注册一个全局指令 (Command)
     * 用户可通过 Cmd+K (快捷搜索) 发现并触发此动作
     * @param id 指令唯一标识
     * @param name 在 UI 上显示的名称
     * @param funcName 触发时调用的全局 JS 函数名
     */
    function registerCommand(id: string, name: string, funcName: string): void;

    /**
     * 在侧边栏注册一个快捷按钮 (Ribbon Icon)
     * @param icon SF Symbols 图标名称 (如 "sparkles")
     * @param title 悬浮提示文本
     * @param funcName 点击时调用的全局 JS 函数名
     */
    function registerRibbonItem(icon: string, title: string, funcName: string): void;

    /**
     * 注册插件专属的设置面板
     * @param name 设置页标题
     * @param schema JSON 格式的 UI 描述字符串 (支持 toggle, text, info 类型)
     * @param funcName 配置变更时的回调函数名
     */
    function registerSettingTab(name: string, schema: string | null, funcName: string): void;

    /**
     * 注册一个独立的侧边栏功能视图 (Custom View)
     * @param id 视图唯一标识
     * @param title 侧边栏显示的标题
     * @param icon 侧边栏图标 (SF Symbols)
     * @param funcName 激活视图时调用的全局 JS 函数名
     */
    function registerView(id: string, title: string, icon: string, funcName: string): void;

    /**
     * 监听系统级生命周期事件
     * @param event 事件名称 (如 "onFileOpen", "onPageSave", "onPageDelete")
     * @param funcName 触发时调用的全局 JS 函数名
     */
    function addEventListener(event: string, funcName: string): void;

    /**
     * 持久化保存插件私有数据 (已自动通过 AES-256-GCM 加密)
     * @param key 键名
     * @param value 键值 (字符串)
     */
    function saveData(key: string, value: string): void;

    /**
     * 读取已持久化的插件私有数据
     * @param key 键名
     * @returns 存储的值，若不存在则返回 null
     */
    function loadData(key: string): string | null;

    /**
     * 发起一个受 DLP 审计保护的网络请求
     * 注意：目标域名必须在 manifest.json 的 allowedDomains 中声明
     * @param url 请求地址
     * @param options 请求配置 (method, headers, body)
     * @param funcName 执行完成后的回调函数名
     */
    function fetch(url: string, options: any | null, funcName: string): void;
}

/**
 * 插件生命周期钩子：插件加载时触发
 */
declare function onLoad(): void;

/**
 * 插件生命周期钩子：插件卸载时触发
 */
declare function onUnload(): void;

/**
 * 内容拦截钩子：页面内容持久化前的预处理
 * @param content 原始 Markdown 内容
 * @returns 修改后的 Markdown 内容
 */
declare function preProcess(content: string): string;

/**
 * 内容转换钩子：内容渲染前的实时转换
 */
declare function postProcess(content: string): string;
