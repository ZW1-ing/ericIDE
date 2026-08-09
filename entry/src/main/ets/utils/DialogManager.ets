import { FileManager } from './FileManager';
import { TabManager } from './TabManager';
import { TabItem } from '../models/IDEModels';

export interface DeleteResult {
  fileName: string;
  newContent: string;
}

export class DialogManager {
  // 重命名状态
  renamePath: string = '';
  renameText: string = '';

  // 删除状态
  deletePath: string = '';

  openRenameDialog(path: string): void {
    this.renamePath = path;
    this.renameText = FileManager.getFileName(path);
  }

  confirmDelete(path: string): void {
    this.deletePath = path;
  }

  doDelete(tabMgr: TabManager, onTreeRefresh: () => void): DeleteResult {
    let path: string = this.deletePath;
    let result: DeleteResult = { fileName: '', newContent: '' };

    if (tabMgr.getCurrentPath() === path && tabMgr.tabs.length > 1) {
      let switchedTab: TabItem | null = tabMgr.closeTab(tabMgr.activeTabId);
      if (switchedTab !== null) {
        result.newContent = switchedTab.content;
      }
    }

    let fileName: string = FileManager.getFileName(path);
    let isFolder: boolean = FileManager.folderExists(path);
    if (isFolder) {
      FileManager.deleteFolder(path);
    } else {
      FileManager.deleteFile(path);
    }

    onTreeRefresh();
    result.fileName = fileName;
    return result;
  }

  doRename(tabMgr: TabManager, onTreeRefresh: () => void): string {
    if (this.renameText.length === 0) return '';

    let oldPath: string = this.renamePath;
    let newName: string = this.renameText;
    let isFolder: boolean = FileManager.folderExists(oldPath);
    if (isFolder) {
      FileManager.renameFolder(oldPath, newName);
    } else {
      FileManager.renameFile(oldPath, newName);
    }

    // 更新标签路径
    for (let i = 0; i < tabMgr.tabs.length; i++) {
      if (tabMgr.tabs[i].path === oldPath) {
        let lastSlash: number = oldPath.lastIndexOf('/');
        let dir: string = lastSlash >= 0 ? oldPath.substring(0, lastSlash) : '';
        tabMgr.tabs[i].path = dir + '/' + newName;
        tabMgr.tabs[i].name = newName;
        break;
      }
    }

    onTreeRefresh();
    return newName;
  }
}
