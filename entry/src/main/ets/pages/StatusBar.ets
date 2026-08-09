import { Language } from '../models/IDEModels';

@Component
export struct StatusBar {
  @Prop currentLanguage: Language = Language.PYTHON
  @Prop cursorLine: number = 1
  @Prop cursorCol: number = 1
  @Prop fileName: string = ''
  @Prop errorCount: number = 0
  onLanguageClick: () => void = () => {}
  onCursorClick: () => void = () => {}
  onErrorClick: () => void = () => {}

  build() {
    Row() {
      // 错误/警告指示器
      if (this.errorCount > 0) {
        Row() {
          Text('✕ ' + this.errorCount)
            .fontSize(11).fontColor('#FFFFFF')
        }
        .padding({ left: 8, right: 8 }).height(22)
        .backgroundColor('#CC0000')
        .onClick(() => { this.onErrorClick() })
      } else {
        Row() {
          Text('✓').fontSize(10).fontColor('#4CAF50')
        }
        .padding({ left: 6, right: 6 }).height(22)
      }

      // 语言模式
      Text(this.getLangLabel())
        .fontSize(11).fontColor('#FFFFFF')
        .padding({ left: 8, right: 8 })
        .onClick(() => { this.onLanguageClick() })

      // 文件名
      Text(this.fileName)
        .fontSize(11).fontColor('#CCCCCC').padding({ left: 8 })

      Blank()

      // 行列（可点击跳转）
      Text('Ln ' + this.cursorLine + ', Col ' + this.cursorCol)
        .fontSize(11).fontColor('#CCCCCC').padding({ left: 8, right: 8 })
        .onClick(() => { this.onCursorClick() })

      Text('UTF-8')
        .fontSize(11).fontColor('#CCCCCC').padding({ left: 8, right: 8 })

      Text('Eric6')
        .fontSize(11).fontColor('#888888').padding({ left: 8, right: 8 })
    }
    .width('100%').height(22).backgroundColor('#007ACC')
    .padding({ left: 4, right: 4 }).alignItems(VerticalAlign.Center)
  }

  private getLangLabel(): string {
    if (this.currentLanguage === Language.PYTHON) return 'Python'
    if (this.currentLanguage === Language.RUBY) return 'Ruby'
    if (this.currentLanguage === Language.JAVASCRIPT) return 'JavaScript'
    if (this.currentLanguage === Language.TYPESCRIPT) return 'TypeScript'
    if (this.currentLanguage === Language.HTML) return 'HTML'
    if (this.currentLanguage === Language.CSS) return 'CSS'
    if (this.currentLanguage === Language.JSON) return 'JSON'
    if (this.currentLanguage === Language.MARKDOWN) return 'Markdown'
    return 'Plain Text'
  }
}
