import { TabItem } from '../models/IDEModels';

@Component
export struct EditorTabBar {
  @Prop tabs: TabItem[] = []
  @Prop activeTabId: string = ''
  onTabClick: (tabId: string) => void = () => {}
  onTabClose: (tabId: string) => void = () => {}
  @State hoveredTabId: string = ''
  @State hoveredCloseId: string = ''

  build() {
    Row() {
      ForEach(this.tabs, (tab: TabItem) => {
        Row() {
          Text(this.getTabIcon(tab.name))
            .fontSize(11)
            .fontColor(this.getTabColor(tab.name))
            .margin({ right: 4 })

          Text(tab.name)
            .fontSize(11)
            .fontColor(this.activeTabId === tab.id ? '#000000' : '#555555')
            .fontWeight(this.activeTabId === tab.id ? FontWeight.Bold : FontWeight.Normal)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)

          if (tab.isModified) {
            Text('●').fontSize(9).fontColor('#3A90DB').margin({ left: 3 })
          }

          Text('✕')
            .fontSize(9)
            .fontColor(this.hoveredCloseId === tab.id ? '#CC0000' : '#BBBBBB')
            .padding({ left: 4, right: 4 }).borderRadius(2)
            .backgroundColor(this.hoveredCloseId === tab.id ? '#FFE0E0' : 'transparent')
            .animation({ duration: 120, curve: Curve.EaseOut })
            .onHover((isHover: boolean) => { this.hoveredCloseId = isHover ? tab.id : '' })
            .onClick(() => { this.onTabClose(tab.id) })
        }
        .height(26).padding({ left: 10, right: 4 })
        .backgroundColor(this.activeTabId === tab.id ? '#FFFFFF' :
          (this.hoveredTabId === tab.id ? '#E8E8E8' : 'transparent'))
        .border({
          width: { top: this.activeTabId === tab.id ? 2 : 0, left: 1, right: 1, bottom: 0 },
          color: this.activeTabId === tab.id ? '#3A90DB' : 'transparent'
        })
        .animation({ duration: 150, curve: Curve.EaseOut })
        .onHover((isHover: boolean) => { this.hoveredTabId = isHover ? tab.id : '' })
        .onClick(() => { this.onTabClick(tab.id) })
        .margin({ top: this.activeTabId === tab.id ? 0 : 2 })
      }, (tab: TabItem) => tab.id)

      Blank()
    }
    .width('100%').height(28).backgroundColor('#E0E0E0')
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 1 }, color: '#C0C0C0' })
  }

  private getTabIcon(name: string): string {
    if (name.endsWith('.py')) return '🐍'
    if (name.endsWith('.rb')) return '💎'
    if (name.endsWith('.js')) return '📜'
    if (name.endsWith('.ts')) return '📘'
    if (name.endsWith('.json')) return '⚙'
    if (name.endsWith('.md')) return '📝'
    if (name.endsWith('.html')) return '🌐'
    if (name.endsWith('.css')) return '🎨'
    return '📄'
  }

  private getTabColor(name: string): string {
    return '#666666'
  }
}
