import { FileNode } from '../models/IDEModels';
import { FileManager } from '../utils/FileManager';

@Component
export struct SideBar {
  @Prop expandedFolders: string[] = []
  @Prop selectedFilePath: string = ''
  @Prop activeFolder: string = '/project'
  @Prop refreshTrigger: number = 0
  onFolderToggle: (path: string) => void = () => {}
  onFolderClick: (path: string) => void = () => {}
  onFileOpen: (path: string) => void = () => {}
  onNewFolder: () => void = () => {}
  onNewFile: () => void = () => {}
  onRefresh: () => void = () => {}
  onClose: () => void = () => {}
  onDelete: (path: string) => void = () => {}
  onRename: (path: string) => void = () => {}
  @State hoveredItem: string = ''
  @State showContextMenu: boolean = false

  build() {
    Column() {
      Row() {
        Row() {
          Text('▸').fontSize(10).fontColor('#555555').width(12)
          Text('资源管理器').fontSize(11).fontColor('#333333').fontWeight(FontWeight.Bold)
        }.layoutWeight(1)
        Text('⋮').fontSize(16).fontColor('#555555').width(24).height(24)
          .textAlign(TextAlign.Center).borderRadius(3)
          .onClick(() => { this.showContextMenu = !this.showContextMenu })
        Text('📂⁺').fontSize(12).fontColor('#555555').width(22).height(22)
          .textAlign(TextAlign.Center).borderRadius(3).backgroundColor('#E8E8E8')
          .onClick(() => { this.onNewFolder() })
        Text('✕').fontSize(10).fontColor('#888888').width(22).height(22)
          .textAlign(TextAlign.Center).borderRadius(3)
          .onClick(() => { this.onClose() })
      }
      .width('100%').height(28).padding({ left: 8, right: 4 })
      .alignItems(VerticalAlign.Center).backgroundColor('#F0F0F0')
      .border({ width: { bottom: 1 }, color: '#D0D0D0' })

      // 右键菜单
      if (this.showContextMenu) {
        Column() {
          Row() {
            Text('📂 新建文件夹').fontSize(12).padding({ left: 12, right: 12 })
          }.width('100%').height(30)
          .backgroundColor('#FFFFFF')
          .onClick(() => { this.showContextMenu = false; this.onNewFolder() })

          Divider().width('100%').height(1).color('#E0E0E0')

          Row() {
            Text('📄 新建文件').fontSize(12).padding({ left: 12, right: 12 })
          }.width('100%').height(30)
          .backgroundColor('#FFFFFF')
          .onClick(() => { this.showContextMenu = false; this.onNewFile() })

          Divider().width('100%').height(1).color('#E0E0E0')

          Row() {
            Text('🔄 刷新').fontSize(12).padding({ left: 12, right: 12 })
          }.width('100%').height(30)
          .backgroundColor('#FFFFFF')
          .onClick(() => { this.showContextMenu = false; this.onRefresh() })
        }
        .width(160)
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#D0D0D0' })
        .borderRadius(6)
        .shadow({ radius: 6, color: 'rgba(0,0,0,0.15)', offsetY: 2 })
        .padding({ top: 2, bottom: 2 })
        .offset({ x: 50, y: 2 })
      }

      // 项目根 — 可选中、可悬停
      Row() {
        Text(this.isFolderExpanded('/project') ? '▾' : '▸').fontSize(10).fontColor('#555555').width(14)
        Text('📁').fontSize(12).fontColor('#666666').width(18).textAlign(TextAlign.Center)
        Text('ERIC6 项目').fontSize(12).fontColor('#333333').fontWeight(FontWeight.Bold).layoutWeight(1)
      }
      .width('100%').height(26).padding({ left: 6, right: 6 }).alignItems(VerticalAlign.Center)
      .backgroundColor(this.activeFolder === '/project' ? '#E3F0E8' :
        (this.hoveredItem === '/project_root' ? '#F0F0F0' : '#FFFFFF'))
      .border({ width: { left: this.activeFolder === '/project' ? 3 : 0 }, color: '#4CAF50' })
      .borderRadius(4)
      .animation({ duration: 150, curve: Curve.EaseOut })
      .onHover((isHover: boolean) => { this.hoveredItem = isHover ? '/project_root' : '' })
      .onClick(() => {
        this.onFolderClick('/project')
        this.onFolderToggle('/project')
      })

      Scroll() {
        Column() {
          if (this.isFolderExpanded('/project')) {
            ForEach(FileManager.buildFileTree(FileManager.getAllFilePaths()), (node: FileNode) => {
              this.FileTreeNode(node, 0)
            }, (node: FileNode) => node.path + '_' + this.refreshTrigger.toString())
          }
        }.width('100%').alignItems(HorizontalAlign.Start)
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto)
      .layoutWeight(1).width('100%').backgroundColor('#FFFFFF').align(Alignment.TopStart)
          }
    .width(220).height('100%').alignItems(HorizontalAlign.Start).backgroundColor('#FFFFFF')
      }

