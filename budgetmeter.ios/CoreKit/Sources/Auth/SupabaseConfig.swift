//
//  SupabaseConfig.swift
//  BudgetMeter
//
//  Supabase project credentials for auth and cloud backup/sync.
//

import Foundation

/// Supabase project configuration.
enum SupabaseConfig {
    static let projectID = "mqbtbtlbpcjzleghvrkv"
    static let projectURL = URL(string: "https://\(projectID).supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xYnRidGxicGNqemxlZ2h2cmt2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MzA2NjIsImV4cCI6MjA5NzIwNjY2Mn0.zxytaytXZ71fP8kVo5FETAh-F3V2k_ZNYNYsZFFJjqg"

    static var isConfigured: Bool {
        !projectID.isEmpty && !anonKey.isEmpty
    }

    static func edgeFunctionURL(named functionName: String) -> URL {
        projectURL
            .appendingPathComponent("functions")
            .appendingPathComponent("v1")
            .appendingPathComponent(functionName)
    }
}
