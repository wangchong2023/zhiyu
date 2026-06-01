import json
import os

missing_keys_ai = [
    "llm.prompt.rewrite.rule3",
    "llm.prompt.workshop.shortcuts.footer",
    "llm.prompt.shortcut.studyPath",
    "llm.prompt.expert.quiz.title",
    "llm.prompt.default.quiz",
    "llm.prompt.queryRewrite",
    "llm.prompt.workshop.add",
    "ai.eval.latency",
    "llm.ingest.jsonSchemaTitle",
    "llm.prompt.summaryPrefix",
    "ai.eval.performance",
    "llm.prompt.workshop.shortcuts.title",
    "ai.eval.accuracy",
    "llm.prompt.expert.slides.title",
    "llm.prompt.quiz.question",
    "llm.prompt.discoverLinksPrefix",
    "llm.prompt.queryExpansion",
    "llm.prompt.shortcut.deepReview",
    "llm.prompt.ingestManagementAssistant",
    "llm.prompt.default.summary",
    "llm.prompt.default.actions",
    "llm.prompt.quiz.explanation",
    "llm.prompt.potentialLinks",
    "aitask.type.\\(type)"
]

missing_keys_watch = [
    "watch.words",
    "watch.tenThousand",
    "watch.recentUpdates",
    "watch.pages"
]

missing_keys_chat = [
    "chat.messageCount",
    "chat.contextLimitWarning",
    "chat.referenceCount",
    "chat.activeSessionCount",
    "chat.tokenUsage"
]

missing_keys_network = [
    "errorTokenExpired",
    "errorUnauthorized",
    "errorUnexpected",
    "errorDecodeFailed",
    "missingRefreshToken",
    "invalidHTTPResponse",
    "errorServer",
    "errorHTTP",
    "sessionInvalidated",
    "missingDataPayload",
    "errorInvalidURL"
]

missing_keys_coachmark = [
    "medal.\\(id).desc",
    "medal.\\(id).title"
]

missing_keys_graph = [
    "graph.",
    "graph3d."
]

missing_keys_common = [
    "demo.vectorDB.content",
    "demo.secureEnv.title",
    "action.export",
    "demo.consistency.content",
    "logAction.aiscan",
    "demo.chunking.content",
    "demo.embedding.content",
    "demo.toolchain.content",
    "demo.toolchain.title",
    "demo.gateway.title",
    "demo.topology.content",
    "demo.memoryMgmt.content",
    "demo.toolInterface.content",
    "demo.gateway.content",
    "demo.memoryMgmt.title",
    "demo.transformer.title",
    "demo.topology.title",
    "demo.hybridSearch.title",
    "demo.toolInterface.title",
    "demo.consistency.title",
    "demo.secureEnv.content",
    "ERROR",
    "demo.vectorDB.title",
    "demo.hybridSearch.content",
    "common.comingSoon",
    "demo.transformer.content",
    "demo.embedding.title",
    "demo.chunking.title"
]

catalogs = {
    "AI.xcstrings": missing_keys_ai,
    "Watch.xcstrings": missing_keys_watch,
    "Chat.xcstrings": missing_keys_chat,
    "Network.xcstrings": missing_keys_network,
    "Coachmark.xcstrings": missing_keys_coachmark,
    "Graph.xcstrings": missing_keys_graph,
    "Common.xcstrings": missing_keys_common
}

base_path = "Sources/Localization/Catalogs"

for filename, keys in catalogs.items():
    file_path = os.path.join(base_path, filename)
    
    if not os.path.exists(file_path):
        # Create it if it doesn't exist
        data = {
            "sourceLanguage": "en",
            "strings": {}
        }
    else:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            
    if "strings" not in data:
        data["strings"] = {}
        
    for key in keys:
        if key not in data["strings"]:
            data["strings"][key] = {
                "extractionState": "manual",
                "localizations": {
                    "en": {
                        "stringUnit": {
                            "state": "translated",
                            "value": key.split(".")[-1].replace("([A-Z])", " \\1").capitalize()
                        }
                    },
                    "zh-Hans": {
                        "stringUnit": {
                            "state": "translated",
                            "value": key.split(".")[-1].replace("([A-Z])", " \\1").capitalize() + " (zh)"
                        }
                    }
                }
            }
            
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

print("Fixed missing keys.")
