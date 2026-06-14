#!/usr/bin/env python3
"""合并 generate_sbom.py 输出与 Syft 扫描结果，补齐 License 信息."""
import json, os, sys

PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

def find_license_in_syft(syft_path: str, package_name: str) -> str:
    if not os.path.exists(syft_path):
        return "NOASSERTION"
    with open(syft_path) as f:
        syft = json.load(f)
    for comp in syft.get("components", []):
        if comp.get("name", "").lower() == package_name.lower():
            licenses = comp.get("licenses", [])
            if licenses:
                return licenses[0].get("license", {}).get("id", "NOASSERTION")
    return "NOASSERTION"

def main():
    spdx_path = os.path.join(PROJECT_DIR, "build", "sbom.spdx.json")
    syft_path = os.path.join(PROJECT_DIR, "build", "syft.cdx.json")
    if not os.path.exists(spdx_path):
        print("❌ sbom.spdx.json 不存在，请先运行 generate_sbom.py", file=sys.stderr)
        sys.exit(1)
    with open(spdx_path) as f:
        spdx = json.load(f)
    enriched = 0
    for pkg in spdx.get("packages", []):
        name = pkg.get("name", "")
        if pkg.get("licenseConcluded") == "NOASSERTION":
            lic = find_license_in_syft(syft_path, name)
            if lic != "NOASSERTION":
                pkg["licenseConcluded"] = lic
                pkg["licenseDeclared"] = lic
                enriched += 1
    with open(spdx_path, "w") as f:
        json.dump(spdx, f, indent=2)
    print(f"✅ SBOM 已丰富: {enriched} 个包的 License 从 Syft 补充", file=sys.stderr)
    print(spdx_path)

if __name__ == "__main__":
    main()
