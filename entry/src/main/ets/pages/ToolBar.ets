@Component
export struct ToolBar {
  @Prop isRunning: boolean = false
  @Prop canUndo: boolean = false
  @Prop canRedo: boolean = false
  @Prop hasSelection: boolean = false
  onNew: () => void = () => {}
  onNewFolder: () => void = () => {}
  onOpen: () => void = () => {}
  onSave: () => void = () => {}
  onSaveAs: () => void = () => {}
  onClose: () => void = () => {}
  onRun: () => void = () => {}
  onStop: () => void = () => {}
  onUndo: () => void = () => {}
  onRedo: () => void = () => {}
  onCut: () => void = () => {}
  onCopy: () => void = () => {}
  onPaste: () => void = () => {}
  onSearch: () => void = () => {}
  @State hoveredBtn: string = ''
  @State pressedBtn: string = ''

  @Builder
  ToolBtn(id: string, icon: string, label: string, enabled: boolean) {
    Column() {
      Text(icon)
        .fontSize(18)
        .opacity(enabled ? 1.0 : 0.25)
      Text(label)
        .fontSize(8)
        .fontColor(enabled ? '#555555' : '#CCCCCC')
    }
    .width(44)
    .height(44)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.pressedBtn === id ? '#C0C0C0' :
      (this.hoveredBtn === id && enabled ? '#D8D8D8' : 'transparent'))
    .borderRadius(4)
    .onHover((isHover: boolean) => {
      this.hoveredBtn = isHover ? id : ''
    })
    .onClick(() => {
      if (!enabled) return
      this.pressedBtn = id
      setTimeout(() => { this.pressedBtn = '' }, 120)
      if (id === 'new') this.onNew()
      else if (id === 'newfolder') this.onNewFolder()
      else if (id === 'open') this.onOpen()
      else if (id === 'save') this.onSave()
      else if (id === 'saveas') this.onSaveAs()
      else if (id === 'close') this.onClose()
      else if (id === 'undo') this.onUndo()
      else if (id === 'redo') this.onRedo()
      else if (id === 'cut') this.onCut()
      else if (id === 'copy') this.onCopy()
      else if (id === 'paste') this.onPaste()
      else if (id === 'search') this.onSearch()
    })
  }

  build() {
    Row() {
      // 运行
      Column() {
        Text(this.isRunning ? '■' : '▶')
          .fontSize(18)
          .fontColor(this.isRunning ? '#CC0000' : '#3A90DB')
        Text(this.isRunning ? '停止' : '运行')
          .fontSize(8)
          .fontColor('#555555')
      }
      .width(44)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.pressedBtn === 'run' ? '#C0C0C0' :
        (this.hoveredBtn === 'run' ? '#D8D8D8' : 'transparent'))
      .borderRadius(4)
      .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'run' : '' })
      .onClick(() => {
        this.pressedBtn = 'run'
        setTimeout(() => { this.pressedBtn = '' }, 120)
        if (this.isRunning) { this.onStop() } else { this.onRun() }
      })

      this.Divider()

      this.ToolBtn('new', '📄', '新建', true)
      this.ToolBtn('newfolder', '📂⁺', '新建文件夹', true)
      this.ToolBtn('open', '📂', '打开', true)
      this.ToolBtn('save', '💾', '保存', true)
      this.ToolBtn('saveas', '📑', '另存', true)

      this.Divider()

      this.ToolBtn('undo', '↩', '撤销', this.canUndo)
      this.ToolBtn('redo', '↪', '重做', this.canRedo)

      this.Divider()

      this.ToolBtn('cut', '✂', '剪切', this.hasSelection)
      this.ToolBtn('copy', '📋', '复制', this.hasSelection)
      this.ToolBtn('paste', '📌', '粘贴', true)

      Blank()
    }
    .width('100%')
    .height(48)
    .backgroundColor('#F0F0F0')
    .padding({ left: 4, right: 4 })
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 1 }, color: '#D0D0D0' })
  }

  @Builder
  Divider() {
    Divider().vertical(true).height(28).color('#C8C8C8').margin({ left: 2, right: 2 })
  }
}
