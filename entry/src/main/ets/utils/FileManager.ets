import { FileNode } from '../models/IDEModels';

interface FileEntry {
  key: string;
  value: string;
}

let g_files: Map<string, string> = new Map();
let g_initialized: boolean = false;

function ensureInit(): void {
  if (!g_initialized) {
    g_files.set('/project/main.py',
      '# ERIC-IDE Demo Project\n' +
      'def greet(name):\n    return "Hello, " + name + "!"\n\n' +
      'def factorial(n):\n    if n <= 1:\n        return 1\n    return n * factorial(n - 1)\n\n' +
      'def fibonacci(n):\n    a, b = 0, 1\n    result = []\n' +
      '    for _ in range(n):\n        result.append(a)\n        a, b = b, a + b\n' +
      '    return result\n\n' +
      'if __name__ == "__main__":\n' +
      '    print(greet("World"))\n' +
      '    print("Factorial(10) =", factorial(10))\n' +
      '    print("Fibonacci(15) =", fibonacci(15))\n'
    );
    g_files.set('/project/utils.py',
      'def word_count(text):\n    return len(text.split())\n\n' +
      'def reverse_string(s):\n    return s[::-1]\n\n' +
      'if __name__ == "__main__":\n' +
      '    s = "Hello ERIC-IDE"\n' +
      '    print("Reversed:", reverse_string(s))\n' +
      '    print("Words:", word_count(s))\n'
    );
    g_files.set('/project/hello.py',
      'print("Hello from ERIC-IDE on HarmonyOS!")\nprint("Python Simulator is running!")\n'
    );
    g_files.set('/project/math_demo.py',
      'print("=== Math Demo ===")\n' +
      'print("2 + 3 =", 2 + 3)\n' +
      'print("10 * 5 =", 10 * 5)\n' +
      'print("100 / 7 =", 100 / 7)\n'
    );
    g_files.set('/project/data_demo.py',
      'fruits = ["apple", "banana", "cherry"]\nprint("Fruits:", fruits)\n\n' +
      'squares = [x * x for x in range(1, 11)]\nprint("Squares:", squares)\n'
    );
    g_files.set('/project/loop_demo.py',
      '# Loop Demo\n' +
      'print("=== For Loop ===")\n' +
      'for i in range(5):\n    print("i =", i)\n\n' +
      'print("=== While Loop ===")\n' +
      'count = 0\nwhile count < 3:\n    print("count =", count)\n    count = count + 1\n'
    );
    g_files.set('/project/condition_demo.py',
      '# Condition Demo\n' +
      'score = 85\n' +
      'if score >= 90:\n    print("excellent")\n' +
      'elif score >= 80:\n    print("good")\n' +
      'elif score >= 60:\n    print("pass")\n' +
      'else:\n    print("fail")\n\n' +
      'x = 10\n' +
      'if x > 5 and x < 20:\n    print("x is in range")\n'
    );
    g_files.set('/project/src/app.rb',
      'def greet(name)\n  "Hello, #{name}!"\nend\n\nputs greet("ERIC-IDE")\n'
    );
    g_files.set('/project/config.json',
      '{\n  "name": "eric-ide-project",\n  "version": "1.0.0"\n}\n'
    );
    g_files.set('/project/README.md',
      '# ERIC-IDE Demo Project\n\nSample project.\n\n## Files\n- main.py\n- utils.py\n- hello.py\n'
    );
    g_initialized = true;
  }
}

function doSortTree(nodes: FileNode[]): void {
  nodes.sort((a: FileNode, b: FileNode) => {
    if (a.isDirectory && !b.isDirectory) return -1;
    if (!a.isDirectory && b.isDirectory) return 1;
    return a.name.localeCompare(b.name);
  });
  for (let i = 0; i < nodes.length; i++) {
    if (nodes[i].isDirectory && nodes[i].children.length > 0) {
      doSortTree(nodes[i].children);
    }
  }
}

export class FileManager {
  static init(): void {
    ensureInit();
  }

  static readFile(path: string): string {
    ensureInit();
    let content: string | undefined = g_files.get(path);
    if (content !== undefined) {
      return content;
    }
    return '';
  }

  static writeFile(path: string, content: string): boolean {
    ensureInit();
    g_files.set(path, content);
    return true;
  }

  static fileExists(path: string): boolean {
    ensureInit();
    return g_files.has(path);
  }

  static deleteFile(path: string): boolean {
    ensureInit();
    return g_files.delete(path);
  }

