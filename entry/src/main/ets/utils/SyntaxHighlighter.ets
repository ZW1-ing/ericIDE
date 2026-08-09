import { Language } from '../models/IDEModels';

let g_pythonKeywords: string[] = [
  'False', 'None', 'True', 'and', 'as', 'assert', 'async', 'await',
  'break', 'class', 'continue', 'def', 'del', 'elif', 'else', 'except',
  'finally', 'for', 'from', 'global', 'if', 'import', 'in', 'is',
  'lambda', 'nonlocal', 'not', 'or', 'pass', 'raise', 'return',
  'try', 'while', 'with', 'yield'
];

let g_rubyKeywords: string[] = [
  'BEGIN', 'END', 'alias', 'and', 'begin', 'break', 'case', 'class',
  'def', 'defined', 'do', 'else', 'elsif', 'end', 'ensure', 'false',
  'for', 'if', 'in', 'module', 'next', 'nil', 'not', 'or', 'redo',
  'rescue', 'retry', 'return', 'self', 'super', 'then', 'true',
  'undef', 'unless', 'until', 'when', 'while', 'yield'
];

let g_javascriptKeywords: string[] = [
  'async', 'await', 'break', 'case', 'catch', 'class', 'const',
  'continue', 'debugger', 'default', 'delete', 'do', 'else', 'enum',
  'export', 'extends', 'false', 'finally', 'for', 'function', 'if',
  'import', 'in', 'instanceof', 'let', 'new', 'null', 'of', 'return',
  'super', 'switch', 'this', 'throw', 'true', 'try', 'typeof',
  'undefined', 'var', 'void', 'while', 'with', 'yield'
];

export class SyntaxHighlighter {
  static getKeywords(language: Language): string[] {
    if (language === Language.PYTHON) {
      return g_pythonKeywords;
    }
    if (language === Language.RUBY) {
      return g_rubyKeywords;
    }
    if (language === Language.JAVASCRIPT || language === Language.TYPESCRIPT) {
      return g_javascriptKeywords;
    }
    return g_pythonKeywords;
  }

  static getFileExtension(language: Language): string {
    if (language === Language.PYTHON) {
      return '.py';
    }
    if (language === Language.RUBY) {
      return '.rb';
    }
    if (language === Language.JAVASCRIPT) {
      return '.js';
    }
    if (language === Language.TYPESCRIPT) {
      return '.ts';
    }
    if (language === Language.HTML) {
      return '.html';
    }
    if (language === Language.CSS) {
      return '.css';
    }
    if (language === Language.JSON) {
      return '.json';
    }
    if (language === Language.MARKDOWN) {
      return '.md';
    }
    return '.txt';
  }

  static getLanguageFromExtension(ext: string): Language {
    if (ext === '.py' || ext === '.pyw') {
      return Language.PYTHON;
    }
    if (ext === '.rb') {
      return Language.RUBY;
    }
    if (ext === '.js') {
      return Language.JAVASCRIPT;
    }
    if (ext === '.ts') {
      return Language.TYPESCRIPT;
    }
    if (ext === '.html' || ext === '.htm') {
      return Language.HTML;
    }
    if (ext === '.css') {
      return Language.CSS;
    }
    if (ext === '.json') {
      return Language.JSON;
    }
    if (ext === '.md' || ext === '.markdown') {
      return Language.MARKDOWN;
    }
    return Language.PLAINTEXT;
  }

  static getLanguageDisplayName(language: Language): string {
    if (language === Language.PYTHON) {
      return 'Python 3';
    }
    if (language === Language.RUBY) {
      return 'Ruby';
    }
    if (language === Language.JAVASCRIPT) {
      return 'JavaScript';
    }
    if (language === Language.TYPESCRIPT) {
      return 'TypeScript';
    }
    if (language === Language.HTML) {
      return 'HTML';
    }
    if (language === Language.CSS) {
      return 'CSS';
    }
    if (language === Language.JSON) {
      return 'JSON';
    }
    if (language === Language.MARKDOWN) {
      return 'Markdown';
    }
    return '纯文本';
  }
}
