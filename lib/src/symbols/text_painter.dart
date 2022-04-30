import 'package:flutter/painting.dart';

import 'symbols.dart';

abstract class TextPainterProvider {
  const TextPainterProvider();
  TextPainter? provide(StyledSymbol symbol);
}

class DefaultTextPainterProvider extends TextPainterProvider {
  const DefaultTextPainterProvider();

  @override
  TextPainter? provide(StyledSymbol symbol) {
    return TextPainter(
        text: TextSpan(style: symbol.style.textStyle, text: symbol.text),
        textAlign: symbol.style.textAlign,
        textDirection: TextDirection.ltr)
      ..layout();
  }
}

class CreatedTextPainterProvider extends TextPainterProvider {
  DefaultTextPainterProvider _delegate = DefaultTextPainterProvider();

  final _painterBySymbol = <StyledSymbol, TextPainter?>{};
  final _symbolsWithoutPainter = <StyledSymbol>{};

  @override
  TextPainter? provide(StyledSymbol symbol) =>
      _painterBySymbol.putIfAbsent(symbol, () {
        _symbolsWithoutPainter.add(symbol);
        return null;
      });

  Iterable<StyledSymbol> symbolsWithoutPainter() => _symbolsWithoutPainter;

  Iterable<StyledSymbol> allSymbols() => _painterBySymbol.keys;

  void create(StyledSymbol symbol) {
    _painterBySymbol[symbol] = _delegate.provide(symbol);
    _symbolsWithoutPainter.remove(symbol);
  }

  void evict(StyledSymbol symbol) {
    _symbolsWithoutPainter.remove(symbol);
    _painterBySymbol.remove(symbol);
  }
}
