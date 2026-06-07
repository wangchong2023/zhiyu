#!/usr/bin/env python3
"""
Mock API 测试脚本
验证插件市场和模型商店的 Mock 服务器数据获取是否正常
"""

import urllib.request
import json
import sys

def test_plugin_market():
    """测试插件市场 API"""
    print("=" * 60)
    print("测试 1: 插件市场 API")
    print("=" * 60)
    
    url = "http://localhost:9091/api/plugins"
    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            status_code = response.getcode()
            print(f"✓ HTTP 状态码: {status_code}")
            
            if status_code == 200:
                data = json.loads(response.read().decode())
                print(f"✓ 返回数据类型: {type(data)}")
                print(f"✓ code: {data.get('code')}")
                print(f"✓ message: {data.get('message')}")
                
                plugins = data.get('data', [])
                print(f"✓ 插件数量: {len(plugins)}")
                
                if plugins:
                    first_plugin = plugins[0]
                    print(f"\n第一个插件:")
                    print(f"  - ID: {first_plugin.get('id')}")
                    print(f"  - 名称: {first_plugin.get('name')}")
                    print(f"  - 作者: {first_plugin.get('author')}")
                    print(f"  - 版本: {first_plugin.get('version')}")
                    print(f"  - 下载量: {first_plugin.get('downloads')}")
                    print(f"  - 评分: {first_plugin.get('rating')}")
                
                return True
            else:
                print(f"✗ HTTP 状态码错误: {status_code}")
                return False
                
    except Exception as e:
        print(f"✗ 错误: {e}")
        return False

def test_model_store():
    """测试模型商店 API"""
    print("\n" + "=" * 60)
    print("测试 2: 模型商店 API")
    print("=" * 60)
    
    url = "http://localhost:8080/api/models"
    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            status_code = response.getcode()
            print(f"✓ HTTP 状态码: {status_code}")
            
            if status_code == 200:
                data = json.loads(response.read().decode())
                print(f"✓ 返回数据类型: {type(data)}")
                print(f"✓ code: {data.get('code')}")
                print(f"✓ message: {data.get('message')}")
                
                models = data.get('data', [])
                print(f"✓ 模型数量: {len(models)}")
                
                if models:
                    first_model = models[0]
                    print(f"\n第一个模型:")
                    print(f"  - ID: {first_model.get('id')}")
                    print(f"  - 名称: {first_model.get('name')}")
                    print(f"  - 提供商: {first_model.get('provider')}")
                    print(f"  - 参数规模: {first_model.get('parameterSize')}")
                    print(f"  - 内存需求: {first_model.get('memoryRequirement')}")
                    print(f"  - 下载大小: {first_model.get('downloadSize')}")
                
                return True
            else:
                print(f"✗ HTTP 状态码错误: {status_code}")
                return False
                
    except Exception as e:
        print(f"✗ 错误: {e}")
        return False

def test_data_structure():
    """测试数据结构完整性"""
    print("\n" + "=" * 60)
    print("测试 3: 数据结构验证")
    print("=" * 60)
    
    # 验证插件市场数据结构
    plugin_url = "http://localhost:9091/api/plugins"
    try:
        with urllib.request.urlopen(plugin_url, timeout=5) as response:
            data = json.loads(response.read().decode())
            plugins = data.get('data', [])
            
            required_fields = ['id', 'name', 'author', 'version', 'description', 
                              'icon', 'category', 'tags', 'downloads', 'rating']
            
            if plugins:
                plugin = plugins[0]
                missing_fields = [field for field in required_fields if field not in plugin]
                
                if missing_fields:
                    print(f"✗ 插件数据缺失字段: {missing_fields}")
                    return False
                else:
                    print(f"✓ 插件数据结构完整")
        
    except Exception as e:
        print(f"✗ 插件数据结构验证失败: {e}")
        return False
    
    # 验证模型商店数据结构
    model_url = "http://localhost:8080/api/models"
    try:
        with urllib.request.urlopen(model_url, timeout=5) as response:
            data = json.loads(response.read().decode())
            models = data.get('data', [])
            
            required_fields = ['id', 'name', 'provider', 'description', 
                              'contextWindow', 'parameterSize', 'memoryRequirement']
            
            if models:
                model = models[0]
                missing_fields = [field for field in required_fields if field not in model]
                
                if missing_fields:
                    print(f"✗ 模型数据缺失字段: {missing_fields}")
                    return False
                else:
                    print(f"✓ 模型数据结构完整")
        
        return True
        
    except Exception as e:
        print(f"✗ 模型数据结构验证失败: {e}")
        return False

def main():
    print("\n🧪 Mock API 测试套件\n")
    
    results = []
    results.append(("插件市场 API", test_plugin_market()))
    results.append(("模型商店 API", test_model_store()))
    results.append(("数据结构验证", test_data_structure()))
    
    print("\n" + "=" * 60)
    print("测试结果汇总")
    print("=" * 60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for name, result in results:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"{name}: {status}")
    
    print(f"\n总计: {passed}/{total} 测试通过")
    
    if passed == total:
        print("\n🎉 所有测试通过！")
        sys.exit(0)
    else:
        print(f"\n⚠️  {total - passed} 个测试失败")
        sys.exit(1)

if __name__ == "__main__":
    main()
