flowchart TD
  Start[Start] --> PlatformEntries[Native Platform Entry Points]
  PlatformEntries --> EngineInit[Initialize Flutter Engine]
  EngineInit --> DartRun[Run Flutter Dart Code]
  DartRun --> UIRender[Render User Interface]
  UIRender --> HomePage[Display Home Page with Counter]
  HomePage --> UserTap[User Taps Floating Action Button]
  UserTap --> IncrementCounter[Invoke setState to Increment Counter]
  IncrementCounter --> UIUpdate[Update UI with New Counter]
  UIUpdate --> HomePage