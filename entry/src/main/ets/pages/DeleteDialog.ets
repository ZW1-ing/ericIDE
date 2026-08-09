@Component
export struct DeleteDialog {
  @Prop fileName: string = ''
  @Prop visible: boolean = false
  onConfirm: () => void = () => {}
  onCancel: () => void = () => {}

  build() {
    if (this.visible) {
      Column() {
        Column() {
          Text('确认删除')
            .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#CC0000')
            .margin({ bottom: 10 })

          Text('确定要删除 "' + this.fileName + '" 吗？')
            .fontSize(13).fontColor('#333333')
            .margin({ bottom: 6 })

          Text('此操作不可撤销')
            .fontSize(11).fontColor('#999999')
            .margin({ bottom: 14 })

          Row() {
            Button('取消')
              .fontSize(12).width(80).height(30)
              .backgroundColor('#E8E8E8').fontColor('#333333')
              .onClick(() => { this.onCancel() })
            Button('确认删除')
              .fontSize(12).width(80).height(30)
              .backgroundColor('#CC0000').fontColor('#FFFFFF')
              .margin({ left: 12 })
              .onClick(() => { this.onConfirm() })
          }
        }
        .padding(24).backgroundColor('#FFFFFF').borderRadius(10)
        .shadow({ radius: 16, color: 'rgba(0,0,0,0.3)', offsetY: 4 })
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      .backgroundColor('rgba(0,0,0,0.35)')
      .onClick(() => { this.onCancel() })
    }
  }
}
