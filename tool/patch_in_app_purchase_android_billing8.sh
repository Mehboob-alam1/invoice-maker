#!/usr/bin/env bash
# Re-apply after `flutter pub get` if Play Billing 8 + in_app_purchase_android 0.4.x fails to compile.
set -euo pipefail
FILE="${PUB_CACHE:-$HOME/.pub-cache}/hosted/pub.dev/in_app_purchase_android-0.4.0+10/android/src/main/java/io/flutter/plugins/inapppurchase/MethodCallHandlerImpl.java"
if [[ ! -f "$FILE" ]]; then
  echo "Plugin file not found: $FILE"
  echo "Upgrade to in_app_purchase_android 0.5.0+ (Flutter 3.38+) when possible."
  exit 1
fi
export FILE
python3 <<'PY'
from pathlib import Path
import os

file = Path(os.environ["FILE"])
text = file.read_text()
changed = False

old_import = "import com.android.billingclient.api.QueryProductDetailsParams;\n"
new_import = (
    old_import + "import com.android.billingclient.api.QueryProductDetailsResult;\n"
)
if "QueryProductDetailsResult" not in text:
    if old_import not in text:
        raise SystemExit("Unexpected plugin source; use in_app_purchase_android 0.5.0+")
    text = text.replace(old_import, new_import, 1)
    changed = True

old_cb = """      billingClient.queryProductDetailsAsync(
          params,
          (billingResult, productDetailsList) -> {
            updateCachedProducts(productDetailsList);
            final PlatformProductDetailsResponse.Builder responseBuilder =
                new PlatformProductDetailsResponse.Builder()
                    .setBillingResult(fromBillingResult(billingResult))
                    .setProductDetails(fromProductDetailsList(productDetailsList));
            result.success(responseBuilder.build());
          });"""
new_cb = """      billingClient.queryProductDetailsAsync(
          params,
          (billingResult, productDetailsResult) -> {
            final List<ProductDetails> productDetailsList =
                productDetailsResult != null
                    ? productDetailsResult.getProductDetailsList()
                    : null;
            updateCachedProducts(productDetailsList);
            final PlatformProductDetailsResponse.Builder responseBuilder =
                new PlatformProductDetailsResponse.Builder()
                    .setBillingResult(fromBillingResult(billingResult))
                    .setProductDetails(fromProductDetailsList(productDetailsList));
            result.success(responseBuilder.build());
          });"""
if old_cb in text:
    text = text.replace(old_cb, new_cb, 1)
    changed = True

old_history = """    try {
      billingClient.queryPurchaseHistoryAsync(
          QueryPurchaseHistoryParams.newBuilder()
              .setProductType(toProductTypeString(productType))
              .build(),
          (billingResult, purchasesList) -> {
            PlatformPurchaseHistoryResponse.Builder builder =
                new PlatformPurchaseHistoryResponse.Builder()
                    .setBillingResult(fromBillingResult(billingResult))
                    .setPurchases(fromPurchaseHistoryRecordList(purchasesList));
            result.success(builder.build());
          });
    } catch (RuntimeException e) {
      result.error(new FlutterError("error", e.getMessage(), Log.getStackTraceString(e)));
    }"""
new_history = """    // queryPurchaseHistoryAsync was removed in Play Billing Library 8.
    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(BillingClient.BillingResponseCode.FEATURE_NOT_SUPPORTED)
            .setDebugMessage(
                "queryPurchaseHistoryAsync is not available on Play Billing Library 8.")
            .build();
    PlatformPurchaseHistoryResponse.Builder builder =
        new PlatformPurchaseHistoryResponse.Builder()
            .setBillingResult(fromBillingResult(billingResult))
            .setPurchases(fromPurchaseHistoryRecordList(null));
    result.success(builder.build());"""
if old_history in text:
    text = text.replace(old_history, new_history, 1)
    changed = True

if not changed:
    if "queryPurchaseHistoryAsync was removed in Play Billing Library 8" in text:
        print("Already patched:", file)
    else:
        raise SystemExit("Nothing to patch; plugin version may have changed.")
else:
    file.write_text(text)
    print("Patched", file)
PY
