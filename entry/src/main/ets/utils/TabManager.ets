import { TabItem, Language } from '../models/IDEModels';
import { FileManager } from './FileManager';

export class TabManager {
  tabs: TabItem[] = [];
  activeTabId: string = '';

  openFile(filePath: string): void {
    // 如果已打开，直接切换
    for (let i = 0; i < this.tabs.length; i++) {
      if (this.tabs[i].path === filePath) {
        this.activeTabId = this.tabs[i].id;
        return;
      }
    }
    let content: string = FileManager.readFile(filePath);
    let name: string = FileManager.getFileName(filePath);

    let tab: TabItem = new TabItem();
    tab.id = FileManager.generateId();
    tab.name = name;
    tab.path = filePath;
    tab.language = this.getLanguageForFile(name);
    tab.content = content;

    let newTabs: TabItem[] = [];
    for (let i = 0; i < this.tabs.length; i++) {
      newTabs.push(this.tabs[i]);
    }
    newTabs.push(tab);
    this.tabs = newTabs;
    this.activeTabId = tab.id;
  }

  createNewFile(): TabItem {
    let baseName: string = '新建文件';
    let newName: string = baseName;
    let counter: number = 1;
    let newPath: string = '/project/' + newName;
    while (FileManager.fileExists(newPath)) {
      counter++;
      newName = baseName + '_' + counter.toString();
      newPath = '/project/' + newName;
    }
    FileManager.writeFile(newPath, '');

    let tab: TabItem = new TabItem();
    tab.id = FileManager.generateId();
    tab.name = newName;
    tab.path = newPath;
    tab.language = Language.PYTHON;
    tab.content = '';

    let newTabs: TabItem[] = [];
    for (let i = 0; i < this.tabs.length; i++) {
      newTabs.push(this.tabs[i]);
    }
    newTabs.push(tab);
    this.tabs = newTabs;
    this.activeTabId = tab.id;
    return tab;
  }

  switchTab(tabId: string, saveCurrentContent: string): string {
    // 先保存当前活动标签的内容
    for (let i = 0; i < this.tabs.length; i++) {
      if (this.tabs[i].id === this.activeTabId) {
        this.tabs[i].content = saveCurrentContent;
        break;
      }
    }
    // 再切换到目标标签
    for (let i = 0; i < this.tabs.length; i++) {
      if (this.tabs[i].id === tabId) {
        this.activeTabId = tabId;
        return this.tabs[i].content;
      }
    }
    return saveCurrentContent;
  }

  closeTab(tabId: string): TabItem | null {
    if (this.tabs.length <= 1) return null;
    let arr: TabItem[] = [];
    let closedIdx: number = -1;
    for (let i = 0; i < this.tabs.length; i++) {
      if (this.tabs[i].id === tabId) {
        closedIdx = i;
      } else {
        arr.push(this.tabs[i]);
      }
    }
    this.tabs = arr;
    if (this.activeTabId === tabId && arr.length > 0) {
      let nextIdx: number = closedIdx >= arr.length ? arr.length - 1 : closedIdx;
      if (nextIdx < 0) nextIdx = 0;
      this.activeTabId = arr[nextIdx].id;
      return arr[nextIdx];
    }
    return null;
  }

  saveFile(filePath: string, content: string): void {
    FileManager.writeFile(filePath, content);
    for (let i = 0; i < this.tabs.length; i++) {
      if (this.tabs[i].id === this.activeTabId) {
        this.tabs[i].isModified = false;
        this.tabs[i].content = content;
        break;
      }
    }
  }

  saveFileAs(content: string, language: Language): TabItem {
    let currentName: string = this.getCurrentName();
    let dotIdx: number = currentName.lastIndexOf('.');
    let stem: string = dotIdx > 0 ? currentName.substring(0, dotIdx) : currentName;
    let ext: string = dotIdx > 0 ? currentName.substring(dotIdx) : '.py';
    let newName: string = stem + '_copy' + ext;
    let newPath: string = '/project/' + newName;
    FileManager.writeFile(newPath, content);

    let tab: TabItem = new TabItem();
    tab.id = FileManager.generateId();
    tab.name = newName;
    tab.path = newPath;
    tab.language = language;
    tab.content = content;

    let newTabs: TabItem[] = [];
    for (let i = 0; i < this.tabs.length; i++) {
      newTabs.push(this.tabs[i]);
    }
    newTabs.push(tab);
    this.tabs = newTabs;
    this.activeTabId = tab.id;
    return tab;
  }

  markModified(tabId: string): void {
    for (let i = 0; i < this.tabs.length; i++) {
      if (this.tabs[i].id === tabId) {
        this.tabs[i].isModified = true;
        break;
      }
    }
  }

  getCurrentName(): string {
    for (let i = 0; i < this.tabs.length; i++) {
      if (this.tabs[i].id === this.activeTabId) return this.tabs[i].name;
    }
    return '';
  }

  getCurrentLanguage(): Language {
    for (let i = 0; i < this.tabs.length; i++) {
      if (this.tabs[i].id === this.activeTabId) return this.tabs[i].language;
    }
    return Language.PYTHON;
  }

  getCurrentPath(): string {
    for (let i = 0; i < this.tabs.length; i++) {
      if (this.tabs[i].id === this.activeTabId) return this.tabs[i].path;
    }
    return '';
  }

  private getLanguageForFile(name: string): Language {
    if (name.endsWith('.py') || name.endsWith('.pyw')) return Language.PYTHON;
    if (name.endsWith('.rb')) return Language.RUBY;
    if (name.endsWith('.js')) return Language.JAVASCRIPT;
    if (name.endsWith('.ts')) return Language.TYPESCRIPT;
    if (name.endsWith('.json')) return Language.JSON;
    if (name.endsWith('.md')) return Language.MARKDOWN;
    return Language.PLAINTEXT;
  }
}
