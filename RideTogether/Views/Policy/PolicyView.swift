//
//  PolicyView.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI

enum PolicyType {
    case privacy
    case eula
    
    var url: String {
        switch self {
        case .privacy: return "https://www.privacypolicies.com/live/38b065d0-5b0e-4b1d-a8e0-f51274f8d269"

        case .eula: return "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
        }
    }
}

struct PolicyView: View {
    let policy: PolicyType
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(policy == .privacy ? "隱私權政策" : "應用程式終端使用者授權協議")
                    .padding()
            }
            .navigationTitle(policy == .privacy ? "隱私權政策" : "應用程式終端使用者授權協議")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
    }
}

