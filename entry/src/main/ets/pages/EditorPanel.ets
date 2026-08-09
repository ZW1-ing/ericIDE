import { TabItem, ConsoleEntry, IDESettings, SearchResult, ErrorEntry } from '../models/IDEModels';
import { EditorTabBar } from './TabBar';
import { CodeEditor } from './CodeEditor';
import { BottomPanel } from './BottomPanel';

@Component
export struct EditorPanel {
  @Prop tabs: TabItem[] = []
  @Prop activeTabId: string = ''
  @Prop editorContent: string = ''
  @Prop codeLines: string[] = ['']
  @Prop settings: IDESettings = new IDESettings()
  @Link consoleEntries: ConsoleEntry[]
  @Prop bottomTab: string = 'terminal'
  @Prop bottomCollapsed: boolean = false
  @Prop searchResults: SearchResult[] = []
  @Prop searchQuery: string = ''
  @Prop errors: ErrorEntry[] = []
  onTabClick: (tabId: string) => void = () => {}
  onTabClose: (tabId: string) => void = () => {}
  onContentChange: (value: string) => void = () => {}
  onTabChange: (tab: string) => void = () => {}
  onCollapse: () => void = () => {}
  onClearTerminal: () => void = () => {}

  build() {
    Column() {
      EditorTabBar({
        tabs: this.tabs,
        activeTabId: this.activeTabId,
        onTabClick: (tabId: string) => { this.onTabClick(tabId) },
        onTabClose: (tabId: string) => { this.onTabClose(tabId) }
      })

      CodeEditor({
        editorContent: this.editorContent,
        codeLines: this.codeLines,
        settings: this.settings,
        onContentChange: (value: string) => { this.onContentChange(value) }
      })

      BottomPanel({
        consoleEntries: $consoleEntries,
        bottomTab: this.bottomTab,
        bottomCollapsed: this.bottomCollapsed,
        searchResults: this.searchResults,
        searchQuery: this.searchQuery,
        errors: this.errors,
        onTabChange: (tab: string) => { this.onTabChange(tab) },
        onCollapse: () => { this.onCollapse() },
        onClearTerminal: () => { this.onClearTerminal() }
      })
    }
    .layoutWeight(1)
    .height('100%')
  }
}
