import Foundation

do {
    try runChromeProfileStoreChecks()
    runProfileLabelsChecks()
    runActiveProfileStoreChecks()
} catch {
    Harness.check(false, "checks threw: \(error)")
}
Harness.finish()
