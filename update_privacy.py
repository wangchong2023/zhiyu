import json

with open("Sources/Localization/Catalogs/System.xcstrings", "r", encoding="utf-8") as f:
    data = json.load(f)

zh_policy = """【智宇 (ZhiYu) 隐私政策】

欢迎使用智宇。我们深知个人信息对您的重要性，并会采取业界标准的安全措施保护您的信息安全。

1. 信息的收集与使用
我们将在您注册和使用服务时，收集您的账号信息（如手机号码、第三方关联账号等）及应用运行日志。这些信息仅用于向您提供稳定、个性化的知识管理与 AI 增强检索服务。

2. 信息的存储与保护
您的知识图谱及笔记数据将安全地保存在本地设备或受保护的服务端中（当前暂不支持 iCloud 同步）。我们采用多重加密和安全防护机制，防止您的数据遭到未经授权的访问或丢失。

3. 信息的共享
未经您的明确同意，或非因法定情形，我们不会向任何第三方提供、共享或出售您的个人数据。

4. 您的数据权利
您拥有访问、更正、删除个人信息以及注销账号的权利。您可以通过应用内的系统设置来管理您的各项数据及授权。

5. 政策变更
随着服务的升级，我们可能会适时更新本隐私政策。若有重大变更，我们将通过显著方式向您发出通知。

6. 联系我们
如果您对本政策有任何疑问，请通过应用内的“帮助与反馈”随时与我们取得联系。"""

en_policy = """[ZhiYu Privacy Policy]

Welcome to ZhiYu. We understand the importance of your personal information and will take industry-standard security measures to protect your data.

1. Information Collection and Use
We collect your account information (e.g., phone number, third-party linked accounts) and application logs when you register and use our services. This information is strictly used to provide stable and personalized knowledge management and AI-enhanced retrieval services.

2. Information Storage and Protection
Your knowledge graph and notes data will be securely stored on your local device or protected servers (iCloud sync is not supported at this time). We use multiple encryption and security protection mechanisms to prevent unauthorized access or data loss.

3. Information Sharing
Without your explicit consent, or unless required by law, we will not provide, share, or sell your personal data to any third party.

4. Your Data Rights
You have the right to access, correct, delete your personal information, and cancel your account. You can manage your data and authorizations through the in-app system settings.

5. Policy Changes
As our services evolve, we may update this privacy policy from time to time. We will notify you prominently of any significant changes.

6. Contact Us
If you have any questions about this policy, please feel free to contact us via "Help & Feedback" in the app."""

if "auth.privacyPolicy.content" in data["strings"]:
    data["strings"]["auth.privacyPolicy.content"]["localizations"]["zh-Hans"]["stringUnit"]["value"] = zh_policy
    data["strings"]["auth.privacyPolicy.content"]["localizations"]["en"]["stringUnit"]["value"] = en_policy
else:
    data["strings"]["auth.privacyPolicy.content"] = {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": en_policy}},
            "zh-Hans": {"stringUnit": {"state": "translated", "value": zh_policy}}
        }
    }

with open("Sources/Localization/Catalogs/System.xcstrings", "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
