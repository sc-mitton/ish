import Foundation
import Supabase

class SupabaseService: ObservableObject {
    public let client: SupabaseClient

    init() {
        guard let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let supabaseKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY")
                as? String
        else {
            fatalError("Supabase configuration not found in Info.plist")
        }
        let updatedSupabaseURL = supabaseURL.replacingOccurrences(of: "#", with: "/")

        self.client = SupabaseClient(
            supabaseURL: URL(string: updatedSupabaseURL)!,
            supabaseKey: supabaseKey
        )
    }

    func hasSession() async throws -> Bool {
        let session = try? await client.auth.session
        return session != nil
    }

    func signInWithPhoneNumber(_ phoneNumber: String) async throws {
        try await client.auth.signInWithOTP(
            phone: phoneNumber
        )
    }

    func verifyOTP(phoneNumber: String, token: String) async throws {
        try await client.auth.verifyOTP(
            phone: phoneNumber,
            token: token,
            type: .sms
        )
    }

    func updateUsername(_ username: String) async throws {
        let session = try await client.auth.session
        let userId = session.user.id
        try await client.from("auth.users")
            .update(["username": username])
            .eq("id", value: userId)
            .execute()
    }

    func getFriends() async throws -> [Friend] {
        let session = try await client.auth.session
        let userId = session.user.id

        // Fetch friends where the current user is either user_id or friend_id
        let response =
            try await client
            .from("auth.friends")
            .select("id, friend:friend_id(username)")
            .eq("user_id", value: userId)
            .execute()

        // Parse the response and create Friend objects
        let friendsData = try JSONDecoder().decode([FriendResponse].self, from: response.data)
        return friendsData.map { response in
            Friend(
                id: response.id,
                username: response.friend.username
            )
        }
    }
}
