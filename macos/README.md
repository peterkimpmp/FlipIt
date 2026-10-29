# FlipIt for macOS

원본 FlipIt(Windows .scr, C#) 디자인을 Swift/AppKit 네이티브 앱으로 옮긴 데스크톱 시계입니다. 우측 하단에 Clean & Science 로고가 표시됩니다.

## 빌드·설치
```bash
./build.sh            # build/FlipIt.app 생성
./build.sh --install  # /Applications/FlipIt.app 에 설치
```
Xcode 없이 Command Line Tools(swiftc)만으로 빌드됩니다.

## 사용
- 보기 > 전체 화면 (⌃⌘F, 또는 시계 더블클릭)
- 보기 > 바탕화면 모드 (⌘D): 모든 화면의 바탕화면에 시계를 깔고 아이콘·창 뒤에 둡니다
- 24시간 표시 (⌘2), 초 표시 (⌘S), 로고 표시 (⌘L), 시계 크게/작게 (⌘+ / ⌘-)
