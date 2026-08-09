import { ConsoleEntry, SearchResult, ErrorEntry } from '../models/IDEModels';
import { FileManager } from '../utils/FileManager';

interface SearchGroup {
  file: string;
  matches: SearchResult[];
}

@Component
export struct BottomPanel {
  @Link consoleEntries: ConsoleEntry[]
  @Prop bottomTab: string = 'terminal'
  @Prop bottomCollapsed: boolean = false
  @Prop searchResults: SearchResult[] = []
  @Prop searchQuery: string = ''
  @Prop errors: ErrorEntry[] = []
  onTabChange: (tab: string) => void = () => {}
  onCollapse: () => void = () => {}
  onClearTerminal: () => void = () => {}
  onResultClick: (filePath: string, line: number) => void = () => {}
  @Prop @Watch('doScroll') scrollToBottom: number = 0
  @State hoveredTabId: string = ''
  private scroller: Scroller = new Scroller()
  @State panelHeight: number = 160
  private dragStartY: number = 0
  private dragStartHeight: number = 0

  doScroll(): void {
    setTimeout(() => { this.scroller.scrollEdge(Edge.Bottom) }, 30)
  }

  @Builder
  TabBtn(id: string, label: string) {
    Text(label)
      .fontSize(11)
      .fontColor(this.bottomTab === id ? '#333333' : (this.hoveredTabId === id ? '#444444' : '#666666'))
      .padding({ left: 10, right: 10, top: 3, bottom: 3 })
      .fontWeight(this.bottomTab === id ? FontWeight.Bold : FontWeight.Normal)
      .backgroundColor(this.hoveredTabId === id && this.bottomTab !== id ? '#E8E8E8' : 'transparent')
      .borderRadius(2)
      .border({
        width: { bottom: this.bottomTab === id ? 2 : 0 },
        color: this.bottomTab === id ? '#3A90DB' : 'transparent'
      })
      .animation({ duration: 120, curve: Curve.EaseOut })
      .onHover((isHover: boolean) => { this.hoveredTabId = isHover ? id : '' })
      .onClick(() => { this.onTabChange(id) })
  }

