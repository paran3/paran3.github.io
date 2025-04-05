import 'dart:math';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Consumer<MyAppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'Namer App',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                  seedColor: appState.seedColor), // appState에서 seedColor 가져오기
            ),
            home: MyHomePage(),
          );
        },
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var favorites = <WordPair>[];
  var pairs = <WordPair>[];
  var logs = <Log>[];
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.blueAccent; // 현재 seedColor 저장

  ThemeMode get themeMode => _themeMode;

  Color get seedColor => _seedColor; // seedColor getter 추가
  GlobalKey? historyListKey;

  void toggleFavorite(WordPair pair) {
    if (favorites.contains(pair)) {
      print('removed');
      favorites.remove(pair);
      logs.add(Log(favorite: pair.asLowerCase, added: false));
    } else {
      print('added');
      favorites.add(pair);
      logs.add(Log(favorite: pair.asLowerCase, added: true));
    }
    notifyListeners();
  }

  void appendPairs(WordPair pair) {
    pairs.add(pair);
    notifyListeners();
  }

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // seedColor 변경 메서드
  void changeSeedColor(Color newColor) {
    _seedColor = newColor;
    notifyListeners();
  }

  bool hasPair(WordPair pair) {
    return favorites.contains(pair);
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      case 2:
        page = HistoryPage();
        break;
      case 3:
        page = SizedBox.shrink(); // 빈 위젯 할당
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 750, // ← Here.
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.history),
                    label: Text('History'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.color_lens_outlined), // 메뉴 아이콘
                    label: Text('Random Theme'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  if (value == 3) {
                    // Random Theme 메뉴의 인덱스가 3이라고 가정
                    // 페이지 전환 없이 테마 변경
                    Provider.of<MyAppState>(context, listen: false)
                        .changeSeedColor(
                      Colors
                          .primaries[Random().nextInt(Colors.primaries.length)],
                    );
                  } else {
                    setState(() {
                      selectedIndex = value;
                    });
                  }
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class FavoritesPage extends StatelessWidget {
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var favorites = appState.favorites;

    final theme = Theme.of(context); // ← Add this.
    final style = theme.textTheme.displayMedium!.copyWith(
      color: Colors.black,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(30),
          child: Text(
            'You have ${appState.favorites.length} favorites:',
            style:
                Theme.of(context).textTheme.titleLarge, // 테마의 titleLarge 스타일 사용
          ),
        ),
        Expanded(
          child: Center(
            child: GridView(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 400 / 100,
              ),
              children: [
                for (WordPair favorite in favorites)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(favorite.asLowerCase),
                      SizedBox(width: 20),
                      Like(favorite: favorite),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HistoryPage extends StatelessWidget {
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var logs = appState.logs;

    final theme = Theme.of(context); // ← Add this.
    final style = theme.textTheme.headlineSmall!.copyWith(
      color: Colors.black,
    );

    return Center(
      child: Center(
        child: ListView(
          scrollDirection: Axis.vertical,
          children: [
            for (Log log in logs)
              Row(
                children: [
                  SizedBox(height: 10),
                  Text(
                    log.printLog(),
                    style: style,
                  )
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;
    var favorites = appState.favorites;
    var pairs = appState.pairs;
    final theme = Theme.of(context); // ← Add this.

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                // 이 콜백은 ShaderMask가 그려질 때 호출되며,
                // bounds는 ShaderMask의 자식(여기서는 ListView)의 크기와 위치 정보입니다.
                return LinearGradient(
                  // 선형 그라데이션을 생성합니다.
                  begin: Alignment.topCenter, // 그라데이션 시작점 (위쪽 중앙)
                  end: Alignment.bottomCenter, // 그라데이션 끝점 (아래쪽 중앙)
                  colors: <Color>[
                    // 그라데이션 색상 목록 (알파값 조절로 투명도 제어)
                    Colors.transparent, // 시작 부분: 완전 투명
                    Colors.black, // 중간 부분: 완전 불투명 (색상은 중요하지 않고 알파값이 1.0임)
                  ],
                  // 각 색상이 적용될 위치 (0.0 ~ 1.0 사이 값)
                  // 이 값을 조절하여 페이드 영역의 크기를 변경할 수 있습니다.
                  stops: [0.0, 0.5],
                ).createShader(bounds); // bounds 정보를 사용하여 실제 Shader 객체를 생성합니다.
              },
              // 블렌드 모드: dstIn은 대상(ListView) 위에 소스(그라데이션)의 알파값을 적용하여 마스킹합니다.
              blendMode: BlendMode.dstIn,
              child: ListView.builder(
                reverse: true,
                itemCount: pairs.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        // Row 위젯을 사용하여 아이콘과 텍스트를 함께 표시
                        mainAxisSize: MainAxisSize.min, // 필요에 따라 조정
                        children: [
                          if (appState.hasPair(
                              pairs[pairs.length - 1 - index])) // 조건부로 아이콘 표시
                            Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              // 아이콘과 텍스트 사이 간격
                              child: Icon(Icons.favorite,
                                  color: theme.colorScheme.primary),
                            ),
                          Text(pairs[pairs.length - 1 - index].asLowerCase),
                          // 텍스트는 항상 표시
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          ResizableCard(pair: pair, size: CardSize.big),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite(pair);
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                  appState.appendPairs(pair);
                },
                child: Text('Next'),
              ),
            ],
          ),
          Spacer(flex: 2),
        ],
      ),
    );
  }
}

enum CardSize {
  big,
  medium,
  small,
}

class ResizableCard extends StatelessWidget {
  const ResizableCard({
    super.key,
    required this.pair,
    required this.size,
  });

  final WordPair pair;
  final CardSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    TextStyle style;
    double paddingValue;
    Color cardColor;

    switch (size) {
      case CardSize.big:
        style = theme.textTheme.displayLarge!.copyWith(
          color: theme.colorScheme.onPrimary,
        );
        paddingValue = 30;
        cardColor = theme.colorScheme.primary;
        break;
      case CardSize.medium:
        style = theme.textTheme.displayMedium!.copyWith(
          color: theme.colorScheme.onPrimary,
        );
        paddingValue = 20;
        cardColor = theme.colorScheme.primary;
        break;
      case CardSize.small:
        style = theme.textTheme.headlineSmall!.copyWith(
          color: theme.colorScheme.onPrimary,
        );
        paddingValue = 15;
        cardColor = theme.colorScheme.primary; // SmallCard는 다른 색상으로 구분 (선택 사항)
        break;
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: EdgeInsets.all(paddingValue),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}

class Like extends StatelessWidget {
  const Like({
    super.key,
    required this.favorite,
  });

  final WordPair favorite;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    IconData icon;
    if (appState.favorites.contains(favorite)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return ElevatedButton.icon(
      onPressed: () {
        appState.toggleFavorite(favorite);
      },
      icon: Icon(icon),
      label: Text('Like'),
    );
  }
}

class Log {
  String favorite;
  bool added;

  Log({required this.favorite, required this.added});

  String printLog() {
    if (added) {
      return '$favorite is added'; // 문자열 보간법 사용
    } else {
      return '$favorite is removed'; // 문자열 보간법 사용
    }
  }
}
