import { VariableEntry } from '../models/IDEModels';

@Component
export struct RightPanel {
  @Prop rightPanelTab: string = 'variables'
  @Prop variables: VariableEntry[] = []
  @Prop fontSize: number = 14
  onTabChange: (tab: string) => void = () => {}
  onClose: () => void = () => {}
  onFontSizeChange: (delta: number) => void = () => {}
  @State hoveredTab: string = ''

  build() {
    Column() {
      // 标题
      Row() {
        Text('▸ 工具箱')
          .fontSize(11)
          .fontColor('#333333')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('✕')
          .fontSize(10)
          .fontColor('#888888')
          .width(22)
          .height(22)
          .textAlign(TextAlign.Center)
          .borderRadius(3)
          .onClick(() => { this.onClose() })
      }
      .width('100%')
      .height(28)
      .padding({ left: 8, right: 4 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#F0F0F0')
      .border({ width: { bottom: 1 }, color: '#D0D0D0' })

      // 标签
      Row() {
        this.TabBtn('variables', '变量')
        this.TabBtn('console', '控制台')
        this.TabBtn('breakpoints', '断点')
        this.TabBtn('extensions', '扩展')
        Blank()
      }
      .width('100%')
      .height(28)
      .backgroundColor('#F5F5F5')
      .border({ width: { bottom: 1 }, color: '#E0E0E0' })
      .padding({ left: 2 })

      Column() {
        if (this.rightPanelTab === 'variables') {
          this.VariablesContent()
        } else if (this.rightPanelTab === 'extensions') {
          this.ExtensionsContent()
        } else {
          this.ConsoleContent()
        }
      }
      .layoutWeight(1).width('100%')
    }
    .width(200)
    .height('100%')
    .backgroundColor('#FFFFFF')
    .alignItems(HorizontalAlign.Start)
    .border({ width: { left: 1 }, color: '#D0D0D0' })
  }

  @Builder
  ExtensionsContent() {
    Scroll() {
      Column() {
        // 字体大小
        Text('字体大小').fontSize(12).fontWeight(FontWeight.Bold).fontColor('#333')
          .padding({ left: 8, top: 8, bottom: 4 })
        Row() {
          Text('当前: ' + this.fontSize.toString() + 'px').fontSize(11).fontColor('#666')
          Blank()
          Text('A-').fontSize(14).width(36).height(28)
            .textAlign(TextAlign.Center).fontColor('#FFFFFF')
            .backgroundColor('#888888').borderRadius(4)
            .onClick(() => { this.onFontSizeChange(-1) })
          Text('A+').fontSize(14).width(36).height(28)
            .textAlign(TextAlign.Center).fontColor('#FFFFFF')
            .backgroundColor('#888888').borderRadius(4)
            .margin({ left: 6 })
            .onClick(() => { this.onFontSizeChange(1) })
        }.width('100%').padding({ left: 8, right: 8 })

        Divider().width('100%').height(1).color('#E0E0E0').margin({ top: 8, bottom: 8 })

        // 快捷键速查
        Text('快捷键').fontSize(12).fontWeight(FontWeight.Bold).fontColor('#333')
          .padding({ left: 8, bottom: 4 })
        Column() {
          this.ShortcutRow('Ctrl+S', '保存')
          this.ShortcutRow('Ctrl+Z', '撤销')
          this.ShortcutRow('Ctrl+Y', '重做')
          this.ShortcutRow('Ctrl+F', '查找')
          this.ShortcutRow('Ctrl+C', '复制')
          this.ShortcutRow('Ctrl+V', '粘贴')
          this.ShortcutRow('Ctrl+X', '剪切')
          this.ShortcutRow('Ctrl+A', '全选')
        }.width('100%')

        Divider().width('100%').height(1).color('#E0E0E0').margin({ top: 8, bottom: 8 })

        // 关于
        Text('关于').fontSize(12).fontWeight(FontWeight.Bold).fontColor('#333')
          .padding({ left: 8, bottom: 4 })
        Text('Eric6 IDE for HarmonyOS').fontSize(11).fontColor('#666').padding({ left: 8 })
        Text('版本 v19.05').fontSize(11).fontColor('#999').padding({ left: 8, top: 2 })
        Text('基于 Eric6 PyQt5 IDE').fontSize(10).fontColor('#BBB').padding({ left: 8, top: 4 })
      }.width('100%').alignItems(HorizontalAlign.Start)
    }
    .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto)
    .layoutWeight(1).width('100%')
  }

  @Builder
  ShortcutRow(key: string, action: string) {
    Row() {
      Text(key).fontSize(10).fontColor('#3A90DB').fontFamily('monospace')
        .width(60).padding({ left: 8 })
      Text(action).fontSize(11).fontColor('#666')
    }.width('100%').height(22)
  }

  @Builder
  TabBtn(id: string, label: string) {
    Text(label)
      .fontSize(11)
      .fontColor(this.rightPanelTab === id ? '#333333' : (this.hoveredTab === id ? '#444444' : '#777777'))
      .fontWeight(this.rightPanelTab === id ? FontWeight.Bold : FontWeight.Normal)
      .padding({ left: 10, right: 10, top: 3, bottom: 3 })
      .backgroundColor(this.hoveredTab === id && this.rightPanelTab !== id ? '#E8E8E8' : 'transparent')
      .borderRadius(2)
      .border({
        width: { bottom: this.rightPanelTab === id ? 2 : 0 },
        color: this.rightPanelTab === id ? '#3A90DB' : 'transparent'
      })
      .animation({ duration: 120, curve: Curve.EaseOut })
      .onHover((isHover: boolean) => { this.hoveredTab = isHover ? id : '' })
      .onClick(() => { this.onTabChange(id) })
  }

  @Builder
  VariablesContent() {
    if (this.variables.length === 0) {
      Text('暂无变量')
        .fontSize(12)
        .fontColor('#AAAAAA')
        .padding({ left: 8, top: 8 })
    } else {
      Row() {
        Text('名称').fontSize(10).fontColor('#999').fontWeight(FontWeight.Bold).width(70).padding({ left: 6 })
        Text('类型').fontSize(10).fontColor('#999').fontWeight(FontWeight.Bold).width(48)
        Text('值').fontSize(10).fontColor('#999').fontWeight(FontWeight.Bold).layoutWeight(1)
      }
      .width('100%').height(20).backgroundColor('#F5F5F5').border({ width: { bottom: 1 }, color: '#E0E0E0' })

      Scroll() {
        Column() {
          ForEach(this.variables, (v: VariableEntry, idx: number) => {
            Row() {
              Text(v.name).fontSize(11).fontColor('#3A90DB').fontFamily('monospace').fontWeight(FontWeight.Bold).width(70).padding({ left: 6 })
              Text(v.varType).fontSize(10).fontColor('#888').fontFamily('monospace').width(48)
              Text(v.value).fontSize(11).fontColor('#333').fontFamily('monospace').layoutWeight(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%').height(22).backgroundColor(idx % 2 === 0 ? '#FFFFFF' : '#F8F8F8').alignItems(VerticalAlign.Center)
          }, (v: VariableEntry) => v.name)
        }.width('100%')
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto)
      .layoutWeight(1).width('100%').align(Alignment.TopStart)
    }
  }

  @Builder
  ConsoleContent() {
    Column() {
      Text('调试控制台').fontSize(12).fontColor('#AAAAAA').margin({ top: 20 })
      Text('暂无交互').fontSize(11).fontColor('#CCCCCC').margin({ top: 4 })
    }
    .width('100%').alignItems(HorizontalAlign.Center)
  }
}
