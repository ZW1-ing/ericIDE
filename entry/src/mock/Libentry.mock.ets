const NativeMock: Record<string, Object> = {
  'runPython': (code: string) => {
    return '[Mock] Python execution not available in preview mode.\n';
  },
  'runRuby': (code: string) => {
    return '[Mock] Ruby runtime not integrated.\n';
  },
  'getSupportedLanguages': () => {
    return 'python,ruby';
  },
};

export default NativeMock;
