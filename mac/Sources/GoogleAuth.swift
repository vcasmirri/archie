import AuthenticationServices
import Cocoa
import CryptoKit

struct GoogleToken {
    let accessToken: String
    let expiresIn: Int
    let scope: String
}

enum AuthFailure: LocalizedError {
    case notSignedIn, noCode, server(String)
    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "Not signed in to Google yet."
        case .noCode: return "Google sign-in didn't finish."
        case .server(let body): return "Google sign-in failed: \(body)"
        }
    }
}

/// Google sign-in through Apple's secure sign-in sheet (Google blocks sign-in inside embedded web pages).
/// Uses the OAuth "code + PKCE" flow for an iOS-type client ID, and keeps the refresh token in the Keychain
/// so the widget reconnects on its own after the first sign-in.
final class GoogleAuth: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let scopes = "https://www.googleapis.com/auth/tasks https://www.googleapis.com/auth/drive.appdata"
    private let clientID: String
    private weak var anchor: NSWindow?
    private var session: ASWebAuthenticationSession?
    private let keychain = Keychain(service: "Archie", account: "google-refresh-token")

    init?(clientID: String?, anchor: NSWindow) {
        guard let clientID, clientID.hasSuffix(".apps.googleusercontent.com") else { return nil }
        self.clientID = clientID
        self.anchor = anchor
    }

    private var redirectScheme: String {
        "com.googleusercontent.apps." + clientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
    }
    private var redirectURI: String { redirectScheme + ":/oauth2redirect" }

    /// Gets a fresh access token: silently from the saved refresh token if possible, otherwise (if allowed) by asking the user.
    func token(interactive: Bool, completion: @escaping (Result<GoogleToken, Error>) -> Void) {
        guard let refresh = keychain.read() else {
            interactive ? signIn(completion) : completion(.failure(AuthFailure.notSignedIn))
            return
        }
        exchange(["refresh_token": refresh, "grant_type": "refresh_token"]) { [weak self] result in
            guard case .failure(let error) = result else { completion(result); return }
            if let failure = error as? AuthFailure, case .server = failure { self?.keychain.delete() } // revoked or expired
            if interactive, let self { self.signIn(completion) } else { completion(result) }
        }
    }

    func signOut() { keychain.delete() }

    private func signIn(_ completion: @escaping (Result<GoogleToken, Error>) -> Void) {
        let verifier = Self.makeVerifier()
        var url = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        url.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Self.scopes),
            URLQueryItem(name: "code_challenge", value: Self.challenge(for: verifier)),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]
        let session = ASWebAuthenticationSession(url: url.url!, callbackURLScheme: redirectScheme) { [weak self] callback, error in
            guard let self else { return }
            if let error { completion(.failure(error)); return }
            let code = callback.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "code" }?.value }
            guard let code else { completion(.failure(AuthFailure.noCode)); return }
            self.exchange(["code": code, "code_verifier": verifier, "grant_type": "authorization_code", "redirect_uri": self.redirectURI], completion)
        }
        session.presentationContextProvider = self
        self.session = session
        session.start()
    }

    private func exchange(_ params: [String: String], _ completion: @escaping (Result<GoogleToken, Error>) -> Void) {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var form = params
        form["client_id"] = clientID
        request.httpBody = form.map { "\($0.key)=\(Self.formEncode($0.value))" }.joined(separator: "&").data(using: .utf8)
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                if let error { completion(.failure(error)); return }
                let json = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
                guard let json, let access = json["access_token"] as? String else {
                    completion(.failure(AuthFailure.server(data.flatMap { String(data: $0, encoding: .utf8) } ?? "no response")))
                    return
                }
                if let refresh = json["refresh_token"] as? String { self?.keychain.save(refresh) }
                completion(.success(GoogleToken(accessToken: access, expiresIn: json["expires_in"] as? Int ?? 3600, scope: json["scope"] as? String ?? "")))
            }
        }.resume()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        anchor ?? NSApp.keyWindow ?? ASPresentationAnchor()
    }

    private static func makeVerifier() -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return String((0..<64).map { _ in chars.randomElement()! })
    }

    private static func challenge(for verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }

    private static func formEncode(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}
