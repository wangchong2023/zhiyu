#!/usr/bin/env python3
"""从 Package.resolved 生成 SPDX 2.3 JSON SBOM."""
import json, os, sys
from datetime import datetime, timezone

PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

def find_resolved():
    paths = [
        os.path.join(PROJECT_DIR, "ZhiYu.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"),
    ]
    for p in paths:
        if os.path.exists(p):
            return p
    for root, dirs, files in os.walk(PROJECT_DIR):
        if "Package.resolved" in files and ".build" not in root:
            return os.path.join(root, "Package.resolved")
    print("❌ Package.resolved not found", file=sys.stderr)
    sys.exit(1)

def make_spdx(packages: list[dict]) -> dict:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return {
        "SPDXID": "SPDXRef-DOCUMENT",
        "spdxVersion": "SPDX-2.3",
        "creationInfo": {
            "created": now,
            "creators": ["Tool: ZhiYu-generate-sbom"],
            "licenseListVersion": "3.21"
        },
        "name": "ZhiYu-iOS",
        "dataLicense": "CC0-1.0",
        "documentNamespace": f"https://zhiyu.app/sbom/{datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S')}",
        "packages": [{
            "SPDXID": "SPDXRef-ZhiYu",
            "name": "ZhiYu",
            "versionInfo": "1.0",
            "supplier": "Organization: wangchong2023",
            "downloadLocation": "NOASSERTION",
            "filesAnalyzed": False,
            "licenseConcluded": "NOASSERTION",
            "licenseDeclared": "NOASSERTION",
            "copyrightText": "NOASSERTION"
        }] + [{
            "SPDXID": f"SPDXRef-{p['name'].replace('.','-').replace('_','-')}",
            "name": p["name"],
            "versionInfo": p["version"],
            "supplier": f"Organization: {p.get('repository_url', 'NOASSERTION')}",
            "downloadLocation": p.get("repository_url", "NOASSERTION"),
            "externalRefs": [{
                "referenceCategory": "PACKAGE-MANAGER",
                "referenceType": "purl",
                "referenceLocator": f"pkg:swift/{p['name']}@{p['version']}"
            }],
            "filesAnalyzed": False,
            "licenseConcluded": p.get("license", "NOASSERTION"),
            "licenseDeclared": p.get("license", "NOASSERTION"),
            "copyrightText": "NOASSERTION"
        } for p in packages],
        "relationships": [{
            "spdxElementId": "SPDXRef-ZhiYu",
            "relationshipType": "CONTAINS",
            "relatedSpdxElement": f"SPDXRef-{p['name'].replace('.','-').replace('_','-')}"
        } for p in packages]
    }

def main():
    resolved_path = find_resolved()
    print(f"📦 解析 Package.resolved: {resolved_path}", file=sys.stderr)
    with open(resolved_path) as f:
        data = json.load(f)
    packages = []
    for pin in data.get("pins", []):
        packages.append({
            "name": pin.get("identity", "unknown"),
            "version": pin.get("state", {}).get("version", "unknown"),
            "revision": pin.get("state", {}).get("revision", "")[:12],
            "repository_url": pin.get("location", ""),
            "license": "NOASSERTION"
        })
    spdx = make_spdx(packages)
    output_path = os.path.join(PROJECT_DIR, "build", "sbom.spdx.json")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        json.dump(spdx, f, indent=2)
    print(f"✅ SBOM (SPDX 2.3) 写入: {output_path}", file=sys.stderr)
    print(f"   包含 {len(packages)} 个依赖", file=sys.stderr)
    print(output_path)

if __name__ == "__main__":
    main()
