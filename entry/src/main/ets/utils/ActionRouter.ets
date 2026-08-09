export class ActionRouter {
  // 回调接口
  onNewFile: () => void = () => {};
  onOpenFile: () => void = () => {};
  onSave: () => void = () => {};
  onSaveAs: () => void = () => {};
  onCloseTab: () => void = () => {};
  onUndo: () => void = () => {};
  onRedo: () => void = () => {};
  onCut: () => void = () => {};
  onCopy: () => void = () => {};
  onPaste: () => void = () => {};
  onRun: () => void = () => {};
  onStop: () => void = () => {};
  onSelectAll: () => void = () => {};
  onDelete: () => void = () => {};
  onToggleBreakpoint: () => void = () => {};
  onNewFolder: () => void = () => {};
  onFind: () => void = () => {};
  onFindInFiles: () => void = () => {};
  onReplace: () => void = () => {};
  onToggleFileTree: () => void = () => {};
  onToggleRightPanel: () => void = () => {};
  onToggleBottomPanel: () => void = () => {};
  onResetLayout: () => void = () => {};
  onZoomIn: () => void = () => {};
  onZoomOut: () => void = () => {};
  onRefresh: () => void = () => {};
  onClearTerminal: () => void = () => {};
  onCopyPath: () => void = () => {};
  onToggleExpand: () => void = () => {};
  onCodeStats: () => void = () => {};
  onCommentToggle: () => void = () => {};
  onDuplicateLine: () => void = () => {};
  onToUppercase: () => void = () => {};
  onToLowercase: () => void = () => {};
  onResetZoom: () => void = () => {};
  onCycleTab: (dir: number) => void = () => {};
  onToast: (msg: string) => void = () => {};

  route(action: string): void {
    if (action === 'new') this.onNewFile();
    else if (action === 'open') this.onOpenFile();
    else if (action === 'save') this.onSave();
    else if (action === 'saveas') this.onSaveAs();
    else if (action === 'close') this.onCloseTab();
    else if (action === 'exit') this.onToast('HarmonyOS 不支持退出');
    else if (action === 'undo') this.onUndo();
    else if (action === 'redo') this.onRedo();
    else if (action === 'cut') this.onCut();
    else if (action === 'copy') this.onCopy();
    else if (action === 'paste') this.onPaste();
    else if (action === 'find') this.onFind();
    else if (action === 'findfiles') this.onFindInFiles();
    else if (action === 'replace') this.onReplace();
    else if (action === 'gotoline') this.onToast('跳转到指定行');
    else if (action === 'togglefiletree') this.onToggleFileTree();
    else if (action === 'togglerightpanel') this.onToggleRightPanel();
    else if (action === 'togglebottompanel') this.onToggleBottomPanel();
    else if (action === 'zoomin') this.onZoomIn();
    else if (action === 'zoomout') this.onZoomOut();
    else if (action === 'newfolder') this.onNewFolder();
    else if (action === 'refresh') this.onRefresh();
    else if (action === 'clear_terminal') this.onClearTerminal();
    else if (action === 'copy_path') this.onCopyPath();
    else if (action === 'toggle_expand') this.onToggleExpand();
    else if (action === 'code_stats') this.onCodeStats();
    else if (action === 'comment_toggle') this.onCommentToggle();
    else if (action === 'duplicate_line') this.onDuplicateLine();
    else if (action === 'to_uppercase') this.onToUppercase();
    else if (action === 'to_lowercase') this.onToLowercase();
    else if (action === 'reset_zoom') this.onResetZoom();
    else if (action === 'run') this.onRun();
    else if (action === 'stop') this.onStop();
    else if (action === 'selectall') this.onSelectAll();
    else if (action === 'delete') this.onDelete();
    else if (action === 'togglebreakpoint') this.onToggleBreakpoint();
    else if (action === 'settings') this.onToggleRightPanel();
    else if (action === 'nexttab') this.onCycleTab(1);
    else if (action === 'prevtab') this.onCycleTab(-1);
    else if (action === 'closetab') this.onCloseTab();
    else if (action === 'resetlayout') {
      this.onResetLayout();
    }
    else if (action === 'about') this.onToast('Eric6 IDE for HarmonyOS');
    else if (action === 'version') this.onToast('v19.05 | HarmonyOS NEXT');
  }
}
