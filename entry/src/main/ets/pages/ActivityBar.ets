@Component
export struct ActivityBar {
  @Prop activeIcon: string = 'files'
  @Prop gitBadge: number = 0
  onIconClick: (id: string) => void = () => {}
  @State hoveredIcon: string = ''

  build() {
    Column() {
      this.BarIcon('files', '📁', '文\n件')
      Divider().width(22).height(1).color('#C0C0C0')
      this.BarIcon('search', '🔍', '搜\n索')
      Divider().width(22).height(1).color('#C0C0C0')
      this.BarIcon('git', '⎇', '源\n码', this.gitBadge)
      Divider().width(22).height(1).color('#C0C0C0')
      this.BarIcon('run', '▶', '运\n行')
      Divider().width(22).height(1).color('#C0C0C0')
      this.BarIcon('extensions', '◫', '扩\n展')
      Divider().width(22).height(1).color('#C0C0C0')
      this.BarIcon('settings', '⚙', '设\n置')
    }
    .width(26)
    .height('100%')
    .backgroundColor('#E6E8EB')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  BarIcon(id: string, icon: string, tooltip: string, badge?: number) {
    Column() {
      Stack() {
        Text(icon)
          .fontSize(18)
          .fontColor(this.activeIcon === id ? '#3A90DB' : '#666666')
          .width(26).height(22)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.activeIcon === id ? 'rgba(58,144,219,0.12)' :
            (this.hoveredIcon === id ? 'rgba(0,0,0,0.05)' : 'transparent'))
          .border({
            width: { left: this.activeIcon === id ? 2 : 0 },
            color: '#3A90DB'
          })
          .borderRadius(2)
        if (badge !== undefined && badge > 0) {
          Text(badge.toString())
            .fontSize(8).fontColor('#FFFFFF')
            .width(14).height(14).textAlign(TextAlign.Center)
            .backgroundColor('#CC3333').borderRadius(7)
            .position({ x: 14, y: 0 })
        }
      }
      .width(26).height(22).alignContent(Alignment.Center)
      Text(tooltip)
        .fontSize(7)
        .fontColor(this.activeIcon === id ? '#3A90DB' : '#999999')
        .lineHeight(9)
        .textAlign(TextAlign.Center)
    }
    .width(26)
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onHover((isHover: boolean) => { this.hoveredIcon = isHover ? id : '' })
    .onClick(() => { this.onIconClick(id) })
  }
}
