import 'package:diyet_programi/features/barcode/presentation/barcode_scan_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aynı barkod art arda kabul edilmez', () {
    final session = BarcodeScanSession();
    expect(session.tryAccept('2000000000015'), isTrue);
    expect(session.tryAccept('2000000000015'), isFalse);
    expect(session.tryAccept('2000000000022'), isFalse);
    expect(session.isBusy, isTrue);
  });

  test('release sonrası farklı barkod kabul edilir', () {
    final session = BarcodeScanSession();
    expect(session.tryAccept('111'), isTrue);
    session.release();
    expect(session.tryAccept('111'), isFalse);
    session.release(clearCode: true);
    expect(session.tryAccept('111'), isTrue);
  });

  test('boş ve harfli değerler yok sayılır', () {
    final session = BarcodeScanSession();
    expect(session.tryAccept(''), isFalse);
    expect(session.tryAccept('abc'), isFalse);
    expect(session.tryAccept(' 123 '), isTrue);
    expect(session.acceptedCode, '123');
  });

  test('leading zero korunur', () {
    final session = BarcodeScanSession();
    expect(session.tryAccept('0123456789012'), isTrue);
    expect(session.acceptedCode, '0123456789012');
    expect(session.acceptedCode, isNot('123456789012'));
  });
}
