import { Language, ErrorEntry } from '../models/IDEModels';
import { PythonSimulator } from './PythonSimulator';

interface NativePythonModule {
  runPython(code: string): string;
  runRuby(code: string): string;
  getSupportedLanguages(): string;
}

export class RunHandler {
  static execute(code: string, language: Language): string {
    let startTime: number = Date.now();
    let result: string = '';

    try {
      let output: string = PythonSimulator.run(code, language);
      let elapsed: number = Date.now() - startTime;
      let errors: ErrorEntry[] = RunHandler.parseErrors(output, code);

      if (errors.length > 0) {
        let lines: string[] = code.split('\n');
        result += 'Traceback (most recent call last):\n';
        for (let i = 0; i < errors.length; i++) {
          let e: ErrorEntry = errors[i];
          result += '  File "<input>", line ' + e.line.toString();
          if (e.column > 0) result += ', column ' + e.column.toString();
          result += '\n';
          if (e.line > 0 && e.line <= lines.length) {
            result += '    ' + lines[e.line - 1].trim() + '\n';
          }
          if (e.column > 0) {
            let pointer: string = '    ';
            for (let p = 1; p < e.column; p++) pointer += ' ';
            pointer += '^\n';
            result += pointer;
          }
          result += e.errorType + ': ' + e.message + '\n';
          if (i < errors.length - 1) result += '\n';
        }
        result += '═══════════════════════════════════════\n';
        result += '共 ' + errors.length.toString() + ' 个错误 | 耗时 ' + elapsed.toString() + 'ms\n';
        result += '═══════════════════════════════════════\n';
      } else if (output.length > 0) {
        // 成功执行
        result += '═══════════════════════════════════════\n';
        result += '✓ 运行成功 [' + RunHandler.getLangName(language) + ']\n';
        result += '───────────────────────────────────────\n';
        let outLines: string[] = output.split('\n');
        let lineNum: number = 1;
        for (let idx = 0; idx < outLines.length; idx++) {
          if (outLines[idx].length > 0) {
            result += ' ' + outLines[idx] + '\n';
            lineNum++;
          }
        }
        result += '───────────────────────────────────────\n';
        result += '✓ 完成 | 输出 ' + (lineNum - 1).toString() + ' 行 | 耗时 ' + elapsed.toString() + 'ms\n';
        result += '═══════════════════════════════════════\n';
      } else {
        result += '═══════════════════════════════════════\n';
        result += '✓ 执行完毕 [' + RunHandler.getLangName(language) + ']\n';
        result += '───────────────────────────────────────\n';
        result += '(无输出)\n';
        result += '💡 提示: 代码执行完毕但没有产生任何输出\n';
        result += '───────────────────────────────────────\n';
        result += '✓ 完成 | 耗时 ' + elapsed.toString() + 'ms\n';
        result += '═══════════════════════════════════════\n';
      }
    } catch (e) {
      let elapsed: number = Date.now() - startTime;
      result += '═══════════════════════════════════════\n';
      result += '✗ 系统错误\n';
      result += '───────────────────────────────────────\n';
      result += '错误: ' + String(e) + '\n';
      result += '耗时: ' + elapsed.toString() + 'ms\n';
      result += '═══════════════════════════════════════\n';
    }

    return result;
  }

