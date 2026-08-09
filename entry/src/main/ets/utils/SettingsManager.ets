import { IDESettings } from '../models/IDEModels';

let g_settings: IDESettings = new IDESettings();

export class SettingsManager {
  static getSettings(): IDESettings {
    return g_settings;
  }

  static updateFontSize(size: number): void {
    g_settings.fontSize = size;
  }

  static updateTheme(theme: string): void {
    g_settings.theme = theme;
  }

  static updateTabSize(size: number): void {
    g_settings.tabSize = size;
  }

  static toggleLineNumbers(): void {
    g_settings.showLineNumbers = !g_settings.showLineNumbers;
  }

  static toggleAutoIndent(): void {
    g_settings.autoIndent = !g_settings.autoIndent;
  }

  static resetToDefaults(): void {
    g_settings = new IDESettings();
  }
}
