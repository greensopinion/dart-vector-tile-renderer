import '../image_expression.dart';

import '../expression.dart';
import 'expression_parser.dart';

class ImageExpressionParser extends ExpressionComponentParser {
  ImageExpressionParser(ExpressionParser parser) : super(parser, 'image');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 2;
  }

  @override
  Expression? parse(List<dynamic> json) {
    final delegate = parser.parseOptional(json[1]);
    if (delegate == null) {
      return null;
    }
    return ImageExpression(delegate);
  }
}
