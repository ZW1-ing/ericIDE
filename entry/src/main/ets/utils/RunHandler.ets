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
        result += '═══════════════════════════════════════\n';
        result += '✗ ' + errors.length.toString() + ' 个错误\n';
        result += '═══════════════════════════════════════\n';
        for (let i = 0; i < errors.length; i++) {
          let e: ErrorEntry = errors[i];
          let lines: string[] = code.split('\n');
          result += '\n';
          result += '错误 ' + (i + 1).toString() + ': ' + e.errorType + '\n';
          result += '───────────────────────────────────────\n';

          // 上下文：上一行
          if (e.line > 1 && e.line - 2 < lines.length) {
            result += '  ' + (e.line - 1).toString() + ' │ ' + lines[e.line - 2] + '\n';
          }

          // 错误行
          if (e.line <= lines.length) {
            result += '▶ ' + e.line.toString() + ' │ ' + lines[e.line - 1] + '\n';
          }

          // 错误指示
          if (e.column > 0) {
            let pointer: string = '    ';
            let lineNumWidth: number = e.line.toString().length;
            for (let p = 0; p < lineNumWidth + 3 + e.column - 1; p++) {
              pointer += ' ';
            }
            pointer += '^── ' + e.message;
            result += pointer + '\n';
          } else {
            result += '    ' + e.message + '\n';
          }

          // 上下文：下一行
          if (e.line < lines.length) {
            result += '  ' + (e.line + 1).toString() + ' │ ' + lines[e.line] + '\n';
          }

          // 修复提示
          if (e.errorType === 'SyntaxError') {
            if (e.message.includes('parenthesis') || e.message.includes('括号')) {
              result += '  💡 检查括号是否配对\n';
            } else if (e.message.includes('colon') || e.message.includes('冒号')) {
              result += '  💡 语句末尾需要加冒号 :\n';
            } else {
              result += '  💡 检查语法是否正确\n';
            }
          } else if (e.errorType === 'IndentationError') {
            result += '  💡 检查缩进是否统一，建议使用4个空格\n';
          } else if (e.errorType === 'NameError') {
            result += '  💡 变量未定义，请检查拼写或先赋值\n';
          } else if (e.errorType === 'TypeError') {
            result += '  💡 类型不匹配，检查运算或函数参数\n';
          } else if (e.errorType === 'RuntimeError') {
            result += '  💡 运行时出错，检查逻辑和数据\n';
          }
          result += '\n';
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

    // 语法错误
    let syntaxMatch: RegExpMatchArray | null = output.match(/SyntaxError:\s*line\s*(\d+)\s*-\s*(.+)/i);
    if (syntaxMatch !== null) {
      let e: ErrorEntry = new ErrorEntry();
      e.errorType = 'SyntaxError';
      e.line = parseInt(syntaxMatch[1]);
      e.column = 0;
      e.message = syntaxMatch[2].trim();
      e.source = RunHandler.getLine(code, e.line);
      errors.push(e);
    }

    // 缩进错误
    let indentMatch: RegExpMatchArray | null = output.match(/IndentationError:\s*line\s*(\d+)\s*-\s*(.+)/i);
    if (indentMatch !== null) {
      let e: ErrorEntry = new ErrorEntry();
      e.errorType = 'IndentationError';
      e.line = parseInt(indentMatch[1]);
      e.column = 0;
      e.message = indentMatch[2].trim();
      e.source = RunHandler.getLine(code, e.line);
      errors.push(e);
    }

    // 运行时错误
    let runtimeMatch: RegExpMatchArray | null = output.match(/RuntimeError:\s*line\s*(\d+)\s*-\s*(.+)/i);
    if (runtimeMatch !== null) {
      let e: ErrorEntry = new ErrorEntry();
      e.errorType = 'RuntimeError';
      e.line = parseInt(runtimeMatch[1]);
      e.column = 0;
      e.message = runtimeMatch[2].trim();
      e.source = RunHandler.getLine(code, e.line);
      errors.push(e);
    }

    // 名称错误 (NameError)
    let nameMatch: RegExpMatchArray | null = output.match(/NameError:\s*line\s*(\d+)\s*-\s*(.+)/i);
    if (nameMatch !== null) {
      let e: ErrorEntry = new ErrorEntry();
      e.errorType = 'NameError';
      e.line = parseInt(nameMatch[1]);
      e.column = 0;
      e.message = nameMatch[2].trim();
      e.source = RunHandler.getLine(code, e.line);
      errors.push(e);
    }

    // 类型错误 (TypeError)
    let typeMatch: RegExpMatchArray | null = output.match(/TypeError:\s*line\s*(\d+)\s*-\s*(.+)/i);
    if (typeMatch !== null) {
      let e: ErrorEntry = new ErrorEntry();
      e.errorType = 'TypeError';
      e.line = parseInt(typeMatch[1]);
      e.column = 0;
      e.message = typeMatch[2].trim();
      e.source = RunHandler.getLine(code, e.line);
      errors.push(e);
    }

    // 通用错误 (带行号)
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