  // 从输出中解析结构化错误
  static parseErrors(output: string, code: string): ErrorEntry[] {
    let errors: ErrorEntry[] = [];

    // 语法错误 - 支持 line:col 格式
    let syntaxMatch: RegExpMatchArray | null = output.match(/SyntaxError:\s*line\s*(\d+):?(\d+)?\s*-\s*(.+)/i);
    if (syntaxMatch !== null) {
      let e: ErrorEntry = new ErrorEntry();
      e.errorType = 'SyntaxError';
      e.line = parseInt(syntaxMatch[1]);
      e.column = syntaxMatch[2] !== undefined ? parseInt(syntaxMatch[2]) : 0;
      e.message = syntaxMatch[3].trim();
      e.source = RunHandler.getLine(code, e.line);
      errors.push(e);
    }

    let indentMatch: RegExpMatchArray | null = output.match(/IndentationError:\s*line\s*(\d+):?(\d+)?\s*-\s*(.+)/i);
    if (indentMatch !== null) {
      let e: ErrorEntry = new ErrorEntry();
      e.errorType = 'IndentationError';
      e.line = parseInt(indentMatch[1]);
      e.column = indentMatch[2] !== undefined ? parseInt(indentMatch[2]) : 0;
      e.message = indentMatch[3].trim();
      e.source = RunHandler.getLine(code, e.line);
      errors.push(e);
    }

    let runtimeMatch: RegExpMatchArray | null = output.match(/RuntimeError:\s*line\s*(\d+):?(\d+)?\s*-\s*(.+)/i);
    if (runtimeMatch !== null) {
      let e: ErrorEntry = new ErrorEntry();
      e.errorType = 'RuntimeError';
      e.line = parseInt(runtimeMatch[1]);
      e.column = runtimeMatch[2] !== undefined ? parseInt(runtimeMatch[2]) : 0;
      e.message = runtimeMatch[3].trim();
      e.source = RunHandler.getLine(code, e.line);
      errors.push(e);
    }

    let nameMatch: RegExpMatchArray | null = output.match(/NameError:\s*line\s*(\d+):?(\d+)?\s*-\s*(.+)/i);
    if (nameMatch !== null) {
      let e: ErrorEntry = new ErrorEntry();
      e.errorType = 'NameError';
      e.line = parseInt(nameMatch[1]);
      e.column = nameMatch[2] !== undefined ? parseInt(nameMatch[2]) : 0;
      e.message = nameMatch[3].trim();
      e.source = RunHandler.getLine(code, e.line);
      errors.push(e);
    }

    let typeMatch: RegExpMatchArray | null = output.match(/TypeError:\s*line\s*(\d+):?(\d+)?\s*-\s*(.+)/i);
    if (typeMatch !== null) {
      let e: ErrorEntry = new ErrorEntry();
      e.errorType = 'TypeError';
      e.line = parseInt(typeMatch[1]);
      e.column = typeMatch[2] !== undefined ? parseInt(typeMatch[2]) : 0;
      e.message = typeMatch[3].trim();
      e.source = RunHandler.getLine(code, e.line);
      errors.push(e);
    }

    let genericMatch: RegExpMatchArray | null = output.match(/错误:\s*line\s*(\d+)\s*-\s*(.+)/i);
    if (genericMatch !== null && errors.length === 0) {
      let e: ErrorEntry = new ErrorEntry();
      e.errorType = 'Error';
      e.line = parseInt(genericMatch[1]);
      e.column = 0;
      e.message = genericMatch[2].trim();
      e.source = RunHandler.getLine(code, e.line);
      errors.push(e);
    }

    // 无行号的通用错误
    if (errors.length === 0 && (output.includes('Error') || output.includes('错误') || output.includes('SyntaxError'))) {
      let e: ErrorEntry = new ErrorEntry();
      e.errorType = 'Error';
      e.line = 1;
      e.column = 0;
      e.message = output.split('\n')[0].trim();
      if (e.message.length > 100) {
        e.message = e.message.substring(0, 100) + '...';
      }
      e.source = '';
      errors.push(e);
    }

    return errors;
  }

  // 获取指定行的源代码，并高亮标记错误位置
  static formatSourceLine(code: string, lineNum: number): string {
    let lines: string[] = code.split('\n');
    if (lineNum > 0 && lineNum <= lines.length) {
      let line: string = lines[lineNum - 1];
      if (line.length > 80) {
        return line.substring(0, 80) + '...';
      }
      return line;
    }
    return '';
  }

  private static getLine(code: string, lineNum: number): string {
    let lines: string[] = code.split('\n');
    if (lineNum > 0 && lineNum <= lines.length) {
      let line: string = lines[lineNum - 1];
      if (line.length > 80) {
        return line.substring(0, 80) + '...';
      }
      return line;
    }
    return '';
  }

  static getLangName(lang: Language): string {
    if (lang === Language.PYTHON) {
      return 'Python 3';
    }
    if (lang === Language.RUBY) {
      return 'Ruby';
    }
    if (lang === Language.JAVASCRIPT) {
      return 'JavaScript';
    }
    if (lang === Language.TYPESCRIPT) {
      return 'TypeScript';
    }
    return '纯文本';
  }
}
