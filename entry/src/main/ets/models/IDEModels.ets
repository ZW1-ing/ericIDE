export enum Language {
  PYTHON = 'python',
  RUBY = 'ruby',
  JAVASCRIPT = 'javascript',
  TYPESCRIPT = 'typescript',
  HTML = 'html',
  CSS = 'css',
  JSON = 'json',
  MARKDOWN = 'markdown',
  PLAINTEXT = 'plaintext'
}

export class FileNode {
  name: string = '';
  path: string = '';
  isDirectory: boolean = false;
  children: FileNode[] = [];
}

export class TabItem {
  id: string = '';
  name: string = '';
  path: string = '';
  content: string = '';
  isModified: boolean = false;
  language: Language = Language.PYTHON;
}

export class IDESettings {
  fontSize: number = 14;
  fontFamily: string = 'monospace';
  theme: string = 'eric6';
  tabSize: number = 4;
  autoIndent: boolean = true;
  showLineNumbers: boolean = true;
}

export class ConsoleEntry {
  text: string = '';
  entryType: string = 'output';
  timestamp: number = 0;
}

export class VariableEntry {
  name: string = '';
  value: string = '';
  varType: string = '';
}

export class Breakpoint {
  file: string = '';
  line: number = 0;
  enabled: boolean = true;
  condition: string = '';
}

export class SearchResult {
  file: string = '';
  line: number = 0;
  column: number = 0;
  text: string = '';
}

export class ErrorEntry {
  errorType: string = '';
  message: string = '';
  line: number = 0;
  column: number = 0;
  source: string = '';
}
