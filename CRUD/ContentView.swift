//
//  ContentView.swift
//  CRUD
//
//  Created by 佐藤一成 on 2020/05/23.
//  Copyright © 2020 s140. All rights reserved.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct Restaurant:Identifiable{
    var id = UUID()
    var name:String
    var rating:String
}



struct ContentView: View {
    @State private var restaurantName = ""
    @State private var restaurantRating = ""
    @State var reviewedRestaurants:[Restaurant]
    var body: some View {
        VStack{
            TextField("add a new name", text: $restaurantName).padding()
            TextField("add a new rating", text: $restaurantRating)
                .keyboardType(.numberPad)
                .padding()
            
            ScrollView{
                if reviewedRestaurants.count>0{
                    ForEach(reviewedRestaurants, id: \.id){ thisRestaurant in
                        HStack{
                        Text("\(thisRestaurant.name) || \(thisRestaurant.rating)")
                            .frame(maxWidth:UIScreen.main.bounds.size.width)
                        }.background(Color.blue)
                    }
                    
                }else{
                    Text("Submit a review")
                }
            }.frame(width:UIScreen.main.bounds.size.width)
                .background(Color.red)
            Button(action: {
                let ratingDictionary = [
                    "name":self.restaurantName,
                    "rating":self.restaurantRating
                ]
                let docRef = Firestore.firestore().document("ratings/\(UUID().uuidString)")
                print("setting data")
                docRef.setData(ratingDictionary){(error) in
                    if let error = error{
                        print("error = \(error)")
                    }else{
                        print("data upload successfully")
                        self.restaurantName = ""
                        self.restaurantRating = ""
                        
                    }
                }
            }){
                Text("Add Rating")
            }
        }.onAppear(){
            Firestore.firestore().collection("ratings")
            .addSnapshotListener{ querySnapshot, error in
                guard let documents = querySnapshot?.documents else{
                    print("Error fetching documents:\(error!)")
                    return
                }
                let names = documents.map{$0["name"]!}
                let ratings = documents.map{$0["rating"]!}
                print(names)
                print(ratings)
                self.reviewedRestaurants.removeAll()
                for i in 0..<names.count{
                    self.reviewedRestaurants
                        .append(Restaurant(name: names[i] as? String ?? "Failed to get name", rating: ratings[i] as? String ?? "Failed to get rating"))
                }
                
                
            }
            
            
        }
        
       // Text("Hello, World!")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(reviewedRestaurants: [])
    }
}
