import { IDESettings } from '../models/IDEModels';

@Component
export struct CodeEditor {
  @Prop editorContent: string = ''
  @Prop codeLines: string[] = ['']
  @Prop settings: IDESettings = new IDESettings()
  @Prop currentLine: number = 1
  @Prop breakpoints: number[] = []
  onContentChange: (value: string) => void = () => {}

  build() {
    Row() {
      // 行号列
      Column() {
        ForEach(this.codeLines, (_line: string, idx: number) => {
          Row() {
            Text(this.hasBreakpoint(idx + 1) ? '●' : ' ')
              .fontSize(8).fontColor('#CC0000').width(12).textAlign(TextAlign.Center)
            Text((idx + 1).toString())
              .fontSize(this.settings.fontSize - 2)
              .fontColor(idx + 1 === this.currentLine ? '#3A90DB' : '#BBBBBB')
              .fontWeight(idx + 1 === this.currentLine ? FontWeight.Bold : FontWeight.Normal)
              .fontFamily('monospace')
              .textAlign(TextAlign.End)
              .width(30)
          }
          .width(44)
          .height(this.settings.fontSize * 1.6)
          .backgroundColor(idx + 1 === this.currentLine ? '#E8F0F8' : 'transparent')
        }, (_line: string, idx: number) => ('ln_' + idx.toString()))
      }
      .width(48)
      .height('100%')
      .backgroundColor('#F8F8F8')
      .padding({ top: 8, right: 6 })
      .border({ width: { right: 1 }, color: '#E0E0E0' })

      // 编辑区
      TextArea({ placeholder: '', text: this.editorContent })
        .fontSize(this.settings.fontSize)
        .fontFamily('monospace')
        .fontColor('#1E1E1E')
        .backgroundColor('#FFFFFF')
        .layoutWeight(1)
        .height('100%')
        .padding({ top: 8, bottom: 8, left: 10, right: 8 })
        .onChange((value: string) => {
          this.onContentChange(value)
        })
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 1 }, color: '#D0D0D0' })
  }

  private hasBreakpoint(line: number): boolean {
    for (let i = 0; i < this.breakpoints.length; i++) {
      if (this.breakpoints[i] === line) return true
    }
    return false
  }
}
