export class ClipboardManager {
  private text: string = '';

  cut(content: string): string {
    this.text = content;
    return content;  // 安全行为：无选区时保留原内容
  }

  copy(content: string): string {
    this.text = content;
    return content;
  }

  paste(currentContent: string): string {
    if (this.text.length > 0) {
      return currentContent + this.text;
    }
    return currentContent;
  }

  hasContent(): boolean {
    return this.text.length > 0;
  }
}
