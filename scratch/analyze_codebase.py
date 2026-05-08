import os
import re
import json

def analyze_swift_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    num_lines = len(lines)
    
    # Heuristics
    has_file_header = bool(re.search(r'//.*?版权|//.*?Copyright|///', content[:500], re.IGNORECASE | re.DOTALL))
    chinese_chars = len(re.findall(r'[\u4e00-\u9fff]', content))
    
    # Imports
    imports = re.findall(r'^\s*import\s+([A-Za-z0-9_]+)', content, re.MULTILINE)
    
    # Count functions and their lengths
    func_pattern = re.compile(r'^\s*(?:(?:public|private|internal|fileprivate|open)\s+)?(?:(?:class|static)\s+)?func\s+([A-Za-z0-9_]+)', re.MULTILINE)
    functions = func_pattern.findall(content)
    
    # Magic numbers/strings (naive)
    magic_strings = re.findall(r'(?<!import )\s*=\s*"([^"]{2,})"', content)
    magic_numbers = re.findall(r'(?<![A-Za-z0-9_])\s*=\s*([0-9]{2,})(?![A-Za-z0-9_])', content)
    
    # Cyclomatic complexity (naive keywords count)
    complexity_keywords = len(re.findall(r'\b(if|guard|for|while|switch|case|catch)\b', content))
    
    # Duplicate code check (naive: just looking for large blocks of similar lines could be too slow in python without advanced libs, so we skip complex duplicate check here)
    
    return {
        "file": filepath,
        "lines": num_lines,
        "has_file_header": has_file_header,
        "chinese_chars": chinese_chars,
        "imports": imports,
        "num_functions": len(functions),
        "magic_strings_count": len(magic_strings),
        "magic_numbers_count": len(magic_numbers),
        "complexity_score": complexity_keywords
    }

def main():
    sources_dir = "Sources"
    results = []
    for root, _, files in os.walk(sources_dir):
        for file in files:
            if file.endswith('.swift'):
                filepath = os.path.join(root, file)
                try:
                    res = analyze_swift_file(filepath)
                    results.append(res)
                except Exception as e:
                    print(f"Error reading {filepath}: {e}")

    # Analyze architecture rules
    # L3 (Views/ViewModels) -> L2 (Domain) -> L1 (Data) -> L0 (Core)
    layer_violations = []
    
    for r in results:
        path = r['file']
        imports = r['imports']
        
        # Check rule: Model/Service shouldn't import SwiftUI
        if "Shared/Models" in path or "Shared/Domain" in path or "Shared/Data" in path:
            if "SwiftUI" in imports:
                layer_violations.append(f"{path} imports SwiftUI but is in a lower layer.")
                
    # Sort by lines to find huge files
    results.sort(key=lambda x: x['lines'], reverse=True)
    
    report = {
        "total_files": len(results),
        "total_lines": sum(r['lines'] for r in results),
        "layer_violations": layer_violations,
        "largest_files": results[:10],
        "files_missing_chinese_comments": [r['file'] for r in results if r['chinese_chars'] < 5][:10],
        "highest_complexity": sorted(results, key=lambda x: x['complexity_score'], reverse=True)[:10],
        "most_magic_literals": sorted(results, key=lambda x: x['magic_strings_count'] + x['magic_numbers_count'], reverse=True)[:10]
    }
    
    with open('scratch/codebase_analysis_report.json', 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
        
    print(f"Analyzed {len(results)} files. Report saved to scratch/codebase_analysis_report.json")

if __name__ == "__main__":
    main()
