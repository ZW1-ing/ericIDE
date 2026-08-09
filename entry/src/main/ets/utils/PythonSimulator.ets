import { Language } from '../models/IDEModels';

class RunContext {
  globals: Map<string, string> = new Map();
  output: string = '';
  breakFlag: boolean = false;
  continueFlag: boolean = false;
  currentLine: number = 0;

  lookup(name: string): string {
    if (this.globals.has(name)) {
      let val: string | undefined = this.globals.get(name);
      if (val !== undefined) {
        return val;
      }
    }
    return name;
  }

  setVar(name: string, val: string): void {
    this.globals.set(name, val);
  }

  appendOutput(text: string): void {
    this.output += text + '\n';
  }
}

export class PythonSimulator {

  private static getIndent(line: string): number {
    let count: number = 0;
    for (let i = 0; i < line.length; i++) {
      if (line[i] === ' ') {
        count++;
      } else if (line[i] === '\t') {
        count += 4;
      } else {
        break;
      }
    }
    return count;
  }

  private static collectBody(lines: string[], startIdx: number, baseIndent: number): string[] {
    let body: string[] = [];
    for (let i = startIdx; i < lines.length; i++) {
      let trimmed: string = lines[i].trim();
      if (trimmed.length === 0) {
        continue;
      }
      if (PythonSimulator.getIndent(lines[i]) <= baseIndent) {
        break;
      }
      body.push(lines[i]);
    }
    return body;
  }

  private static isCompoundAssignment(line: string): boolean {
    let ops: string[] = ['+=', '-=', '*=', '/='];
    for (let op of ops) {
      let idx: number = line.indexOf(op);
      if (idx > 0) {
        let left: string = line.substring(0, idx).trim();
        if (left.length > 0 && !left.includes(' ') && !left.includes('(') && !left.includes(')')) {
          return true;
        }
      }
    }
    return false;
  }

  private static isAssignment(line: string): boolean {
    if (PythonSimulator.isCompoundAssignment(line)) return true;
    let eqIdx: number = line.indexOf('=');
    if (eqIdx < 1) return false;
    let left: string = line.substring(0, eqIdx).trim();
    if (left.includes('(') || left.includes(')')) return false;
    if (left.endsWith('>') || left.endsWith('<') || left.endsWith('!') || left.endsWith('=') ||
        left.endsWith('+') || left.endsWith('-') || left.endsWith('*') || left.endsWith('/')) return false;
    if (left.startsWith('if ') || left.startsWith('elif ') || left.startsWith('while ') || left.startsWith('for ')) return false;
    return true;
  }

  private static doAssignment(line: string, ctx: RunContext): void {
    let compoundOps: string[] = ['+=', '-=', '*=', '/='];
    for (let cop of compoundOps) {
      let cidx: number = line.indexOf(cop);
      if (cidx > 0) {
        let varName: string = line.substring(0, cidx).trim();
        let rightExpr: string = line.substring(cidx + 2).trim();
        let currentVal: string = ctx.lookup(varName);
        let rightVal: string = PythonSimulator.evalExpr(rightExpr, ctx);

        let currentIsStr: boolean = (currentVal.startsWith('"') && currentVal.endsWith('"')) ||
          (currentVal.startsWith("'") && currentVal.endsWith("'"));
        let rightIsStr: boolean = (rightVal.startsWith('"') && rightVal.endsWith('"')) ||
          (rightVal.startsWith("'") && rightVal.endsWith("'"));

        if (cop === '+=' && (currentIsStr || rightIsStr)) {
          let ls: string = currentIsStr ? currentVal.substring(1, currentVal.length - 1) : currentVal;
          let rs: string = rightIsStr ? rightVal.substring(1, rightVal.length - 1) : rightVal;
          ctx.setVar(varName, '"' + ls + rs + '"');
          return;
        }

        let leftNum: number = parseFloat(currentIsStr ? currentVal.substring(1, currentVal.length - 1) : currentVal);
        let rightNum: number = parseFloat(rightIsStr ? rightVal.substring(1, rightVal.length - 1) : rightVal);
        if (!isNaN(leftNum) && !isNaN(rightNum)) {
          let result: number = 0;
          if (cop === '+=') result = leftNum + rightNum;
          else if (cop === '-=') result = leftNum - rightNum;
          else if (cop === '*=') result = leftNum * rightNum;
          else if (cop === '/=') {
            if (rightNum === 0) return;
            result = leftNum / rightNum;
          }
          ctx.setVar(varName, String(result));
        }
        return;
      }
    }

    let eqIdx: number = line.indexOf('=');
    let left: string = line.substring(0, eqIdx).trim();
    let right: string = line.substring(eqIdx + 1).trim();

    if (left.includes(',')) {
      let names: string[] = left.split(',').map((s: string) => s.trim());
      if (right.includes(',')) {
        let vals: string[] = PythonSimulator.splitArgs(right);
        for (let i = 0; i < names.length && i < vals.length; i++) {
          ctx.setVar(names[i], PythonSimulator.evalExpr(vals[i], ctx));
        }
      }
      return;
    }
    ctx.setVar(left, PythonSimulator.evalExpr(right, ctx));
  }

