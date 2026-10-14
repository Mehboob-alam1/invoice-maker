import 'package:flutter_test/flutter_test.dart';
import 'package:ai_invoice_maker_receipt_app/services/referral_link.dart';

void main() {
  test('reads the invite code from a Play install referrer', () {
    const referrer = 'utm_source=referral&utm_medium=invite&utm_content=AB23CD';
    expect(ReferralLink.codeFromInstallReferrer(referrer), 'AB23CD');
    expect(ReferralLink.codeFromInstallReferrer('utm_content=OOO111'), isNull);
  });

  test('share link keeps the referrer value encoded', () {
    final url = ReferralLink.shareUrl('AB23CD');
    expect(url, contains('com.invoice.maker.estimate.billing.ocr.appomatrix'));
    expect(url, contains('referrer='));
    expect(url, contains('utm_content%3DAB23CD'));
  });
}
