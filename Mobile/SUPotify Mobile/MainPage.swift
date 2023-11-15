//
//  MainPage.swift
//  SUPotify Mobile
//
//  Created by Alkım Özyüzer on 28.10.2023.
//

import SwiftUI

struct MainMenu: View {
    @StateObject var likedSongsViewModel = LikedSongsViewModel()
    
    var body: some View {
        TabView {
            // Tab 1
            Text("Home page")
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            // Tab 2
            Text("Search")
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Tab 2")
                }
            
            NavigationView{
                ForYouView()
            }
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("For You")
                }
            
            if likedSongsViewModel.likedSongsCount > 0 {
                NavigationView {
                    LikedSongsView()
                }
                
                .tabItem {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("Liked Songs")
                }
            }
            else{
                NavigationView{
                    ImportView()
                }
                .tabItem {
                    Image(systemName: "arrow.down.doc.fill")
                    Text("Import")
                }
            }
            
            // Profile Tab
                NavigationView {
                    Profile()
                }
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profile")
                }
        }
        .font(.title)
        .navigationBarBackButtonHidden(true)

    }
}

struct MainMenu_Previews: PreviewProvider {
    static var previews: some View {
        MainMenu()
            .preferredColorScheme(.dark)
    }
}