  private static splitArgs(argsStr: string): string[] {
    let args: string[] = [];
    let depth: number = 0;
    let current: string = '';
    let inStr: string = '';
    for (let i = 0; i < argsStr.length; i++) {
      let ch: string = argsStr[i];
      if (inStr.length > 0) {
        current += ch;
        if (ch === inStr) inStr = '';
        continue;
      }
      if (ch === '"' || ch === '\'') {
        inStr = ch;
        current += ch;
      } else if (ch === '(') {
        depth++;
        current += ch;
      } else if (ch === ')') {
        depth--;
        current += ch;
      } else if (ch === ',' && depth === 0) {
        args.push(current.trim());
        current = '';
      } else {
        current += ch;
      }
    }
    if (current.trim().length > 0) {
      args.push(current.trim());
    }
    return args;
  }

  private static evalExpr(expr: string, ctx: RunContext): string {
    expr = expr.trim();

    if ((expr.startsWith('"') && expr.endsWith('"')) || (expr.startsWith("'") && expr.endsWith("'"))) {
      return expr;
    }

    if (expr === 'True') return 'True';
    if (expr === 'False') return 'False';
    if (expr === 'None') return 'None';

    if (expr.startsWith('f"') || expr.startsWith("f'")) {
      let quote: string = expr[1];
      let inner: string = expr.substring(2, expr.length - 1);
      let result: string = '';
      let i: number = 0;
      while (i < inner.length) {
        if (inner[i] === '{' && i + 1 < inner.length && inner[i + 1] !== '{') {
          let depth: number = 1;
          let j: number = i + 1;
          while (j < inner.length && depth > 0) {
            if (inner[j] === '{') depth++;
            if (inner[j] === '}') depth--;
            j++;
          }
          let placeholder: string = inner.substring(i + 1, j - 1);
          let val: string = PythonSimulator.evalExpr(placeholder, ctx);
          if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
            val = val.substring(1, val.length - 1);
          }
          result += val;
          i = j;
        } else {
          result += inner[i];
          i++;
        }
      }
      return '"' + result + '"';
    }

