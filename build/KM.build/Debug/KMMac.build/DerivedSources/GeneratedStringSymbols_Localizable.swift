// 
// GeneratedStringSymbols_Localizable.swift
// Auto-Generated symbols for localized strings defined in “Localizable.xcstrings”.
// 

import Foundation

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
private nonisolated let resourceBundleDescription = LocalizedStringResource.BundleDescription.atURL(resourceBundle.bundleURL)
#else

private class ResourceBundleClass {}
@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
private nonisolated let resourceBundleDescription = LocalizedStringResource.BundleDescription.forClass(ResourceBundleClass.self)
#endif

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
nonisolated extension LocalizedStringResource {
    /**
     Localized string for key “app.name” in table “Localizable.xcstrings”.
     */
    static var appName: LocalizedStringResource {
        LocalizedStringResource("app.name", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “ingest.clipboardImport” in table “Localizable.xcstrings”.
     */
    static var ingestClipboardImport: LocalizedStringResource {
        LocalizedStringResource("ingest.clipboardImport", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “llm.provider.minimax” in table “Localizable.xcstrings”.
     */
    static var llmProviderMinimax: LocalizedStringResource {
        LocalizedStringResource("llm.provider.minimax", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “llm.provider.qwen” in table “Localizable.xcstrings”.
     */
    static var llmProviderQwen: LocalizedStringResource {
        LocalizedStringResource("llm.provider.qwen", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “llm.provider.zhipu” in table “Localizable.xcstrings”.
     */
    static var llmProviderZhipu: LocalizedStringResource {
        LocalizedStringResource("llm.provider.zhipu", table: "Localizable", bundle: resourceBundleDescription)
    }
}