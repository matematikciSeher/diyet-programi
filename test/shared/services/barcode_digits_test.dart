import 'package:diyet_programi/shared/services/barcode/barcode_digits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('leading zero string olarak korunur, integer parse edilmez', () {
    expect(BarcodeDigits.normalize('0123456789012'), '0123456789012');
    expect(int.parse('0123456789012').toString(), isNot('0123456789012'));
    expect(BarcodeDigits.normalize('0123456789012'), isNot('123456789012'));
  });

  test('EAN-13, EAN-8 ve UPC rakam dizisi korunur', () {
    expect(BarcodeDigits.normalize('3017620422003'), '3017620422003');
    expect(BarcodeDigits.normalize('12345670'), '12345670');
    expect(BarcodeDigits.normalize('012345678905'), '012345678905');
  });

  test('boşluk ve ayırıcılar atılır, rakam kaybı olmaz', () {
    expect(BarcodeDigits.normalize(' 0123456789012 '), '0123456789012');
    expect(BarcodeDigits.normalize('869-0504-000016'), '8690504000016');
  });

  test('QR/URL ve kısa değer kabul edilmez; EAN-13 kabul edilir', () {
    expect(BarcodeDigits.accept('https://penguen.com.tr/tarif/123'), isNull);
    expect(BarcodeDigits.accept('08002931131'), isNull);
    expect(BarcodeDigits.accept('8691422701433'), '8691422701433');
    expect(BarcodeDigits.accept(' 8691422701433 '), '8691422701433');
  });
}
