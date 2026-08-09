export class UndoManager {
  private undoStack: string[] = [];
  private redoStack: string[] = [];
  private isUndoRedo: boolean = false;

  init(initialContent: string): void {
    this.undoStack = [initialContent];
    this.redoStack = [];
  }

  reset(initialContent: string): void {
    this.undoStack = [initialContent];
    this.redoStack = [];
  }

  pushState(content: string): void {
    if (this.isUndoRedo) return;
    let last: string = this.undoStack.length > 0 ? this.undoStack[this.undoStack.length - 1] : '';
    if (last === content) return;

    // 多字符变更拆成逐字符记录
    let diff: number = content.length - last.length;
    if (diff > 1 || diff < -1) {
      let steps: string[] = [];
      if (diff > 0) {
        for (let i = last.length + 1; i <= content.length; i++) {
          steps.push(content.substring(0, i));
        }
      } else {
        for (let i = last.length - 1; i >= content.length; i--) {
          steps.push(last.substring(0, i));
        }
      }
      let newStack: string[] = [];
      for (let i = 0; i < this.undoStack.length; i++) newStack.push(this.undoStack[i]);
      for (let i = 0; i < steps.length; i++) newStack.push(steps[i]);
      this.undoStack = newStack;
      this.redoStack = [];
    } else {
      let newStack: string[] = [];
      for (let i = 0; i < this.undoStack.length; i++) newStack.push(this.undoStack[i]);
      newStack.push(content);
      this.undoStack = newStack;
      this.redoStack = [];
    }
  }

  undo(): string | null {
    if (this.undoStack.length <= 1) return null;
    this.isUndoRedo = true;

    let current: string = this.undoStack[this.undoStack.length - 1];

    let newUndo: string[] = [];
    for (let i = 0; i < this.undoStack.length - 1; i++) {
      newUndo.push(this.undoStack[i]);
    }
    this.undoStack = newUndo;

    let newRedo: string[] = [];
    for (let i = 0; i < this.redoStack.length; i++) {
      newRedo.push(this.redoStack[i]);
    }
    newRedo.push(current);
    this.redoStack = newRedo;

    let prev: string = this.undoStack[this.undoStack.length - 1];
    this.isUndoRedo = false;
    return prev;
  }

  redo(): string | null {
    if (this.redoStack.length === 0) return null;
    this.isUndoRedo = true;

    let next: string = this.redoStack[this.redoStack.length - 1];

    let newRedo: string[] = [];
    for (let i = 0; i < this.redoStack.length - 1; i++) {
      newRedo.push(this.redoStack[i]);
    }
    this.redoStack = newRedo;

    let newUndo: string[] = [];
    for (let i = 0; i < this.undoStack.length; i++) {
      newUndo.push(this.undoStack[i]);
    }
    newUndo.push(next);
    this.undoStack = newUndo;

    this.isUndoRedo = false;
    return next;
  }

  canUndo(): boolean {
    return this.undoStack.length > 1;
  }

  canRedo(): boolean {
    return this.redoStack.length > 0;
  }

  getCurrentContent(): string {
    return this.undoStack.length > 0 ? this.undoStack[this.undoStack.length - 1] : '';
  }
}