    if (expr.includes('+') && !expr.startsWith('-')) {
      let parts: string[] = PythonSimulator.splitAddExpr(expr);
      if (parts.length > 1) {
        let isStr: boolean = false;
        let strs: string[] = [];
        for (let p of parts) {
          let v: string = PythonSimulator.evalExpr(p, ctx);
          if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
            isStr = true;
            strs.push(v.substring(1, v.length - 1));
          } else {
            strs.push(v);
          }
        }
        if (isStr) {
          let combined: string = '';
          for (let s of strs) {
            combined += s;
          }
          return '"' + combined + '"';
        }
        let numResult: number = 0;
        for (let s of strs) {
          numResult += parseFloat(s);
        }
        return String(numResult);
      }
    }

    if (ctx.globals.has(expr)) {
      return ctx.lookup(expr);
    }

    // 检测未定义变量的引用
    if (/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(expr) && !ctx.globals.has(expr)) {
      return 'NameError: line ' + ctx.currentLine.toString() + ' - 变量 \'' + expr + '\' 未定义';
    }

    if (/^-?\d+(\.\d+)?$/.test(expr)) {
      return expr;
    }

    return expr;
  }

  private static splitAddExpr(expr: string): string[] {
    let parts: string[] = [];
    let current: string = '';
    let depth: number = 0;
    let inStr: string = '';
    for (let i = 0; i < expr.length; i++) {
      let ch: string = expr[i];
      if (inStr.length > 0) {
        current += ch;
        if (ch === inStr) inStr = '';
        continue;
      }
      if (ch === '"' || ch === '\'') {
        inStr = ch;
        current += ch;
      } else if (ch === '(') {
        depth++;
        current += ch;
      } else if (ch === ')') {
        depth--;
        current += ch;
      } else if (ch === '+' && depth === 0) {
        if (current.trim().length > 0) {
          parts.push(current.trim());
        }
        current = '';
      } else {
        current += ch;
      }
    }
    if (current.trim().length > 0) {
      parts.push(current.trim());
    }
    return parts;
  }

  private static evalCondition(cond: string, ctx: RunContext): boolean {
    cond = cond.trim();

    if (cond === 'True') return true;
    if (cond === 'False') return false;

    if (cond.includes(' and ')) {
      let parts: string[] = cond.split(' and ');
      for (let p of parts) {
        if (!PythonSimulator.evalCondition(p, ctx)) return false;
      }
      return true;
    }
    if (cond.includes(' or ')) {
      let parts: string[] = cond.split(' or ');
      for (let p of parts) {
        if (PythonSimulator.evalCondition(p, ctx)) return true;
      }
      return false;
    }
    if (cond.startsWith('not ')) {
      return !PythonSimulator.evalCondition(cond.substring(4), ctx);
    }

    let ops: string[] = ['>=', '<=', '!=', '==', '>', '<'];
    for (let op of ops) {
      let idx: number = cond.indexOf(op);
      if (idx > 0) {
        let leftStr: string = cond.substring(0, idx).trim();
        let rightStr: string = cond.substring(idx + op.length).trim();
        let leftVal: string = PythonSimulator.evalExpr(leftStr, ctx);
        let rightVal: string = PythonSimulator.evalExpr(rightStr, ctx);

        let leftIsStr: boolean = (leftVal.startsWith('"') && leftVal.endsWith('"')) ||
          (leftVal.startsWith("'") && leftVal.endsWith("'"));
        let rightIsStr: boolean = (rightVal.startsWith('"') && rightVal.endsWith('"')) ||
          (rightVal.startsWith("'") && rightVal.endsWith("'"));

        if (leftIsStr || rightIsStr) {
          let ls: string = leftIsStr ? leftVal.substring(1, leftVal.length - 1) : leftVal;
          let rs: string = rightIsStr ? rightVal.substring(1, rightVal.length - 1) : rightVal;
          if (op === '==') return ls === rs;
          if (op === '!=') return ls !== rs;
          if (op === '>') return ls > rs;
          if (op === '<') return ls < rs;
          if (op === '>=') return ls >= rs;
          if (op === '<=') return ls <= rs;
        } else {
          let ln: number = parseFloat(leftVal);
          let rn: number = parseFloat(rightVal);
          if (op === '==') return ln === rn;
          if (op === '!=') return ln !== rn;
          if (op === '>') return ln > rn;
          if (op === '<') return ln < rn;
          if (op === '>=') return ln >= rn;
          if (op === '<=') return ln <= rn;
        }
        return false;
      }
    }

    return PythonSimulator.evalExpr(cond, ctx) !== 'False';
  }

  private static execIfChain(lines: string[], startIdx: number, ctx: RunContext): number {
    let i: number = startIdx;
    let executed: boolean = false;
    let skipUntilNext: boolean = false;

    while (i < lines.length) {
      let trimmed: string = lines[i].trim();
      if (trimmed.length === 0) { i++; continue; }

      let isBranch: boolean = trimmed.startsWith('if ') || trimmed.startsWith('elif ') || trimmed.startsWith('else:');
      if (isBranch && i > startIdx) {
        if (executed) {
          skipUntilNext = true;
        }
      }

      if (!isBranch && i > startIdx) {
        break;
      }

      if (trimmed.startsWith('if ') && trimmed.endsWith(':')) {
        let cond: string = trimmed.substring(3, trimmed.length - 1).trim();
        executed = PythonSimulator.evalCondition(cond, ctx);
        skipUntilNext = !executed;
      } else if (trimmed.startsWith('elif ') && trimmed.endsWith(':')) {
        if (executed) {
          skipUntilNext = true;
        } else {
          let cond: string = trimmed.substring(5, trimmed.length - 1).trim();
          executed = PythonSimulator.evalCondition(cond, ctx);
          skipUntilNext = !executed;
        }
      } else if (trimmed === 'else:') {
        if (executed) {
          skipUntilNext = true;
        } else {
          executed = true;
          skipUntilNext = false;
        }
      } else {
        if (!skipUntilNext) {
          PythonSimulator.executeLine(trimmed, ctx);
        }
      }
      i++;
    }
    return i - startIdx;
  }

  private static execForLoop(lines: string[], startIdx: number, ctx: RunContext): number {
    let trimmed: string = lines[startIdx].trim();
    let body: string[] = PythonSimulator.collectBody(lines, startIdx + 1, PythonSimulator.getIndent(lines[startIdx]));

    let iterPart: string = trimmed.substring(4, trimmed.length - 1).trim();
    let inIdx: number = iterPart.indexOf(' in ');
    if (inIdx < 0) return 1 + body.length;

    let varName: string = iterPart.substring(0, inIdx).trim();
    let rangeExpr: string = iterPart.substring(inIdx + 4).trim();

    let iterValues: string[] = PythonSimulator.resolveRange(rangeExpr, ctx);

    let totalLines: number = 1 + body.length;
    for (let val of iterValues) {
      ctx.setVar(varName, val);
      for (let bLine of body) {
        let bTrimmed: string = bLine.trim();
        if (bTrimmed.length === 0) continue;
        PythonSimulator.executeLine(bTrimmed, ctx);
        if (ctx.breakFlag) { ctx.breakFlag = false; return totalLines; }
        if (ctx.continueFlag) { ctx.continueFlag = false; continue; }
      }
    }
    return totalLines;
  }

  private static resolveRange(rangeExpr: string, ctx: RunContext): string[] {
    rangeExpr = rangeExpr.trim();
    if (rangeExpr.startsWith('range(') && rangeExpr.endsWith(')')) {
      let argsStr: string = rangeExpr.substring(6, rangeExpr.length - 1).trim();
      let args: string[] = PythonSimulator.splitArgs(argsStr);
      let startVal: number = 0;
      let endVal: number = 0;
      let stepVal: number = 1;

      if (args.length === 1) {
        endVal = parseInt(PythonSimulator.evalExpr(args[0], ctx));
      } else if (args.length === 2) {
        startVal = parseInt(PythonSimulator.evalExpr(args[0], ctx));
        endVal = parseInt(PythonSimulator.evalExpr(args[1], ctx));
      } else if (args.length >= 3) {
        startVal = parseInt(PythonSimulator.evalExpr(args[0], ctx));
        endVal = parseInt(PythonSimulator.evalExpr(args[1], ctx));
        stepVal = parseInt(PythonSimulator.evalExpr(args[2], ctx));
      }

      let result: string[] = [];
      if (stepVal > 0) {
        for (let v: number = startVal; v < endVal; v += stepVal) {
          result.push(String(v));
        }
      } else if (stepVal < 0) {
        for (let v: number = startVal; v > endVal; v += stepVal) {
          result.push(String(v));
        }
      }
      return result;
    }

    if (ctx.globals.has(rangeExpr)) {
      let val: string = ctx.lookup(rangeExpr);
      if (val.startsWith('[') && val.endsWith(']')) {
        let inner: string = val.substring(1, val.length - 1);
        if (inner.length === 0) return [];
        return PythonSimulator.splitArgs(inner);
      }
    }

    return [];
  }

  private static execWhileLoop(lines: string[], startIdx: number, ctx: RunContext): number {
    let trimmed: string = lines[startIdx].trim();
    let condStr: string = trimmed.substring(6, trimmed.length - 1).trim();
    let body: string[] = PythonSimulator.collectBody(lines, startIdx + 1, PythonSimulator.getIndent(lines[startIdx]));

    let maxIter: number = 1000;
    let iterCount: number = 0;
    while (iterCount < maxIter && PythonSimulator.evalCondition(condStr, ctx)) {
      for (let bLine of body) {
        let bTrimmed: string = bLine.trim();
        if (bTrimmed.length === 0) continue;
        PythonSimulator.executeLine(bTrimmed, ctx);
        if (ctx.breakFlag) { ctx.breakFlag = false; return 1 + body.length; }
        if (ctx.continueFlag) { ctx.continueFlag = false; continue; }
      }
      iterCount++;
    }
    return 1 + body.length;
  }

  private static executeLine(line: string, ctx: RunContext): void {
    if (line.length === 0 || line.startsWith('#')) return;

    if (line === 'break') { ctx.breakFlag = true; return; }
    if (line === 'continue') { ctx.continueFlag = true; return; }
    if (line === 'pass') return;

    if (line.startsWith('print(') && line.endsWith(')')) {
      let inner: string = line.substring(6, line.length - 1).trim();
      if (inner.length === 0) {
        ctx.appendOutput('');
        return;
      }
      let args: string[] = PythonSimulator.splitArgs(inner);
      let result: string = '';
      for (let i = 0; i < args.length; i++) {
        let val: string = PythonSimulator.evalExpr(args[i], ctx);
        if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
          val = val.substring(1, val.length - 1);
        }
        if (i > 0) result += ' ';
        result += val;
      }
      ctx.appendOutput(result);
      return;
    }

    if (PythonSimulator.isAssignment(line)) {
      PythonSimulator.doAssignment(line, ctx);
      return;
    }

    if (line.includes('(') && line.endsWith(')')) {
      PythonSimulator.evalExpr(line, ctx);
    }
  }

  private static executeBlock(body: string[], ctx: RunContext): void {
    let i: number = 0;
    while (i < body.length) {
      let trimmed: string = body[i].trim();
      ctx.currentLine++;
      if (trimmed.length === 0 || trimmed.startsWith('#')) { i++; continue; }

      if (trimmed.startsWith('for ') && trimmed.endsWith(':')) {
        i += PythonSimulator.execForLoop(body, i, ctx);
        continue;
      }
      if (trimmed.startsWith('while ') && trimmed.endsWith(':')) {
        i += PythonSimulator.execWhileLoop(body, i, ctx);
        continue;
      }
      if (trimmed.startsWith('if ') && trimmed.endsWith(':')) {
        i += PythonSimulator.execIfChain(body, i, ctx);
        continue;
      }
      PythonSimulator.executeLine(trimmed, ctx);
      i++;
    }
  }

  private static checkSyntax(code: string): string | null {
    let lines: string[] = code.split('\n');
    let openParens: number = 0;
    let openBrackets: number = 0;
    let openBraces: number = 0;
    let openQuotes: number = 0;
    let lastIndent: number = 0;

    for (let i = 0; i < lines.length; i++) {
      let trimmed: string = lines[i].trim();
      let indent: number = PythonSimulator.getIndent(lines[i]);
      if (trimmed.length === 0 || trimmed.startsWith('#')) continue;

      // 缩进检查
      if (indent > lastIndent && lastIndent === 0 && i > 0 && trimmed.length > 0) {
        let prevTrimmed: string = '';
        for (let p = i - 1; p >= 0; p--) {
          if (lines[p].trim().length > 0) { prevTrimmed = lines[p].trim(); break; }
        }
        if (!prevTrimmed.endsWith(':') && trimmed.length > 0) {
          return 'IndentationError: line ' + (i + 1).toString() + ' - 意外的缩进，上一行不是复合语句';
        }
      }

      // 冒号检查：复合语句必须以冒号结尾
      let compoundStarts: string[] = ['if ', 'elif ', 'else', 'for ', 'while ', 'def ', 'class ', 'try', 'except', 'finally', 'with '];
      let isCompound: boolean = false;
      for (let k of compoundStarts) {
        if (trimmed.startsWith(k)) { isCompound = true; break; }
      }
      if (isCompound && !trimmed.endsWith(':')) {
        return 'SyntaxError: line ' + (i + 1).toString() + ' - 复合语句缺少冒号 :';
      }

      // 引号检查
      let inStr: string = '';
      for (let j = 0; j < trimmed.length; j++) {
        let ch: string = trimmed[j];
        if (inStr.length > 0) {
          if (ch === inStr) inStr = '';
          continue;
        }
        if (ch === '"' || ch === '\'' || ch === '`') {
          inStr = ch;
          openQuotes++;
        } else if (ch === '(') {
          openParens++;
        } else if (ch === ')') {
          openParens--;
        } else if (ch === '[') {
          openBrackets++;
        } else if (ch === ']') {
          openBrackets--;
        } else if (ch === '{') {
          openBraces++;
        } else if (ch === '}') {
          openBraces--;
        }
      }
      if (inStr.length > 0) {
        return 'SyntaxError: line ' + (i + 1).toString() + ' - 字符串引号未闭合';
      }

      if (openParens < 0) return 'SyntaxError: line ' + (i + 1).toString() + ' - 多余的右括号 )';
      if (openBrackets < 0) return 'SyntaxError: line ' + (i + 1).toString() + ' - 多余的右方括号 ]';
      if (openBraces < 0) return 'SyntaxError: line ' + (i + 1).toString() + ' - 多余的右花括号 }';

      lastIndent = indent;
    }

    if (openParens > 0) return 'SyntaxError: line ' + lines.length.toString() + ' - 缺少 ' + openParens.toString() + ' 个右括号 )';
    if (openBrackets > 0) return 'SyntaxError: line ' + lines.length.toString() + ' - 缺少 ' + openBrackets.toString() + ' 个右方括号 ]';
    if (openBraces > 0) return 'SyntaxError: line ' + lines.length.toString() + ' - 缺少 ' + openBraces.toString() + ' 个右花括号 }';

    return null;
  }

  static run(code: string, language: Language): string {
    if (language === Language.RUBY) {
      return '[Ruby] runtime not integrated, please use Python';
    }

    let syntaxErr: string | null = PythonSimulator.checkSyntax(code);
    if (syntaxErr !== null) {
      return syntaxErr;
    }

    let ctx: RunContext = new RunContext();
    let codeLines: string[] = code.split('\n');

    let funcDefs: Map<string, string[]> = new Map();
    let i: number = 0;
    while (i < codeLines.length) {
      let trimmed: string = codeLines[i].trim();
      if (trimmed.startsWith('def ') && trimmed.endsWith(':')) {
        let funcName: string = trimmed.substring(4, trimmed.length - 1).trim();
        let parenIdx: number = funcName.indexOf('(');
        if (parenIdx >= 0) {
          funcName = funcName.substring(0, parenIdx).trim();
        }
        let baseIndent: number = PythonSimulator.getIndent(codeLines[i]);
        let bodyLines: string[] = PythonSimulator.collectBody(codeLines, i + 1, baseIndent);
        funcDefs.set(funcName, bodyLines);
        i += bodyLines.length + 1;
        continue;
      }
      i++;
    }

    i = 0;
    while (i < codeLines.length) {
      ctx.currentLine = i + 1;
      let trimmed: string = codeLines[i].trim();
      if (trimmed.length === 0 || trimmed.startsWith('#') || trimmed.startsWith('import ')) {
        i++;
        continue;
      }

      if (trimmed.startsWith('def ') && trimmed.endsWith(':')) {
        let baseIndent: number = PythonSimulator.getIndent(codeLines[i]);
        let body: string[] = PythonSimulator.collectBody(codeLines, i + 1, baseIndent);
        i += body.length + 1;
        continue;
      }

      if (trimmed.startsWith('if __name__')) {
        let baseIndent: number = PythonSimulator.getIndent(codeLines[i]);
        let body: string[] = PythonSimulator.collectBody(codeLines, i + 1, baseIndent);
        PythonSimulator.executeBlock(body, ctx);
        i += body.length + 1;
        continue;
      }

      if (trimmed.startsWith('print(') && trimmed.endsWith(')')) {
        let inner: string = trimmed.substring(6, trimmed.length - 1);
        let val: string = PythonSimulator.evalExpr(inner, ctx);
        if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
          val = val.substring(1, val.length - 1);
        }
        ctx.appendOutput(val);
        i++;
        continue;
      }

      if (trimmed.startsWith('for ') && trimmed.endsWith(':')) {
        i += PythonSimulator.execForLoop(codeLines, i, ctx);
        continue;
      }

      if (trimmed.startsWith('while ') && trimmed.endsWith(':')) {
        i += PythonSimulator.execWhileLoop(codeLines, i, ctx);
        continue;
      }

      if (trimmed.startsWith('if ') && trimmed.endsWith(':')) {
        i += PythonSimulator.execIfChain(codeLines, i, ctx);
        continue;
      }

      if (PythonSimulator.isAssignment(trimmed)) {
        PythonSimulator.doAssignment(trimmed, ctx);
        i++;
        continue;
      }

      if (trimmed.includes('(') && trimmed.endsWith(')') && !trimmed.startsWith('if ') && !trimmed.startsWith('for ') && !trimmed.startsWith('while ') && !trimmed.startsWith('def ')) {
        PythonSimulator.evalExpr(trimmed, ctx);
        i++;
        continue;
      }

      i++;
    }

    let output: string = ctx.output;
    if (output.endsWith('\n')) {
      output = output.substring(0, output.length - 1);
    }
    // 保存最后执行的变量
    PythonSimulator.lastGlobals = ctx.globals;
    return output;
  }

  private static lastGlobals: Map<string, string> = new Map();

  static getLastVariables(): Map<string, string> {
    return PythonSimulator.lastGlobals;
  }
}
