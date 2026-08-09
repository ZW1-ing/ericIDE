interface MenuItem {
  action: string;
  label: string;
  shortcut: string;
}

@Component
export struct MenuBar {
  @State hoveredMenu: string = ''
  @State openMenu: string = ''
  @State hoveredItem: string = ''
  @State pressedMenu: string = ''
  @State pressedItem: string = ''
  onMenuAction: (action: string) => void = () => {}

  build() {
    Column() {
      Row() {
        this.Trigger('file', '文件')
        this.Trigger('edit', '编辑')
        this.Trigger('search', '搜索')
        this.Trigger('view', '视图')
        this.Trigger('project', '项目')
        this.Trigger('debug', '调试')
        this.Trigger('tools', '工具')
        this.Trigger('window', '窗口')
        this.Trigger('help', '帮助')
      }
      .width('100%').height(30).backgroundColor('#F5F6F7')
      .padding({ left: 2 }).alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: '#E5E6EB' })

      if (this.openMenu !== '') {
        Row() {
          Row() {
            ForEach(this.getItems(this.openMenu), (item: MenuItem, idx: number) => {
              if (item.action === '---') {
                Divider().vertical(true).height(48).color('#F0F0F0').margin({ left: 4, right: 4 })
              } else {
                Column() {
                  Text(item.label).fontSize(13).fontColor('#1F2329').textAlign(TextAlign.Center)
                    .padding({ left: 12, right: 12, top: 10 })
                  Text(item.shortcut).fontSize(10).fontColor('#8F959E').textAlign(TextAlign.Center)
                    .padding({ left: 12, right: 12, bottom: 10 })
                }
                .backgroundColor(this.pressedItem === item.action ? 'rgba(0,0,0,0.08)' :
                  (this.hoveredItem === item.action ? '#F2F3F5' : 'transparent'))
                .borderRadius(6)
                .animation({ duration: 100, curve: Curve.EaseOut })
                .onHover((isHover: boolean) => { this.hoveredItem = isHover ? item.action : '' })
                .onClick(() => {
                  this.pressedItem = item.action
                  setTimeout(() => { this.pressedItem = '' }, 100)
                  this.onMenuAction(item.action)
                })
              }
            }, (item: MenuItem, idx: number) => item.action + '_' + idx.toString())
          }
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#EBECF0' })
          .borderRadius(8)
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.06)', offsetY: 4 })
          .padding({ top: 8, bottom: 8, left: 4, right: 4 })
          Blank()
        }
        .width('100%')
        .padding({ left: 4 })
        .animation({ duration: 120, curve: Curve.EaseOut })
      }
    }
    .width('100%')
  }

  @Builder
  Trigger(id: string, label: string) {
    Text(label)
      .fontSize(13)
      .fontColor(this.openMenu === id ? '#1F2329' : '#4E5969')
      .fontWeight(this.openMenu === id ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: 10, right: 10 }).height(30)
      .backgroundColor(this.pressedMenu === id ? 'rgba(0,0,0,0.1)' :
        (this.openMenu === id ? 'rgba(0,0,0,0.06)' :
        (this.hoveredMenu === id ? 'rgba(0,0,0,0.04)' : 'transparent')))
      .borderRadius(6)
      .animation({ duration: 120, curve: Curve.EaseOut })
      .onHover((isHover: boolean) => {
        this.hoveredMenu = isHover ? id : ''
        if (isHover && this.openMenu !== '' && this.openMenu !== id) {
          this.openMenu = id
        }
      })
      .onClick(() => {
        this.pressedMenu = id
        setTimeout(() => { this.pressedMenu = '' }, 120)
        this.openMenu = (this.openMenu === id) ? '' : id
      })
  }

  private getItems(menuId: string): MenuItem[] {
    let items: MenuItem[] = [];
    if (menuId === 'file') {
      items.push({action: 'new', label: '新建文件', shortcut: 'Ctrl+N'});
      items.push({action: 'newfolder', label: '新建文件夹', shortcut: ''});
      items.push({action: 'open', label: '打开文件', shortcut: 'Ctrl+O'});
      items.push({action: '---', label: '', shortcut: ''});
      items.push({action: 'save', label: '保存', shortcut: 'Ctrl+S'});
      items.push({action: 'saveas', label: '另存为...', shortcut: 'Ctrl+Shift+S'});
      items.push({action: '---', label: '', shortcut: ''});
      items.push({action: 'close', label: '关闭文件', shortcut: 'Ctrl+W'});
    } else if (menuId === 'edit') {
      items.push({action: 'undo', label: '撤销', shortcut: 'Ctrl+Z'});
      items.push({action: 'redo', label: '重做', shortcut: 'Ctrl+Y'});
      items.push({action: '---', label: '', shortcut: ''});
      items.push({action: 'cut', label: '剪切', shortcut: 'Ctrl+X'});
      items.push({action: 'copy', label: '复制', shortcut: 'Ctrl+C'});
      items.push({action: 'paste', label: '粘贴', shortcut: 'Ctrl+V'});
      items.push({action: '---', label: '', shortcut: ''});
      items.push({action: 'selectall', label: '全选', shortcut: 'Ctrl+A'});
    } else if (menuId === 'search') {
      items.push({action: 'find', label: '查找', shortcut: 'Ctrl+F'});
      items.push({action: 'findfiles', label: '在文件中查找', shortcut: 'Ctrl+Shift+F'});
    } else if (menuId === 'view') {
      items.push({action: 'togglefiletree', label: '文件浏览器', shortcut: 'Ctrl+B'});
      items.push({action: 'togglerightpanel', label: '工具箱', shortcut: ''});
      items.push({action: 'togglebottompanel', label: '底部面板', shortcut: ''});
    } else if (menuId === 'project') {
      items.push({action: 'newfolder', label: '新建文件夹', shortcut: ''});
      items.push({action: 'refresh', label: '刷新', shortcut: ''});
    } else if (menuId === 'debug') {
      items.push({action: 'run', label: '运行', shortcut: 'F5'});
      items.push({action: 'stop', label: '停止', shortcut: 'Shift+F5'});
      items.push({action: '---', label: '', shortcut: ''});
      items.push({action: 'togglebreakpoint', label: '切换断点', shortcut: 'F9'});
    } else if (menuId === 'tools') {
      items.push({action: 'clear_terminal', label: '清空终端', shortcut: ''});
      items.push({action: 'copy_path', label: '复制文件路径', shortcut: ''});
      items.push({action: 'code_stats', label: '代码统计', shortcut: ''});
      items.push({action: '---', label: '', shortcut: ''});
      items.push({action: 'togglefiletree', label: '文件树', shortcut: ''});
      items.push({action: 'toggle_expand', label: '展开/折叠文件夹', shortcut: ''});
      items.push({action: '---', label: '', shortcut: ''});
      items.push({action: 'reset_zoom', label: '重置缩放', shortcut: ''});
      items.push({action: 'settings', label: '设置', shortcut: 'Ctrl+,'});
    } else if (menuId === 'window') {
      items.push({action: 'nexttab', label: '下一个标签', shortcut: 'Ctrl+Tab'});
      items.push({action: 'prevtab', label: '上一个标签', shortcut: 'Ctrl+Shift+Tab'});
      items.push({action: '---', label: '', shortcut: ''});
      items.push({action: 'resetlayout', label: '重置布局', shortcut: ''});
    } else {
      items.push({action: 'about', label: '关于', shortcut: ''});
      items.push({action: 'version', label: '版本', shortcut: ''});
    }
    return items;
  }

  private getX(id: string): number {
    let offsets: Record<string, number> = {
      'file': 4, 'edit': 52, 'search': 100, 'view': 148,
      'project': 196, 'debug': 248, 'tools': 296, 'window': 344, 'help': 396
    };
    let val: number | undefined = offsets[id];
    return val !== undefined ? val : 4;
  }
}
