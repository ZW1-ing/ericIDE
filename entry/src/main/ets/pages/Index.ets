import { Language, TabItem, ConsoleEntry, IDESettings, SearchResult, FileNode, ErrorEntry, VariableEntry } from '../models/IDEModels';
import { FileManager } from '../utils/FileManager';
import { TabManager } from '../utils/TabManager';
import { UndoManager } from '../utils/UndoManager';
import { ClipboardManager } from '../utils/ClipboardManager';
import { DialogManager, DeleteResult } from '../utils/DialogManager';
import { ActionRouter } from '../utils/ActionRouter';
import { RunHandler } from '../utils/RunHandler';
import { PythonSimulator } from '../utils/PythonSimulator';
import { TitleBar } from './TitleBar';
import { MenuBar } from './MenuBar';
import { ToolBar } from './ToolBar';
import { ActivityBar } from './ActivityBar';
import { SideBar } from './SideBar';
import { EditorTabBar } from './TabBar';
import { CodeEditor } from './CodeEditor';
import { BottomPanel } from './BottomPanel';
import { RightPanel } from './RightPanel';
import { StatusBar } from './StatusBar';
import { CommandPalette } from './Overlays';
import { RenameDialog } from './RenameDialog';
import { DeleteDialog } from './DeleteDialog';

@Entry
@Component
struct Index {
  // === 编辑器状态 ===
  @State editorContent: string = '';
  @State codeLines: string[] = [''];
  @State consoleEntries: ConsoleEntry[] = [];
  @State settings: IDESettings = new IDESettings();

  // === 面板可见性 ===
  @State showFileTree: boolean = true;
  @State showRightPanel: boolean = false;
  @State showSearch: boolean = false;
  @State bottomCollapsed: boolean = false;

  // === 面板标签 ===
  @State bottomTab: string = 'terminal';
  @State rightPanelTab: string = 'variables';
  @State activityBarIcon: string = 'files';

  // === 文件树 ===
  @State expandedFolders: string[] = ['/project'];
  @State treeRefreshKey: number = 0;
  private currentFolder: string = '/project';

  // === 搜索 ===
  @State searchQuery: string = '';
  @State searchResults: SearchResult[] = [];
  @State errorEntries: ErrorEntry[] = [];
  @State debugVariables: VariableEntry[] = [];
  @State scrollToBottom: number = 0;
  @State breakpoints: number[] = [];

  // === 光标 & 运行 ===
  @State cursorLine: number = 1;
  @State cursorCol: number = 1;
  @State isRunning: boolean = false;

  // === 弹窗 ===
  @State showRenameDialog: boolean = false;
  @State showDeleteConfirm: boolean = false;
  // === Toast ===
  @State toastMessage: string = '';
  @State showToast: boolean = false;

  // === 管理器 ===
  private tabMgr: TabManager = new TabManager();
  private undoMgr: UndoManager = new UndoManager();
  private clipboard: ClipboardManager = new ClipboardManager();
  private dialog: DialogManager = new DialogManager();
  private router: ActionRouter = new ActionRouter();

  aboutToAppear(): void {
    FileManager.init();
    this.setupRouter();
    this.expandAllFolders();
    let content: string = FileManager.readFile('/project/main.py');
    this.editorContent = content;
    this.codeLines = content.split('\n');
    this.undoMgr.init(content);
    this.currentFolder = '/project';
    let tab: TabItem = new TabItem();
    tab.id = FileManager.generateId(); tab.name = 'main.py';
    tab.path = '/project/main.py'; tab.language = Language.PYTHON; tab.content = content;
    this.tabMgr.tabs = [tab]; this.tabMgr.activeTabId = tab.id;
  }

  private toggleAllFolders(): void {
    // 如果当前全部展开，则收起（只保留根）；否则全部展开
    if (this.expandedFolders.length > 1) {
      this.expandedFolders = ['/project']
      this.toast('已折叠所有文件夹')
    } else {
      this.expandAllFolders()
      this.toast('已展开所有文件夹')
    }
  }

  private expandAllFolders(): void {
    let allPaths: string[] = FileManager.getAllFilePaths()
    let folders: string[] = ['/project']
    for (let i = 0; i < allPaths.length; i++) {
      let parts: string[] = allPaths[i].split('/').filter((p: string) => p.length > 0)
      let current: string = ''
      for (let j = 0; j < parts.length - 1; j++) {
        current += '/' + parts[j]
        let found: boolean = false
        for (let k = 0; k < folders.length; k++) {
          if (folders[k] === current) { found = true; break }
        }
        if (!found) { folders.push(current) }
      }
    }
    this.expandedFolders = folders
  }

