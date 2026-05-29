import re

filepath = "Sources/Features/System/Auth/Service/AuthService.swift"
with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# We want to force isMockBackend to false for everything EXCEPT continueAsGuest.
# Currently, isMockBackend is a computed property checking ProcessInfo.
# We will change it to return false so real network requests are used for login/register/etc.
# BUT, we will manually hardcode `if true { ... }` in continueAsGuest to keep it mocked as requested.

# 1. Change isMockBackend to always return false
content = re.sub(
    r'private var isMockBackend: Bool \{.*?\n    \}',
    r'private var isMockBackend: Bool { return false }',
    content,
    flags=re.DOTALL
)

# 2. In continueAsGuest, change `if isMockBackend {` to `if true { // 强制保留游客模式 Mock`
content = re.sub(
    r'public func continueAsGuest\(\) \{\n\s*#if DEBUG\n\s*// Mock 模式 / 无后端环境下：直接本地设置游客状态，无需网络请求\n\s*if isMockBackend \{',
    r'public func continueAsGuest() {\n        #if DEBUG\n        // Mock 模式 / 无后端环境下：直接本地设置游客状态，无需网络请求\n        if true { // 强制保留游客模式 Mock',
    content
)

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

print("Patched AuthService.swift")