  static renameFile(oldPath: string, newName: string): boolean {
    ensureInit();
    let content: string | undefined = g_files.get(oldPath);
    if (content === undefined) return false;
    let lastSlash: number = oldPath.lastIndexOf('/');
    let dir: string = lastSlash >= 0 ? oldPath.substring(0, lastSlash) : '';
    let newPath: string = dir + '/' + newName;
    g_files.set(newPath, content);
    g_files.delete(oldPath);
    return true;
  }

  static renameFolder(oldPath: string, newName: string): boolean {
    ensureInit();
    let prefix: string = oldPath;
    if (!prefix.endsWith('/')) prefix += '/';
    let entries: FileEntry[] = [];
    g_files.forEach((value: string, key: string) => {
      if (key === oldPath || key.startsWith(prefix)) {
        let entry: FileEntry = { key: key, value: value };
        entries.push(entry);
      }
    });
    if (entries.length === 0) return false;
    let lastSlash: number = oldPath.lastIndexOf('/');
    let dir: string = lastSlash >= 0 ? oldPath.substring(0, lastSlash) : '';
    let newPrefix: string = dir + '/' + newName + '/';
    for (let i = 0; i < entries.length; i++) {
      g_files.delete(entries[i].key);
      let relPath: string = entries[i].key.substring(oldPath.length);
      let newKey: string = dir + '/' + newName + relPath;
      g_files.set(newKey, entries[i].value);
    }
    return true;
  }

  static deleteFolder(folderPath: string): boolean {
    ensureInit();
    let prefix: string = folderPath;
    if (!prefix.endsWith('/')) prefix += '/';
    let keysToDelete: string[] = [];
    g_files.forEach((_value: string, key: string) => {
      if (key === folderPath || key.startsWith(prefix)) keysToDelete.push(key);
    });
    for (let i = 0; i < keysToDelete.length; i++) {
      g_files.delete(keysToDelete[i]);
    }
    return keysToDelete.length > 0;
  }

  static createFolder(parentPath: string, folderName: string): boolean {
    ensureInit();
    let folderPath: string = parentPath;
    if (!folderPath.endsWith('/')) {
      folderPath += '/';
    }
    folderPath += folderName;
    // 用 "${folderPath}/.gitkeep" 作为占位，让 buildFileTree 能发现这个目录
    let placeholderKey: string = folderPath + '/.gitkeep';
    g_files.set(placeholderKey, '');
    return true;
  }

  static folderExists(folderPath: string): boolean {
    ensureInit();
    let prefix: string = folderPath;
    if (!prefix.endsWith('/')) {
      prefix += '/';
    }
    let found: boolean = false;
    g_files.forEach((_value: string, key: string) => {
      if (key.startsWith(prefix)) {
        found = true;
      }
    });
    return found;
  }

  static getAllFilePaths(): string[] {
    ensureInit();
    let paths: string[] = [];
    g_files.forEach((_value: string, key: string) => {
      paths.push(key);
    });
    return paths;
  }

  static getExtension(filePath: string): string {
    let lastDot: number = filePath.lastIndexOf('.');
    if (lastDot >= 0) {
      return filePath.substring(lastDot);
    }
    return '';
  }

  static getFileName(filePath: string): string {
    let lastSlash: number = filePath.lastIndexOf('/');
    if (lastSlash >= 0) {
      return filePath.substring(lastSlash + 1);
    }
    return filePath;
  }

  static generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substring(2, 8);
  }

  static buildFileTree(paths: string[]): FileNode[] {
    let root: FileNode[] = [];
    for (let p of paths) {
      let parts: string[] = p.split('/').filter((part: string) => part.length > 0);
      let current: FileNode[] = root;
      let currentPath: string = '';
      for (let i: number = 0; i < parts.length; i++) {
        currentPath += '/' + parts[i];
        let isLast: boolean = i === parts.length - 1;
        let existing: FileNode | undefined = undefined;
        for (let j: number = 0; j < current.length; j++) {
          if (current[j].name === parts[i]) {
            existing = current[j];
            break;
          }
        }
        if (existing) {
          if (!isLast) {
            current = existing.children;
          }
        } else {
          let node = new FileNode();
          node.name = parts[i];
          node.path = currentPath;
          node.isDirectory = !isLast;
          current.push(node);
          if (!isLast) {
            current = node.children;
          }
        }
      }
    }
    doSortTree(root);
    return root;
  }
}
