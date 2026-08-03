import Foundation

extension String {
    public func localized(language: String) -> String {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to English if the specific language bundle is not found
            if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
               let enBundle = Bundle(path: enPath) {
                return NSLocalizedString(self, bundle: enBundle, comment: "")
            }
            return self
        }
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
}
