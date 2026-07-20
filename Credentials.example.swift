import Foundation

// Copy this file to Credentials.swift and fill in your values.
// Credentials.swift is gitignored — never commit real secrets.
enum Credentials {
    static let clientID     = "YOUR_CLIENT_ID.apps.googleusercontent.com"
    static let clientSecret = "YOUR_CLIENT_SECRET"
    static let redirectURI  = "com.googleusercontent.apps.YOUR_CLIENT_ID:/oauth2callback"

    static let scopes = [
        "https://www.googleapis.com/auth/calendar.events",
        "https://www.googleapis.com/auth/userinfo.email",
    ]

    static let keychainItemName = "com.sulakshana.tempo.google-auth"
}