  private setupRouter(): void {
    this.router.onNewFile = () => { this.handleNewFile() };
    this.router.onOpenFile = () => { this.handleOpenFile() };
    this.router.onSave = () => { this.handleSave() };
    this.router.onSaveAs = () => { this.handleSaveAs() };
    this.router.onCloseTab = () => { this.handleCloseTab() };
    this.router.onUndo = () => { this.handleUndo() };
    this.router.onRedo = () => { this.handleRedo() };
    this.router.onCut = () => { this.handleCut() };
    this.router.onCopy = () => { this.handleCopy() };
    this.router.onPaste = () => { this.handlePaste() };
    this.router.onRun = () => { this.handleRun() };
    this.router.onStop = () => { this.handleStop() };
    this.router.onNewFolder = () => { this.handleNewFolder() };
    this.router.onFind = () => { this.showSearch = !this.showSearch };
    this.router.onFindInFiles = () => {
      this.showSearch = true;
      this.bottomTab = 'search';
      this.bottomCollapsed = false;
    };
    this.router.onReplace = () => { this.showSearch = true };
    this.router.onSelectAll = () => { this.toast('已全选') };
    this.router.onDelete = () => { this.toast('已删除') };
    this.router.onToggleBreakpoint = () => {
      let line: number = this.cursorLine
      let found: boolean = false
      let newBP: number[] = []
      for (let i = 0; i < this.breakpoints.length; i++) {
        if (this.breakpoints[i] === line) { found = true }
        else { newBP.push(this.breakpoints[i]) }
      }
      if (found) {
        this.breakpoints = newBP
        this.toast('已取消断点: 行 ' + line.toString())
      } else {
        newBP.push(line)
        this.breakpoints = newBP
        this.toast('已添加断点: 行 ' + line.toString())
      }
    };
    this.router.onToggleFileTree = () => { this.showFileTree = !this.showFileTree };
    this.router.onToggleRightPanel = () => { this.showRightPanel = !this.showRightPanel };
    this.router.onToggleBottomPanel = () => { this.bottomCollapsed = !this.bottomCollapsed };
    this.router.onZoomIn = () => { this.settings.fontSize += 1 };
    this.router.onZoomOut = () => { this.settings.fontSize -= 1 };
    this.router.onRefresh = () => { this.treeRefreshKey++ };
    this.router.onClearTerminal = () => { this.consoleEntries = []; this.toast('终端已清空') };
    this.router.onCopyPath = () => { this.clipboard.copy(this.tabMgr.getCurrentPath()); this.toast('路径已复制') };
    this.router.onToggleExpand = () => { this.toggleAllFolders() };
    this.router.onCodeStats = () => {
      let lines: number = this.codeLines.length;
      let chars: number = this.editorContent.length;
      let words: number = 0;
      let parts: string[] = this.editorContent.split(' ')
      for (let i = 0; i < parts.length; i++) { if (parts[i].length > 0) words++ }
      let size: string = chars < 1024 ? chars.toString() + ' B' : (chars / 1024).toFixed(1) + ' KB';
      let msg: string = '📊 ' + this.tabMgr.getCurrentName() + ' — 行: ' + lines.toString() + ' 词: ' + words.toString() + ' 字符: ' + chars.toString() + ' (' + size + ')'
      let entry: ConsoleEntry = new ConsoleEntry()
      entry.text = msg; entry.entryType = 'data'; entry.timestamp = Date.now()
      let newEntries: ConsoleEntry[] = []
      for (let i = 0; i < this.consoleEntries.length; i++) newEntries.push(this.consoleEntries[i])
      newEntries.push(entry)
      this.consoleEntries = newEntries
      this.bottomTab = 'terminal'
      this.bottomCollapsed = false
      this.toast(msg)
    };
    this.router.onCommentToggle = () => {
      let lines: string[] = this.editorContent.split('\n');
      let result: string[] = [];
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].trimStart().startsWith('#')) {
          let stripped: string = lines[i].trimStart();
          if (stripped.startsWith('# ')) {
            result.push(lines[i].replace('# ', ''));
          } else if (stripped.startsWith('#')) {
            result.push(lines[i].replace('#', ''));
          } else {
            result.push(lines[i]);
          }
        } else if (lines[i].trim().length > 0) {
          result.push('# ' + lines[i]);
        } else {
          result.push(lines[i]);
        }
      }
      let newContent: string = '';
      for (let i = 0; i < result.length; i++) {
        if (i > 0) newContent += '\n';
        newContent += result[i];
      }
      this.editorContent = newContent;
      this.codeLines = newContent.split('\n');
      this.toast('已切换注释');
    };
    this.router.onDuplicateLine = () => {
      let idx: number = this.cursorLine - 1;
      if (idx < 0) idx = 0;
      let lines: string[] = this.editorContent.split('\n');
      if (idx < lines.length) {
        let newLines: string[] = [];
        for (let i = 0; i < lines.length; i++) {
          newLines.push(lines[i]);
          if (i === idx) newLines.push(lines[idx]);
        }
        let newContent: string = '';
        for (let i = 0; i < newLines.length; i++) {
          if (i > 0) newContent += '\n';
          newContent += newLines[i];
        }
        this.editorContent = newContent;
        this.codeLines = newContent.split('\n');
        this.toast('已重复当前行');
      }
    };
    this.router.onToUppercase = () => {
      this.editorContent = this.editorContent.toUpperCase();
      this.codeLines = this.editorContent.split('\n');
      this.toast('已转为大写');
    };
    this.router.onToLowercase = () => {
      this.editorContent = this.editorContent.toLowerCase();
      this.codeLines = this.editorContent.split('\n');
      this.toast('已转为小写');
    };
    this.router.onResetZoom = () => {
      this.settings.fontSize = 14;
      this.toast('缩放已重置');
    };
    this.router.onCycleTab = (dir: number) => { this.cycleTab(dir) };
    this.router.onToast = (msg: string) => { this.toast(msg) };
    this.router.onResetLayout = () => {
      this.showFileTree = true;
      this.showRightPanel = false;
      this.bottomCollapsed = false;
    };
  }

  build() {
    Stack() {
      Column() {
        TitleBar({
          onMinimize: () => { this.toast('最小化') },
          onMaximize: () => { this.toast('最大化') },
          onClose: () => { this.toast('关闭') }
        })

        MenuBar({ onMenuAction: (action: string) => {
          if (action.startsWith('openfile:')) {
            this.openFile(action.substring(9))
          } else {
            this.router.route(action)
          }
        } })

        CommandPalette({
          showSearch: this.showSearch,
          searchQuery: this.searchQuery,
          matchCount: this.searchResults.length,
          results: this.searchResults,
          onSearchChange: (value: string) => { this.searchQuery = value; this.performSearch(value); },
          onSearchClose: () => { this.showSearch = false; this.searchQuery = ''; this.searchResults = [] },
          onCommand: (action: string) => { this.router.route(action) },
          onResultClick: (filePath: string, line: number) => {
            if (filePath !== this.tabMgr.getCurrentPath()) this.openFile(filePath)
            this.cursorLine = line
            this.showSearch = false
          }
        })

        ToolBar({
          isRunning: this.isRunning,
          canUndo: true,
          canRedo: true,
          hasSelection: this.editorContent.length > 0,
          onNew: () => { this.handleNewFile() },
          onNewFolder: () => { this.handleNewFolder() },
          onOpen: () => { this.handleOpenFile() },
          onSave: () => { this.handleSave() },
          onSaveAs: () => { this.handleSaveAs() },
          onClose: () => { this.handleCloseTab() },
          onRun: () => { this.handleRun() },
          onStop: () => { this.handleStop() },
          onUndo: () => { this.handleUndo() },
          onRedo: () => { this.handleRedo() },
          onCut: () => { this.handleCut() },
          onCopy: () => { this.handleCopy() },
          onPaste: () => { this.handlePaste() },
          onSearch: () => { this.showSearch = !this.showSearch }
        })

        Row() {
          ActivityBar({
            activeIcon: this.activityBarIcon,
            onIconClick: (id: string) => { this.handleActivityClick(id) }
          })

          if (this.showFileTree) {
            SideBar({
              expandedFolders: this.expandedFolders,
              selectedFilePath: this.tabMgr.getCurrentPath(),
              activeFolder: this.currentFolder,
              refreshTrigger: this.treeRefreshKey,
              onFolderClick: (path: string) => { this.currentFolder = path },
              onFolderToggle: (path: string) => { this.toggleFolder(path) },
              onFileOpen: (path: string) => { this.openFile(path) },
              onNewFolder: () => { this.handleNewFolder() },
              onNewFile: () => { this.handleNewFile() },
              onRefresh: () => { this.treeRefreshKey++ },
              onClose: () => { this.showFileTree = false },
              onDelete: (path: string) => {
                this.dialog.confirmDelete(path)
                this.showDeleteConfirm = true
              },
              onRename: (path: string) => {
                this.dialog.openRenameDialog(path)
                this.showRenameDialog = true
              }
            })
          }

          Column() {
            EditorTabBar({
              tabs: this.tabMgr.tabs,
              activeTabId: this.tabMgr.activeTabId,
              onTabClick: (tabId: string) => { this.switchTab(tabId) },
              onTabClose: (tabId: string) => { this.closeTabById(tabId) }
            })

            CodeEditor({
              editorContent: this.editorContent,
              codeLines: this.codeLines,
              settings: this.settings,
              currentLine: this.cursorLine,
              breakpoints: this.breakpoints,
              onContentChange: (value: string) => {
                if (this.editorContent !== value) {
                  this.tabMgr.markModified(this.tabMgr.activeTabId)
                  this.undoMgr.pushState(value)
                }
                this.editorContent = value
                this.codeLines = value.split('\n')
                this.cursorLine = this.codeLines.length
                this.cursorCol = this.codeLines[this.codeLines.length - 1].length + 1
              }
            })

            BottomPanel({
              consoleEntries: $consoleEntries,
              bottomTab: this.bottomTab,
              bottomCollapsed: this.bottomCollapsed,
              scrollToBottom: this.scrollToBottom,
              searchResults: this.searchResults,
              searchQuery: this.searchQuery,
              errors: this.errorEntries,
              onTabChange: (tab: string) => { this.bottomTab = tab },
              onCollapse: () => { this.bottomCollapsed = !this.bottomCollapsed },
              onClearTerminal: () => { this.consoleEntries = [] },
              onResultClick: (filePath: string, line: number) => {
                this.openFile(filePath)
                this.cursorLine = line
                this.bottomCollapsed = true
              }
            })
          }
          .layoutWeight(1).height('100%')

          if (this.showRightPanel) {
            RightPanel({
              rightPanelTab: this.rightPanelTab,
              variables: this.debugVariables,
              fontSize: this.settings.fontSize,
              onTabChange: (tab: string) => { this.rightPanelTab = tab },
              onClose: () => { this.showRightPanel = false },
              onFontSizeChange: (delta: number) => {
                this.settings.fontSize += delta
                if (this.settings.fontSize < 10) this.settings.fontSize = 10
                if (this.settings.fontSize > 30) this.settings.fontSize = 30
              }
            })
          }
        }
        .layoutWeight(1).width('100%')

        StatusBar({
          currentLanguage: this.tabMgr.getCurrentLanguage(),
          cursorLine: this.cursorLine,
          cursorCol: this.cursorCol,
          fileName: this.tabMgr.getCurrentName(),
          errorCount: this.errorEntries.length,
          onLanguageClick: () => { this.toast('语言模式: ' + this.getLangName(this.tabMgr.getCurrentLanguage())) },
          onCursorClick: () => { this.toast('转到行...') },
          onErrorClick: () => { this.bottomTab = 'problems'; this.bottomCollapsed = false }
        })
      }
      .width('100%').height('100%')

      // === 弹窗层 ===
      RenameDialog({
        renameText: this.dialog.renameText,
        visible: this.showRenameDialog,
        onChange: (v: string) => { this.dialog.renameText = v },
        onConfirm: () => {
          let newName: string = this.dialog.doRename(this.tabMgr, () => { this.treeRefreshKey++ })
          if (newName.length > 0) this.toast('已重命名: ' + newName)
          this.showRenameDialog = false
        },
        onCancel: () => { this.showRenameDialog = false }
      })
      DeleteDialog({
        fileName: FileManager.getFileName(this.dialog.deletePath),
        visible: this.showDeleteConfirm,
        onConfirm: () => {
          let res: DeleteResult = this.dialog.doDelete(this.tabMgr, () => { this.treeRefreshKey++ })
          if (res.newContent.length > 0) {
            this.editorContent = res.newContent
            this.codeLines = res.newContent.split('\n')
            this.undoMgr.reset(res.newContent)
          }
          if (res.fileName.length > 0) this.toast('已删除: ' + res.fileName)
          this.showDeleteConfirm = false
        },
        onCancel: () => { this.showDeleteConfirm = false }
      })
      if (this.showToast) {
        Text(this.toastMessage)
          .fontSize(12).fontColor('#FFFFFF')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor('#333333').borderRadius(4)
          .position({ x: 0, y: '90%' })
      }
    }
    .width('100%').height('100%').backgroundColor('#F0F0F0')
  }

  // ====== 文件操作 ======

  private handleNewFile(): void {
    let baseName: string = '新建文件'
    let name: string = baseName
    let counter: number = 1
    let newPath: string = this.currentFolder + '/' + name
    while (FileManager.fileExists(newPath)) {
      counter++
      name = baseName + '_' + counter.toString()
      newPath = this.currentFolder + '/' + name
    }
    FileManager.writeFile(newPath, '')
    let tab: TabItem = new TabItem()
    tab.id = FileManager.generateId(); tab.name = name
    tab.path = newPath; tab.language = Language.PYTHON; tab.content = ''
    let arr: TabItem[] = []
    for (let i = 0; i < this.tabMgr.tabs.length; i++) arr.push(this.tabMgr.tabs[i])
    arr.push(tab); this.tabMgr.tabs = arr; this.tabMgr.activeTabId = tab.id
    this.editorContent = ''; this.codeLines = ['']
    this.undoMgr.reset(''); this.treeRefreshKey++
    this.expandAllFolders()
    this.toast('已创建: ' + newPath)
  }

  private handleOpenFile(): void {
    this.treeRefreshKey++; this.showFileTree = true
    this.toast('文件列表已刷新')
  }

  private handleSave(): void {
    this.tabMgr.saveFile(this.tabMgr.getCurrentPath(), this.editorContent)
    this.treeRefreshKey++
    this.toast('已保存: ' + this.tabMgr.getCurrentName())
  }

  private handleSaveAs(): void {
    let tab: TabItem = this.tabMgr.saveFileAs(this.editorContent, this.tabMgr.getCurrentLanguage())
    this.treeRefreshKey++
    this.toast('已另存为: ' + tab.name)
  }

  private handleNewFolder(): void {
    let parentPath: string = this.currentFolder
    let baseName: string = '新建文件夹'
    let folderName: string = baseName
    let counter: number = 1
    while (FileManager.folderExists(parentPath + '/' + folderName)) {
      counter++; folderName = baseName + '_' + counter.toString()
    }
    FileManager.createFolder(parentPath, folderName)
    this.treeRefreshKey++
    let newPath: string = parentPath + '/' + folderName
    let arr: string[] = []
    for (let i = 0; i < this.expandedFolders.length; i++) { arr.push(this.expandedFolders[i]) }
    arr.push(newPath); this.expandedFolders = arr
    this.toast('已创建文件夹: ' + folderName)
  }

  // ====== 标签操作 ======

  private handleCloseTab(): void {
    if (this.tabMgr.tabs.length > 1) { this.closeTabById(this.tabMgr.activeTabId) }
  }

  private switchTab(tabId: string): void {
    let content: string = this.tabMgr.switchTab(tabId, this.editorContent)
    this.editorContent = content; this.codeLines = content.split('\n')
    this.undoMgr.reset(content)
    let currentPath: string = this.tabMgr.getCurrentPath()
    if (currentPath.length > 0) {
      let lastSlash: number = currentPath.lastIndexOf('/')
      if (lastSlash > 0) {
        this.currentFolder = currentPath.substring(0, lastSlash)
      }
      this.revealPath(currentPath)
    }
  }

  private closeTabById(tabId: string): void {
    let result: TabItem | null = this.tabMgr.closeTab(tabId)
    if (result !== null) {
      this.editorContent = result.content; this.codeLines = result.content.split('\n')
      this.undoMgr.reset(result.content)
    }
  }

  private openFile(path: string): void {
    this.tabMgr.openFile(path)
    let newContent: string = FileManager.readFile(path)
    this.editorContent = newContent; this.codeLines = newContent.split('\n')
    this.undoMgr.reset(newContent)
    // 设置当前工作目录为文件的父目录
    let lastSlash: number = path.lastIndexOf('/')
    if (lastSlash > 0) {
      this.currentFolder = path.substring(0, lastSlash)
    }
    this.revealPath(path)
  }

  private revealPath(path: string): void {
    let parts: string[] = path.split('/').filter((p: string) => p.length > 0)
    let current: string = ''
    let newExpanded: string[] = []
    // 保留已有的展开状态
    for (let i = 0; i < this.expandedFolders.length; i++) {
      newExpanded.push(this.expandedFolders[i])
    }
    for (let i = 0; i < parts.length - 1; i++) {
      current += '/' + parts[i]
      let found: boolean = false
      for (let j = 0; j < newExpanded.length; j++) {
        if (newExpanded[j] === current) { found = true; break }
      }
      if (!found) { newExpanded.push(current) }
    }
    this.expandedFolders = newExpanded
  }

  // ====== 撤销/剪贴板 ======

  private handleUndo(): void {
    let prev: string | null = this.undoMgr.undo()
    if (prev !== null) { this.editorContent = prev; this.codeLines = prev.split('\n'); this.toast('撤销') }
  }

  private handleRedo(): void {
    let next: string | null = this.undoMgr.redo()
    if (next !== null) { this.editorContent = next; this.codeLines = next.split('\n'); this.toast('重做') }
  }

  private handleCut(): void { if (this.editorContent.length > 0) { this.clipboard.cut(this.editorContent); this.toast('已剪切') } }
  private handleCopy(): void { if (this.editorContent.length > 0) { this.clipboard.copy(this.editorContent); this.toast('已复制') } }

  private handlePaste(): void {
    if (this.clipboard.hasContent()) {
      this.editorContent = this.clipboard.paste(this.editorContent)
      this.codeLines = this.editorContent.split('\n')
      this.undoMgr.pushState(this.editorContent); this.toast('已粘贴')
    }
  }

  // ====== 运行 ======

  private handleRun(): void {
    this.isRunning = true; this.bottomTab = 'terminal'; this.bottomCollapsed = false

    // 已有输出时加分隔线
    if (this.consoleEntries.length > 0) {
      let sep: ConsoleEntry = new ConsoleEntry()
      sep.text = '────────── 第 ' + (this.runCount + 1).toString() + ' 次运行 ──────────'
      sep.entryType = 'system'; sep.timestamp = Date.now()
      let current: ConsoleEntry[] = []
      for (let i = 0; i < this.consoleEntries.length; i++) current.push(this.consoleEntries[i])
      current.push(sep)
      this.consoleEntries = current
    }

    let info: ConsoleEntry = new ConsoleEntry()
    info.text = '▶ 运行代码...'; info.entryType = 'info'; info.timestamp = Date.now()
    let newEntries: ConsoleEntry[] = [info]
    this.consoleEntries = this.appendEntries(this.consoleEntries, newEntries)

    this.runCount++

    setTimeout(() => {
      let output: string = RunHandler.execute(this.editorContent, Language.PYTHON)
      let outputEntries: ConsoleEntry[] = [info]
      let outputLines: string[] = output.split('\n')
      for (let i = 0; i < outputLines.length; i++) {
        if (outputLines[i].length > 0) {
          let e: ConsoleEntry = new ConsoleEntry()
          e.text = outputLines[i]
          let line: string = outputLines[i]
          if (line.includes('✗') || line.includes('Error') || line.includes('错误')) {
            e.entryType = 'error'
          } else if (line.includes('⚠') || line.includes('Warning') || line.includes('警告')) {
            e.entryType = 'warn'
          } else if (line.includes('✓') || line.includes('完成') || line.includes('成功')) {
            e.entryType = 'success'
          } else if (line.includes('▶') || line.includes('开始') || line.includes('运行')) {
            e.entryType = 'info'
          } else if (line.includes('═══') || line.includes('───')) {
            e.entryType = 'system'
          } else {
            e.entryType = 'data'
          }
          e.timestamp = Date.now() + i + 1
          outputEntries.push(e)
        }
      }
      this.errorEntries = RunHandler.parseErrors(output, this.editorContent)
      if (this.errorEntries.length > 0) { this.bottomTab = 'problems' }

      let vars: Map<string, string> = PythonSimulator.getLastVariables()
      let varEntries: VariableEntry[] = []
      vars.forEach((value: string, key: string) => {
        let ve: VariableEntry = new VariableEntry()
        ve.name = key
        ve.value = value
        ve.varType = 'str'
        varEntries.push(ve)
      })
      this.debugVariables = varEntries

      let done: ConsoleEntry = new ConsoleEntry()
      done.text = '✓ 运行完成'; done.entryType = 'system'; done.timestamp = Date.now()
      outputEntries.push(done)

      let finalEntries: ConsoleEntry[] = []
      for (let i = 0; i < this.consoleEntries.length; i++) finalEntries.push(this.consoleEntries[i])
      for (let i = 0; i < outputEntries.length; i++) finalEntries.push(outputEntries[i])
      this.consoleEntries = finalEntries
      this.scrollToBottom++
      this.isRunning = false
    }, 50)
  }

  private runCount: number = 0

  private appendEntries(source: ConsoleEntry[], add: ConsoleEntry[]): ConsoleEntry[] {
    let result: ConsoleEntry[] = []
    for (let i = 0; i < source.length; i++) result.push(source[i])
    for (let i = 0; i < add.length; i++) result.push(add[i])
    return result
  }

  private handleStop(): void {
    this.isRunning = false
    let entry: ConsoleEntry = new ConsoleEntry()
    entry.text = '⏹ 已停止'; entry.entryType = 'system'; entry.timestamp = Date.now()
    let entries: ConsoleEntry[] = []
    for (let i = 0; i < this.consoleEntries.length; i++) { entries.push(this.consoleEntries[i]) }
    entries.push(entry); this.consoleEntries = entries
  }

  // ====== 搜索 ======

  private performSearch(query: string): void {
    if (query.length === 0 || query.startsWith('>')) { this.searchResults = []; return }
    let results: SearchResult[] = []
    let allPaths: string[] = FileManager.getAllFilePaths()
    for (let p = 0; p < allPaths.length; p++) {
      let filePath: string = allPaths[p]
      if (filePath.endsWith('.gitkeep')) continue
      let content: string = FileManager.readFile(filePath)
      let lines: string[] = content.split('\n')
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].toLowerCase().includes(query.toLowerCase())) {
          let r: SearchResult = new SearchResult()
          r.file = filePath
          r.line = i + 1
          r.text = lines[i].trim()
          if (r.text.length > 60) { r.text = r.text.substring(0, 60) + '...' }
          results.push(r)
        }
      }
    }
    this.searchResults = results
    if (results.length > 0) { this.bottomTab = 'search'; this.bottomCollapsed = false }
  }

  // ====== 辅助 ======

  private handleActivityClick(id: string): void {
    this.activityBarIcon = id
    if (id === 'files') this.showFileTree = !this.showFileTree
    else if (id === 'run') this.handleRun()
    else if (id === 'search') { this.showSearch = true; this.searchQuery = ''; this.searchResults = [] }
    else if (id === 'settings') {
      this.rightPanelTab = 'extensions'
      this.showRightPanel = !this.showRightPanel
    }
    else if (id === 'git') {
      this.toast('源代码管理：暂无变更')
    } else if (id === 'extensions') {
      this.rightPanelTab = 'extensions'
      this.showRightPanel = true
    }
  }

  private cycleTab(dir: number): void {
    let tabs: TabItem[] = this.tabMgr.tabs
    if (tabs.length <= 1) return
    let cur: number = -1
    for (let i = 0; i < tabs.length; i++) { if (tabs[i].id === this.tabMgr.activeTabId) { cur = i; break } }
    if (cur < 0) return
    let next: number = cur + dir
    if (next < 0) next = tabs.length - 1
    if (next >= tabs.length) next = 0
    this.switchTab(tabs[next].id)
  }

  private toggleFolder(path: string): void {
    let arr: string[] = []
    let found: boolean = false
    for (let i = 0; i < this.expandedFolders.length; i++) {
      if (this.expandedFolders[i] === path) found = true; else arr.push(this.expandedFolders[i])
    }
    if (!found) arr.push(path)
    this.expandedFolders = arr
  }

  private getLangName(lang: Language): string {
    if (lang === Language.PYTHON) return 'Python'
    if (lang === Language.RUBY) return 'Ruby'
    if (lang === Language.JAVASCRIPT) return 'JavaScript'
    if (lang === Language.TYPESCRIPT) return 'TypeScript'
    return 'Plain Text'
  }

  private toast(msg: string): void {
    this.toastMessage = msg; this.showToast = true
    setTimeout(() => { this.showToast = false }, 2000)
  }
}
