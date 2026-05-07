import os
import re

mapping = {
    "WikiPageStore": "KnowledgePageStore",
    "WikiPageFTS": "KnowledgePageFTS",
    "WikiPage": "KnowledgePage",
    "WikiEventBus": "AppEventBus",
    "WikiEvent": "AppEvent",
    "WikiLinkProcessor": "AppLinkProcessor",
    "WikiLink": "PageLink",
    "WikiPasteboard": "AppPasteboard",
    "WikiImage": "AppImage",
    "shimmerWiki": "shimmerApp",
    "wikiCard": "appCard",
    "wikiToast": "appToast",
    "wikiSecondary": "appSecondary",
    "wikiAccent": "appAccent",
    "wikiBackground": "appBackground",
    "WikiGlow": "AppGlow",
    "WikiGlassCard": "AppGlassCard",
    "WikiShimmer": "AppShimmer",
    "WikiBadge": "AppBadge",
    "WikiToast": "AppToast",
    "WikiToastType": "AppToastType",
    "WikiDivider": "AppDivider",
    "WikiAccentLine": "AppAccentLine",
    "WikiGradientBG": "AppGradientBG",
    "WikiDotPattern": "AppDotPattern",
    "WikiCardAccent": "AppCardAccent",
    "WikiIconBox": "AppIconBox",
    "WikiSkeleton": "AppSkeleton",
    "WikiPulseDot": "AppPulseDot",
    "WikiEmptyState": "AppEmptyState",
    "WikiLoadingOverlay": "AppLoadingOverlay",
    "WikiTooltip": "AppTooltip",
    "WikiCardModifier": "AppCardModifier",
    "WikiBorderedCard": "AppBorderedCard",
    "WikiSectionHeader": "AppSectionHeader",
    "WikiLabeledRow": "AppLabeledRow",
    "WikiStepRow": "AppStepRow",
    "WikiChip": "AppChip",
    "WikiIconChip": "AppIconChip",
    "WikiPrimaryButton": "AppPrimaryButton",
    "WikiCapsuleButton": "AppCapsuleButton",
    "WikiSuccessBanner": "AppSuccessBanner",
    "WikiTextField": "AppTextField",
    "WikiTagField": "AppTagField",
    "WikiMonospacedEditor": "AppMonospacedEditor",
    "WikiScrollableChips": "AppScrollableChips",
    "WikiInlineProgress": "AppInlineProgress",
    "WikiToastModifier": "AppToastModifier",
    "WikiToastView": "AppToastView",
    "WikilinkPickerSheet": "PageLinkPickerSheet",
    "wiki_link": "page_link"
}

def process_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return False
    
    new_content = content
    # Use word boundary or specific replacements to avoid partial matches if needed,
    # but here the names are quite specific.
    for old, new in mapping.items():
        new_content = new_content.replace(old, new)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

def main():
    targets = ['Sources', 'Tests']
    modified_count = 0
    for target in targets:
        for root, dirs, files in os.walk(target):
            for file in files:
                if file.endswith('.swift') or file.endswith('.xcstrings'):
                    if process_file(os.path.join(root, file)):
                        modified_count += 1
                        print(f"Modified: {os.path.join(root, file)}")
    print(f"Modified {modified_count} files.")

if __name__ == "__main__":
    main()