  @Builder
  FileTreeNode(node: FileNode, depth: number) {
    Column() {
      Row() {
        if (depth > 0) { Text('  ').width((depth * 16).toString() + 'px').fontSize(1) }

        if (node.isDirectory) {
          Text(this.isFolderExpanded(node.path) ? '▾' : '▸').fontSize(10).fontColor('#666666').width(14)
            .onClick(() => { this.onFolderClick(node.path); this.onFolderToggle(node.path) })
        } else {
          Text('').width(14)
        }

        Text(this.getFileIcon(node)).fontSize(13).fontColor(this.getFileColor(node)).width(18).textAlign(TextAlign.Center)
          .onClick(() => {
            if (node.isDirectory) { this.onFolderClick(node.path); this.onFolderToggle(node.path) }
            else { this.onFileOpen(node.path) }
          })

        Text(node.name)
          .fontSize(12)
          .fontColor(this.selectedFilePath === node.path ? '#000000' : '#333333')
          .fontWeight(this.selectedFilePath === node.path ? FontWeight.Bold : FontWeight.Normal)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
          .onClick(() => {
            if (node.isDirectory) { this.onFolderClick(node.path); this.onFolderToggle(node.path) }
            else { this.onFileOpen(node.path) }
          })

        Text('✏').fontSize(10)
          .fontColor(this.hoveredItem === node.path ? '#555555' : '#CCCCCC')
          .width(18).textAlign(TextAlign.Center).borderRadius(2)
          .backgroundColor(this.hoveredItem === node.path ? '#E0E0E0' : 'transparent')
          .onClick(() => { this.onRename(node.path) })
        Text('🗑').fontSize(10)
          .fontColor(this.hoveredItem === node.path ? '#CC0000' : '#CCCCCC')
          .width(18).textAlign(TextAlign.Center).borderRadius(2)
          .backgroundColor(this.hoveredItem === node.path ? '#FFE0E0' : 'transparent')
          .onClick(() => { this.onDelete(node.path) })
      }
      .width('100%').height(24).padding({ left: 6, right: 6 }).alignItems(VerticalAlign.Center)
      .backgroundColor(
        this.selectedFilePath === node.path ? '#CBEAFE' :
        (this.activeFolder === node.path && node.isDirectory ? '#E3F0E8' :
        (this.hoveredItem === node.path ? '#F0F0F0' :
        (node.isDirectory ? '#FAFAF8' : 'transparent')))
      )
      .border({
        width: { left: this.activeFolder === node.path && node.isDirectory ? 3 : 0 },
        color: '#4CAF50'
      })
      .borderRadius(4)
      .animation({ duration: 150, curve: Curve.EaseOut })
      .onHover((isHover: boolean) => { this.hoveredItem = isHover ? node.path : '' })

      if (node.isDirectory && this.isFolderExpanded(node.path) && node.children.length > 0) {
        ForEach(this.getVisibleChildren(node.children), (child: FileNode) => {
          this.FileTreeNode(child, depth + 1)
        }, (child: FileNode) => child.path + '_' + this.refreshTrigger.toString())
      }
    }.width('100%')
  }

  private getVisibleChildren(children: FileNode[]): FileNode[] {
    let result: FileNode[] = []
    for (let i = 0; i < children.length; i++) {
      if (children[i].name !== '.gitkeep') { result.push(children[i]) }
    }
    return result
  }

  private isFolderExpanded(path: string): boolean {
    for (let i = 0; i < this.expandedFolders.length; i++) {
      if (this.expandedFolders[i] === path) return true
    }
    return false
  }

  private getFileIcon(node: FileNode): string {
    if (node.isDirectory) return this.isFolderExpanded(node.path) ? '📂' : '📁'
    let name: string = node.name
    if (name.endsWith('.py') || name.endsWith('.pyw')) return '🐍'
    if (name.endsWith('.rb')) return '💎'
    if (name.endsWith('.js')) return '📜'
    if (name.endsWith('.ts')) return '📘'
    if (name.endsWith('.json')) return '⚙'
    if (name.endsWith('.md')) return '📝'
    if (name.endsWith('.html')) return '🌐'
    if (name.endsWith('.css')) return '🎨'
    return '📄'
  }

  private getFileColor(node: FileNode): string {
    return '#666666'
  }
}
