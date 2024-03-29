import SwiftUI

struct FriendsView: View {
    @State private var newFriendUsername = ""
    @State private var friends = [String]()
    let username: String
    @State private var refreshID = UUID()
    @State private var isRotated = false
    @State private var listKey = UUID()
    @State var notExist: Bool = false
    let myUsername = SessionManager.shared.username
    @State var giveAlert: Bool = false

    
    var body: some View {
        
        ScrollView{
            
                HStack {
                    TextField("Enter username", text: $newFriendUsername)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .font(.caption)
                        .autocapitalization(.none)
                    
                    Button(action: {
                        if(newFriendUsername == myUsername){
                            giveAlert = true
                        }
                        self.addFriend(friendUsername: self.newFriendUsername)
                       
                    }) {
                        Text("Add")
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.indigo.opacity(0.50))
                            .cornerRadius(8)
                            .font(.subheadline)
                            .alert(isPresented: $notExist) {
                                Alert(
                                    title: Text("Cannot add friend"),
                                    message: Text("This user does not exist!"),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                            .alert(isPresented: $giveAlert) {
                                Alert(
                                    title: Text("Cannot add friend"),
                                    message: Text("You cannot add yourself as friend"),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                    }
                    .padding()
                }
                

                        ForEach(friends, id: \.self) { friend in
                                HStack{
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 45, height: 45)
                                        .foregroundColor(.indigo.opacity(0.70))
                                        .padding()
                                    Text(friend)
                                        .font(.subheadline)
                                    Spacer()
                                    Button(action: {
                                        removeFollower(friendUsername: friend)
                                    }) {
                                        Image(systemName: "person.badge.minus.fill")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.white.opacity(0.50))
                                    }
                                }
                            }
        }
        .id(refreshID)
        .onAppear(perform: fetchFollowedUsers)
    }
    
    func addFriend(friendUsername: String) {
        
        let token = SessionManager.shared.token
        let trimmedUsername = friendUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedUsername.isEmpty {
            let url = URL(string: "http://localhost:4000/api/followedUsers/addToUserFollowedUsers")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue( "Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = ["followedUsername": trimmedUsername]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        
                        print(error.localizedDescription)
                        return
                    }
                    guard let data = data else {
                        return
                    }
                    do {
                        let response = try JSONDecoder().decode(FollowedUsersResponse.self, from: data)
                        if response.success {
                            self.friends.append(trimmedUsername)
                            print(response)
                        } else if (response.message == "This user does not exist!"){
                            print("This user does not exist")
                            notExist = true
                        }
                    } catch {
                        print("Decoding error!")
                    }
                    fetchFollowedUsers()
                }
            }.resume()
        }
        newFriendUsername = ""
    }
    
    
    func removeFollower(friendUsername: String) {
        let token = SessionManager.shared.token
        let url = URL(string: "http://localhost:4000/api/followedUsers/removeFromUserFollowedUsers")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let trimmedUsername = friendUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        print(trimmedUsername)
        
        let body: [String: Any] = ["followedUsername": trimmedUsername]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response String: \(responseString)")
                }
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                guard let data = data else {
                    print("No data received")
                    return
                }
               do {
                    let response = try JSONDecoder().decode(RemoveUserResponse.self, from: data)
                    if response.message == "User is removed from followed users successfully" {
                        self.friends = response.updatedFollowedUsers.followedUsersList
                    } else {
                        print("Failed to remove friend: \(response.message)")
                    }
                } catch {
                    print("Decoding error: \(error)")
                }
                fetchFollowedUsers()
            }
        }.resume()
    }
    
    func fetchFollowedUsers() {
            let token = SessionManager.shared.token
            let url = URL(string: "http://localhost:4000/api/followedUsers/getAllFollowedUsersForUser")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Fetch error: \(error.localizedDescription)")
                        return
                    }
                    guard let data = data else {
                        print("No data received")
                        return
                    }
                    do {
                        let response = try JSONDecoder().decode(FollowedUsersListResponse.self, from: data)
                        if response.success {
                            self.friends = response.followedUsers
                            self.refreshID = UUID()
                            
                        } else {
                            print("Fetch failed: \(response.message)")
                        }
                    } catch {
                        print("Decoding error: \(error)")
                    }
                    self.listKey = UUID()
                }
                
            }.resume()
        
}

    
    struct FollowedUsersResponse: Codable {
        let message: String
        let success: Bool
    }


    struct FollowedUsersListResponse: Codable {
        let message: String
        let success: Bool
        let followedUsers: [String]
    }
    
    struct RemoveUserResponse: Codable{
        let message: String
        let updatedFollowedUsers: UpdatedFollowedUsers
    }
    

    struct UpdatedFollowedUsers: Codable {
        let id: String
        let username: String
        let followedUsersList: [String]
        let __v: Int
    }
    
    struct FriendsView_Previews: PreviewProvider {
        static var previews: some View {
            FriendsView(username: "testUser")
                .preferredColorScheme(.dark)
        }
    }
}
