import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';

class TableSelectionPage {
  const TableSelectionPage(this.$);
  final PatrolIntegrationTester $;

  PatrolFinder get _tableList    => $('tableListView');
  PatrolFinder get _filterButton => $('tableFilterButton');

  Future<void> assertTableListVisible() async {
    await _tableList.waitUntilVisible(timeout: Timeouts.medium);
    expect(_tableList, findsOneWidget);
  }

  Future<void> selectTableByChipValue(String chipValue) async {
    final row = $(find.text(chipValue));
    await row.waitUntilVisible(timeout: Timeouts.medium);
    await row.tap();
  }

  Future<void> applyFilter({required String filterKey}) async {
    await _filterButton.tap();
    await $(filterKey).waitUntilVisible(timeout: Timeouts.short);
    await $(filterKey).tap();
  }
}