  @Builder
  TerminalContent() {
    Column() {
      if (this.consoleEntries.length === 0) {
        Row() {
          Text('▶ ')
            .fontSize(12)
            .fontColor('#3A90DB')
            .fontFamily('monospace')
          Text('Eric6 终端就绪，点击 ▶ 运行代码')
            .fontSize(12)
            .fontColor('#999999')
            .fontFamily('monospace')
        }
        .width('100%')
        .padding({ left: 8, top: 6 })
      } else {
        ForEach(this.consoleEntries, (entry: ConsoleEntry) => {
          Row() {
            Text(this.getEntryIcon(entry.entryType))
              .fontSize(11).width(18)
              .fontColor(this.getEntryColor(entry.entryType))
            Text(entry.text)
              .fontSize(12)
              .fontColor(this.getEntryColor(entry.entryType))
              .fontFamily('monospace')
              .layoutWeight(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 1, bottom: 1 })
          .alignItems(VerticalAlign.Top)
          .backgroundColor(this.getEntryBg(entry.entryType))
        }, (entry: ConsoleEntry) => entry.timestamp.toString())
        Row()
          .height(1).width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SearchResultsContent() {
    Column() {
      if (this.searchResults.length === 0) {
        Text(this.searchQuery.length > 0 ? '未找到结果' : '输入搜索内容开始搜索')
          .fontSize(12)
          .fontColor('#999999')
          .padding({ left: 8, top: 6 })
      } else {
        ForEach(this.groupedResults(), (group: SearchGroup) => {
          Column() {
            Row() {
              Text(FileManager.getFileName(group.file)).fontSize(12).fontColor('#3A90DB').fontWeight(FontWeight.Bold)
              Text('  ' + group.matches.length.toString() + ' 处匹配').fontSize(10).fontColor('#999')
            }
            .width('100%').padding({ left: 8, right: 8, top: 6, bottom: 2 })
            .onClick(() => { this.onResultClick(group.file, group.matches[0].line) })

            ForEach(group.matches, (r: SearchResult) => {
              Row() {
                Text('').width(16)
                Text(r.line.toString()).fontSize(10).fontColor('#AAA').fontFamily('monospace').width(28).textAlign(TextAlign.End)
                Text(r.text).fontSize(11).fontColor('#333').fontFamily('monospace').layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%').padding({ left: 8, right: 8, top: 1, bottom: 1 })
              .onClick(() => { this.onResultClick(r.file, r.line) })
            }, (r: SearchResult) => (r.file + '_' + r.line.toString()))
          }
          .width('100%').padding({ bottom: 4 })
        }, (group: SearchGroup) => group.file)
      }
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  ProblemsContent() {
    Column() {
      if (this.errors.length === 0) {
        Row() {
          Text('✓ 没有问题')
            .fontSize(12)
            .fontColor('#4CAF50')
            .fontWeight(FontWeight.Bold)
            .padding({ left: 8, top: 6 })
        }
        .width('100%')
        Row() {
          Text('运行代码以检查错误')
            .fontSize(11)
            .fontColor('#AAAAAA')
        }
        .width('100%')
        .padding({ left: 12, top: 2 })
      } else {
        Row() {
          Text('✗ ' + this.errors.length.toString() + ' 个问题')
            .fontSize(12)
            .fontColor('#CC0000')
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding({ left: 8, top: 6, bottom: 4 })
        ForEach(this.errors, (err: ErrorEntry) => {
          Column() {
            Row() {
              Text(this.getErrIcon(err.errorType))
                .fontSize(13).width(20).textAlign(TextAlign.Center)
              Text(err.errorType)
                .fontSize(11).fontColor('#CC0000').fontWeight(FontWeight.Bold)
              Text(' 行 ' + err.line.toString())
                .fontSize(10).fontColor('#888').margin({ left: 4 })
            }
            .width('100%').padding({ left: 6, top: 4 })
            Row() {
              Text(err.message)
                .fontSize(11).fontColor('#444').fontFamily('monospace')
                .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%').padding({ left: 28, right: 8, top: 2 })
            if (err.source.length > 0) {
              Row() {
                Text(err.source)
                  .fontSize(10).fontColor('#999').fontFamily('monospace')
              }
              .width('100%').padding({ left: 28, right: 8, top: 1, bottom: 4 })
              .backgroundColor('#FFF5F5')
            }
          }
          .width('100%')
          .border({ width: { bottom: 0.5 }, color: '#F0D0D0' })
        }, (err: ErrorEntry) => (err.errorType + '_' + err.line.toString() + '_' + err.message.substring(0, 20)))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  private getEntryColor(entryType: string): string {
    if (entryType === 'error') return '#CC0000'
    if (entryType === 'warn') return '#E67E00'
    if (entryType === 'info') return '#3A90DB'
    if (entryType === 'system') return '#2E7D32'
    if (entryType === 'success') return '#2E7D32'
    if (entryType === 'data') return '#6A1B9A'
    return '#333333'
  }

  private getEntryIcon(entryType: string): string {
    if (entryType === 'error') return '✗'
    if (entryType === 'warn') return '⚠'
    if (entryType === 'info') return '▶'
    if (entryType === 'system') return '●'
    if (entryType === 'success') return '✓'
    if (entryType === 'data') return '◆'
    return ' '
  }

  private getEntryBg(entryType: string): string {
    if (entryType === 'error') return '#FFF5F5'
    if (entryType === 'warn') return '#FFF8F0'
    return 'transparent'
  }

  private groupedResults(): SearchGroup[] {
    let map: Record<string, SearchResult[]> = {}
    for (let i = 0; i < this.searchResults.length; i++) {
      let r: SearchResult = this.searchResults[i]
      if (map[r.file] === undefined) { map[r.file] = [] }
      map[r.file].push(r)
    }
    let groups: SearchGroup[] = []
    let keys: string[] = Object.keys(map)
    for (let i = 0; i < keys.length; i++) {
      let file: string = keys[i]
      let val: SearchResult[] | undefined = map[file]
      if (val !== undefined) {
        let filtered: SearchResult[] = []
        for (let j = 0; j < val.length; j++) {
          if (val[j] !== undefined) { filtered.push(val[j]) }
        }
        groups.push({ file: file, matches: filtered })
      }
    }
    return groups
  }

  private getErrIcon(errorType: string): string {
    if (errorType === 'SyntaxError') return '✕'
    if (errorType === 'IndentationError') return '↹'
    if (errorType === 'RuntimeError') return '⚡'
    if (errorType === 'NameError') return '？'
    if (errorType === 'TypeError') return '⚠'
    return '✕'
  }

  @Builder
  OutputContent() {
    Column() {
      Row() {
        Text('输出')
          .fontSize(12)
          .fontColor('#333333')
          .fontWeight(FontWeight.Bold)
          .padding({ left: 8, top: 6 })
      }
      .width('100%')
      ForEach(this.consoleEntries, (entry: ConsoleEntry) => {
        if (entry.entryType === 'output') {
          Row() {
            Text(entry.text)
              .fontSize(12)
              .fontColor('#333333')
              .fontFamily('monospace')
              .layoutWeight(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding({ left: 12, right: 8, top: 1, bottom: 1 })
          .alignItems(VerticalAlign.Top)
        }
      }, (entry: ConsoleEntry) => entry.timestamp.toString())
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
      // 面板标题栏（可拖拽调整高度）
      Row() {
        this.TabBtn('terminal', '终端')
        this.TabBtn('output', '输出')
        this.TabBtn('problems', '问题')
        this.TabBtn('search', '搜索结果')

        Blank()

        // 清除终端按钮
        if (this.bottomTab === 'terminal') {
          Text('🗑')
            .fontSize(11)
            .fontColor('#888888')
            .width(20)
            .height(20)
            .textAlign(TextAlign.Center)
            .borderRadius(3)
            .onClick(() => { this.onClearTerminal() })
        }
        // 折叠按钮
        Text(this.bottomCollapsed ? '▲' : '▼')
          .fontSize(10)
          .fontColor('#666666')
          .width(20)
          .height(20)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.onCollapse() })
      }
      .width('100%')
      .height(26)
      .backgroundColor('#F0F0F0')
      .padding({ left: 4, right: 2 })
      .alignItems(VerticalAlign.Center)
      .border({ width: { top: 1, left: 1, bottom: 0, right: 0 }, color: '#B0B0B0' })
      .backgroundColor(this.bottomCollapsed ? '#F0F0F0' : '#F5F5F5')
      .gesture(
        PanGesture({ direction: PanDirection.Vertical })
          .onActionStart((event: GestureEvent) => {
            this.dragStartHeight = this.panelHeight
          })
          .onActionUpdate((event: GestureEvent) => {
            let newHeight: number = this.dragStartHeight - event.offsetY
            if (newHeight < 28) newHeight = 28
            if (newHeight > 500) newHeight = 500
            this.panelHeight = newHeight
          })
      )

      // 面板内容
      if (!this.bottomCollapsed) {
        Scroll(this.scroller) {
          Column() {
            if (this.bottomTab === 'terminal') {
              this.TerminalContent()
            } else if (this.bottomTab === 'problems') {
              this.ProblemsContent()
            } else if (this.bottomTab === 'output') {
              this.OutputContent()
            } else if (this.bottomTab === 'search') {
              this.SearchResultsContent()
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .border({ width: { left: 1 }, color: '#B0B0B0' })
        .padding({ left: 4 })
        .align(Alignment.TopStart)
      }
    }
    .width('100%')
    .height(this.bottomCollapsed ? 26 : this.panelHeight)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.08)', offsetY: -2 })
    .alignItems(HorizontalAlign.Start)
  }
}
