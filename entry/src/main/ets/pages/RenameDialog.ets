@Component
export struct RenameDialog {
  @Prop renameText: string = ''
  @Prop visible: boolean = false
  onChange: (value: string) => void = () => {}
  onConfirm: () => void = () => {}
  onCancel: () => void = () => {}

  build() {
    if (this.visible) {
      Column() {
        Column() {
          Text('重命名')
            .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#333333')
            .margin({ bottom: 8 })

          TextInput({ text: this.renameText })
            .fontSize(12).width(200).height(32)
            .onChange((v: string) => { this.onChange(v) })

          Row() {
            Button('确定')
              .fontSize(12).width(80).height(28)
              .onClick(() => { this.onConfirm() })
            Button('取消')
              .fontSize(12).width(80).height(28)
              .backgroundColor('#E0E0E0').fontColor('#333333')
              .onClick(() => { this.onCancel() })
          }
          .margin({ top: 12 })
        }
        .width(260).padding(20).backgroundColor('#FFFFFF')
        .borderRadius(8).shadow({ radius: 12, color: 'rgba(0,0,0,0.3)' })
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      .backgroundColor('rgba(0,0,0,0.35)')
      .onClick(() => { this.onCancel() })
    }
  }
}
