import '../themes/expression/expression.dart';
import '../themes/style.dart';

class TextWrapper {
  final TextLayout layout;

  TextWrapper(this.layout);

  List<String> wrap(EvaluationContext context, String text) {
    double? textSize = layout.textSize.evaluate(context);
    if (textSize == null) {
      return [text];
    }
    final maxWidth = (layout.maxWidth?.evaluate(context) ?? 10.0).ceil();
    return wrapText(text, textSize, maxWidth);
  }
}

List<String> wrapText(String text, double textSize, int maxWidth) {
  double maxWidthInPoints = _oneEm * maxWidth;
  double textLength = text.length * textSize;
  if (textLength > maxWidthInPoints) {
    final words = text.split(RegExp(r'\s'));
    int maxCharactersPerLine = (maxWidthInPoints / textSize).truncate();
    int optimalLineCount = (text.length / maxCharactersPerLine).ceil();
    int optimalWordsPerLine = (words.length / optimalLineCount).floor();
    final lines = <String>[];
    List<String>? currentLine;
    for (int wordIndex = 0; wordIndex < words.length; ++wordIndex) {
      if (currentLine == null) {
        currentLine = [words[wordIndex]];
      } else {
        currentLine.add(words[wordIndex]);
      }
      if (currentLine.length >= optimalWordsPerLine) {
        if (optimalWordsPerLine > 1 &&
            lines.length == (optimalLineCount - 1) &&
            wordIndex == words.length - 2) {
          final currentLinelengthPlusTrailingSpace = currentLine
                  .map((e) => e.length * textSize)
                  .reduce((a, b) => (a + b)) +
              (currentLine.length * textSize);
          final lastWordLength = words.last.length * textSize;
          if (currentLinelengthPlusTrailingSpace + lastWordLength <
              maxWidthInPoints) {
            currentLine.add(words.last);
            ++wordIndex;
          }
        }
        lines.add(currentLine.join(' '));
        currentLine = null;
      }
    }
    if (currentLine != null) {
      lines.add(currentLine.join(' '));
    }
    return lines;
  }
  return [text];
}

const _oneEm = 24.0;
