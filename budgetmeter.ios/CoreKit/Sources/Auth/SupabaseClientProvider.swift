//
//  SupabaseClientProvider.swift
//  BudgetMeter
//

import Foundation
import Supabase

enum SupabaseClientProvider {

    static func makeClient() -> SupabaseClient? {
        guard SupabaseConfig.isConfigured else { return nil }

        return SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
}
