import { SearchResult } from '../models/IDEModels';
import { FileManager } from '../utils/FileManager';

@Component
export struct CommandPalette {
  @Prop showSearch: boolean = false
  @Prop searchQuery: string = ''
  @Prop matchCount: number = 0
  @Prop results: SearchResult[] = []
  onSearchChange: (value: string) => void = () => {}
  onSearchClose: () => void = () => {}
  onCommand: (action: string) => void = () => {}
  onResultClick: (filePath: string, line: number) => void = () => {}

  build() {
    if (this.showSearch) {
      Column() {
        Row() {
          Text(this.searchQuery.startsWith('>') ? '>' : '🔍')
            .fontSize(12)
            .fontColor(this.searchQuery.startsWith('>') ? '#E98300' : '#666666')
            .margin({ right: 4 })

          TextArea({
            placeholder: this.searchQuery.startsWith('>') ? '输入命令...' : '搜索...',
            text: this.searchQuery
          })
            .fontSize(12).fontFamily('monospace').backgroundColor('#FFFFFF')
            .layoutWeight(1).height(26).padding(0)
            .onChange((value: string) => { this.onSearchChange(value) })

          if (!this.searchQuery.startsWith('>') && this.searchQuery.length > 0) {
            Text(this.matchCount.toString())
              .fontSize(11)
              .fontColor(this.matchCount > 0 ? '#333333' : '#CC0000')
              .padding({ left: 4, right: 4 })
          }

          Text('✕')
            .fontSize(12).fontColor('#666666')
            .padding({ left: 8, right: 8 })
            .onClick(() => { this.onSearchClose() })
        }
        .width('100%').height(32).padding({ left: 8, right: 8 })
        .backgroundColor('#F0F0F0').border({ width: { bottom: 1 }, color: '#D0D0D0' })

        if (!this.searchQuery.startsWith('>') && this.results.length > 0) {
          Column() {
            ForEach(this.results, (r: SearchResult, idx: number) => {
              Row() {
                Text(FileManager.getFileName(r.file))
                  .fontSize(10).fontColor('#3A90DB').fontFamily('monospace')
                  .width(55).maxLines(1)
                Text(r.line.toString())
                  .fontSize(10).fontColor('#999').fontFamily('monospace')
                  .width(24).textAlign(TextAlign.End)
                Text(r.text)
                  .fontSize(11).fontColor('#333').fontFamily('monospace')
                  .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%').height(24).padding({ left: 8, right: 8 })
              .backgroundColor(idx % 2 === 0 ? '#FFFFFF' : '#F8F8F8')
              .onClick(() => { this.onResultClick(r.file, r.line) })
            }, (r: SearchResult, idx: number) => 'sr_' + idx.toString())
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .border({ width: { bottom: 1 }, color: '#E0E0E0' })
          .constraintSize({ maxHeight: 200 })
        }

        if (this.searchQuery.startsWith('>')) {
          Row() {
            Text('命令: new save undo redo find run stop zoomin zoomout refresh about')
              .fontSize(10).fontColor('#999999').padding({ left: 12, top: 2, bottom: 2 })
          }.width('100%').backgroundColor('#F8F8F8')
        }
      }
    }
  }
}
