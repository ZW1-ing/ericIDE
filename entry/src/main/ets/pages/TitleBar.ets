@Component
export struct TitleBar {
  @State hoveredBtn: string = ''
  onMinimize: () => void = () => {}
  onMaximize: () => void = () => {}
  onClose: () => void = () => {}

  build() {
    Row() {
      // Eric6 logo icon
      Text('●')
        .fontSize(12)
        .fontColor('#40CE40')
        .width(28)
        .height('100%')
        .textAlign(TextAlign.Center)

      // 标题文字
      Text('Eric6 IDE')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ right: 8 })

      // 窗口标题
      Text('— 主窗口 [未命名]')
        .fontSize(12)
        .fontColor('#666666')
        .layoutWeight(1)

      // 窗口控制按钮
      Text('─')
        .fontSize(13)
        .fontColor(this.hoveredBtn === 'min' ? '#333333' : '#888888')
        .width(36)
        .height(28)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.hoveredBtn === 'min' ? '#D0D0D0' : 'transparent')
        .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'min' : '' })
        .onClick(() => { this.onMinimize() })

      Text('□')
        .fontSize(13)
        .fontColor(this.hoveredBtn === 'max' ? '#333333' : '#888888')
        .width(36)
        .height(28)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.hoveredBtn === 'max' ? '#D0D0D0' : 'transparent')
        .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'max' : '' })
        .onClick(() => { this.onMaximize() })

      Text('✕')
        .fontSize(13)
        .fontColor(this.hoveredBtn === 'close' ? '#FFFFFF' : '#888888')
        .width(36)
        .height(28)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.hoveredBtn === 'close' ? '#C42B1C' : 'transparent')
        .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'close' : '' })
        .onClick(() => { this.onClose() })
    }
    .width('100%')
    .height(30)
    .backgroundColor('#E8E8E8')
    .padding({ left: 8, right: 0 })
    .alignItems(VerticalAlign.Center)
  }
}
