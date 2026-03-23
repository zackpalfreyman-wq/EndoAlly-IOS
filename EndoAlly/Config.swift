import Foundation

enum Config {
    static let supabaseURL    = "https://rntneltlfpfybixtbslq.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJudG5lbHRsZnBmeWJpeHRic2xxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0OTQ2MDQsImV4cCI6MjA4OTA3MDYwNH0.tA31uTBG2I0OeeolI-zxA5c0jFJSk05aq0S2un2m7uU"

    // Add your Anthropic API key here. Store this in a .xcconfig or environment variable in production.
    static let anthropicAPIKey = "YOUR_ANTHROPIC_API_KEY_HERE"
    static let anthropicModel  = "claude-sonnet-4-20250514"
}
