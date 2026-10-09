import 'package:diyet_programi/core/utils/debouncer.dart';
import 'package:diyet_programi/features/food/data/datasources/food_api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('yalnızca son çağrıyı çalıştırır', () async {
    var count = 0;
    String? last;
    final debounce = Debouncer(duration: const Duration(milliseconds: 40));
    debounce.run(() {
      count++;
      last = 'a';
    });
    debounce.run(() {
      count++;
      last = 'ab';
    });
    debounce.run(() {
      count++;
      last = 'abc';
    });
    expect(count, 0);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(count, 1);
    expect(last, 'abc');
    debounce.dispose();
  });

  test('arama debounce yapılandırması 400 ms kalır (mevcut arama testi)', () {
    expect(FoodApiConfig.searchDebounce, const Duration(milliseconds: 400));
  });
}
