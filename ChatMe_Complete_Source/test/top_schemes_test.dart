import 'package:flutter_test/flutter_test.dart';
import 'package:chatme/data/top_schemes_data.dart';

void main() {
  test('top schemes expose a valid fallback list', () {
    final html = TopSchemesRepository.formatTop5SchemesHtml('en');

    expect(html, contains('scheme-btn'));
    expect(TopSchemesRepository.top5Schemes, isNotEmpty);
  });

  test('top scheme lookup is stable', () {
    final scheme = TopSchemesRepository.top5Schemes.first;
    expect(
      TopSchemesRepository.findById(scheme.id),
      isNotNull,
    );
  });
}
