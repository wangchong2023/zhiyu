import sys
import re

def check_balance(filename):
    with open(filename, 'r') as f:
        content = f.read()
    
    # Remove strings
    content = re.sub(r'"([^"\\]|\\.)*"', '""', content)
    # Remove single line comments
    content = re.sub(r'//.*', '', content)
    # Remove multi-line comments
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
    
    stack = []
    line_num = 1
    col_num = 1
    
    for i, char in enumerate(content):
        if char == '\n':
            line_num += 1
            col_num = 1
            continue
        
        if char == '{':
            stack.append((line_num, col_num))
        elif char == '}':
            if not stack:
                print(f"Extra '}}' at line {line_num}, col {col_num}")
                return False
            stack.pop()
        col_num += 1
        
    if stack:
        print(f"Total unclosed: {len(stack)}")
        for line, col in stack:
            print(f"Unclosed '{{' at line {line}, col {col}")
        return False
    
    print("Braces are balanced (ignoring comments/strings).")
    return True

if __name__ == "__main__":
    check_balance(sys.argv[1])
