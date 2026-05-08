import os
import re

def calculate_complexity(code_block):
    # This is a heuristic calculation of cyclomatic complexity
    # Complexity = 1 + number of decision points
    
    # Common decision point keywords in Swift
    keywords = [
        r'\bif\b', 
        r'\bwhile\b', 
        r'\bfor\b', 
        r'\bcase\b', 
        r'\bguard\b', 
        r'\bcatch\b',
        r'\b&& \b',
        r'\b\|\|\b',
        r'\?', # ternary operator - heuristic, might catch optional types too but usually okay for finding complex functions
        r'\?\?' # nil coalescing
    ]
    
    complexity = 1
    for kw in keywords:
        matches = re.findall(kw, code_block)
        complexity += len(matches)
        
    return complexity

def analyze_swift_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Regex to find function definitions
    # Matches 'func name(...) -> ReturnType {'
    # Note: This is a simplified regex and won't catch everything (like multiline definitions)
    # but it's a good starting point.
    func_pattern = re.compile(r'func\s+([a-zA-Z0-9_]+)\s*\([^)]*\)\s*(?:->\s*[^{]+)?\s*\{')
    
    # We need to find the body of each function. 
    # A simple way is to find the function start and then match braces.
    results = []
    
    for match in func_pattern.finditer(content):
        func_name = match.group(1)
        start_pos = match.end() - 1 # Include the opening brace
        
        # Match braces to find the end of the function
        brace_count = 0
        end_pos = -1
        for i in range(start_pos, len(content)):
            if content[i] == '{':
                brace_count += 1
            elif content[i] == '}':
                brace_count -= 1
                if brace_count == 0:
                    end_pos = i + 1
                    break
        
        if end_pos != -1:
            func_body = content[start_pos:end_pos]
            complexity = calculate_complexity(func_body)
            
            # Find line number
            line_num = content.count('\n', 0, match.start()) + 1
            
            results.append({
                'name': func_name,
                'complexity': complexity,
                'line': line_num,
                'file': filepath
            })
            
    return results

def main():
    sources_dir = 'Sources'
    all_results = []
    
    for root, dirs, files in os.walk(sources_dir):
        for file in files:
            if file.endswith('.swift'):
                path = os.path.join(root, file)
                try:
                    all_results.extend(analyze_swift_file(path))
                except Exception as e:
                    print(f"Error analyzing {path}: {e}")
    
    # Filter for complexity > 20
    complex_funcs = [r for r in all_results if r['complexity'] > 20]
    
    # Sort by complexity descending
    complex_funcs.sort(key=lambda x: x['complexity'], reverse=True)
    
    if not complex_funcs:
        print("未发现圈复杂度超过 20 的函数。")
    else:
        print(f"发现 {len(complex_funcs)} 个圈复杂度超过 20 的函数：\n")
        print(f"{'复杂度':<8} | {'行号':<6} | {'函数名':<30} | {'文件'}")
        print("-" * 100)
        for f in complex_funcs:
            print(f"{f['complexity']:<8} | {f['line']:<6} | {f['name']:<30} | {f['file']}")

if __name__ == "__main__":
    main()
