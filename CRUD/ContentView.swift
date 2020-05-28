//
//  ContentView.swift
//  CRUD
//
//docRef.setData(dataToUpdate, merge: true){(error) in
//if let error = error {
//    print("error = \(error)")
//}else{
//    print("data upload successfully")
//    if showDetails{
//        print("dataUploaded = \(dataToUpdate)")
//    }
//    completion(true)
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



struct FirebaseView: View {
    @State private var rating_id = ""
    @State private var restaurantName = ""
    @State private var restaurantRating = ""
    @State var reviewedRestaurants:[Restaurant] = []
    @State private var showSheet = false
    
    var body: some View {
        VStack{
            TextField("add a new name", text: $restaurantName).padding()
            TextField("add a new rating", text: $restaurantRating)
                .keyboardType(.numberPad)
                .padding()
            ScrollView{
                if reviewedRestaurants.count>0{
                    ForEach(reviewedRestaurants, id: \.id){ thisRestaurant in
                        Button(action:{
                            self.rating_id = thisRestaurant.id.uuidString
                            self.restaurantName = thisRestaurant.name
                            self.restaurantRating = thisRestaurant.rating
                            self.showSheet = true
                        }){
                            HStack{
                                Text("\(thisRestaurant.name) || \(thisRestaurant.rating)")
                                    .frame(maxWidth:UIScreen.main.bounds.size.width)
                                    .foregroundColor(.white)
                            }.background(Color.blue)
                        }.sheet(isPresented: self.$showSheet){
                            VStack{
                                Text("Modify rating - \(self.rating_id)")
                                TextField("add a new name", text: self.$restaurantName).padding()
                                TextField("add a new rating", text: self.$restaurantRating)
                                    .keyboardType(.numberPad)
                                    .padding()
                                Button(action: {
                                    let ratingDictionary = [
                                        "name":self.restaurantName,
                                        "rating":self.restaurantRating
                                    ]
                                    let docRef = Firestore.firestore().document("ratings/\(self.rating_id)")
                                    print("setting data")
                                    docRef.setData(ratingDictionary,merge: true){(error) in
                                        if let error = error{
                                            print("error = \(error)")
                                        }else{
                                            print("data update successfully")
                                            self.showSheet = false
                                            self.restaurantName = ""
                                            self.restaurantRating = ""
                                        }
                                    }
                                    
                                }){
                                    Text("Update Rating")
                                }
                            }
                        }
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
                DispatchQueue.main.async {
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
                            .append(Restaurant(id:UUID(uuidString: documents[i].documentID) ?? UUID(),name: names[i] as? String ?? "Failed to get name", rating: ratings[i] as? String ?? "Failed to get rating"))
                    }
            }
        }
    }
}

struct DrawPoints:Identifiable{
    let id = UUID()
    var x:[CGFloat] = []
    var y:[CGFloat] = []
    var lineColor:Color = .black
    var lineThickness:CGFloat = 1.0
    var lineOpacity:Double = 0.5
}




struct DrawingView:View{
    let drawnPointsArray:[DrawPoints]
    let drawingPoints:DrawPoints
    
    init(drawnPointsArray:[DrawPoints],drawingPoints:DrawPoints){
        self.drawnPointsArray = drawnPointsArray
        self.drawingPoints = drawingPoints
    }
    
    func drawLine(drawPoints:DrawPoints)->some View{
        var points:[CGPoint] = []
        for i in 0..<drawPoints.x.count{
            let point = CGPoint(x: drawPoints.x[i], y: drawPoints.y[i])
            points.append(point)
        }
        return Path{path in
            path.addLines(points)
        }.stroke(drawingPoints.lineColor,lineWidth: drawingPoints.lineThickness)
    }
    
    var body: some View{
        ZStack{
            ForEach(drawnPointsArray){
                self.drawLine(drawPoints: $0)
            }
            self.drawLine(drawPoints: self.drawingPoints)
        }
    }
}

struct BaseView:View{
    @State private var drawnPointsArray:[DrawPoints] = []
    @State private var drawingPoints:DrawPoints = DrawPoints()
    @State private var isShown:Bool = false
    
    var body: some View{
        let dragGeststure = DragGesture()
            .onChanged({value in
                self.drawingPoints.x.append(value.location.x)
                self.drawingPoints.y.append(value.location.y)
            })
            .onEnded({value in
                self.drawnPointsArray.append(self.drawingPoints)
                self.drawingPoints = DrawPoints()
            })
        
        return
            ZStack{
                DrawingView(drawnPointsArray: drawnPointsArray, drawingPoints: drawingPoints)
                    .frame(width:UIScreen.main.bounds.size.width,height: UIScreen.main.bounds.height)
                    .background(Color.blue)
                    .gesture(dragGeststure)
                VStack{
                    Spacer()
                    HStack{
                        Spacer()
                        Trash(drawnPointsArray: self.$drawnPointsArray, drawingPoints: self.$drawingPoints)
                        Spacer()
                        ArrowUp(drawnPointsArray: self.$drawnPointsArray, drawingPoints: self.$drawingPoints)
                        Spacer()
                        ArrowDown(isShown: self.$isShown)
                        Spacer()
                    }.offset(x: 0.0, y: -30.0)
                        .font(.largeTitle).foregroundColor(.black)
                    
                }
            }.edgesIgnoringSafeArea(.all)
                .sheet(isPresented: self.$isShown, content: {ListView()})
    }
}
struct Record:Identifiable{
    var id = UUID()
    var createdAt:Date
    var drawPointsArray:[DrawPoints]
    
    init(document:QueryDocumentSnapshot){
        let timeStamp = document["timeStamp"] as! Timestamp
        self.createdAt = timeStamp.dateValue()
        self.drawPointsArray = []
        let totalLines = document["totalLines"] as! Int
        for i in 0..<totalLines{
            let line = document[String(i)] as! [String:Any]
            let x = line["x"] as! [CGFloat]
            let y = line["y"] as! [CGFloat]
            let lineThickness = line["lineThickness"] as! CGFloat
            let colorString = line["lineColor"] as! String
            let lineColor = self.getLineColor(colorString: colorString)
            let lineOpacity = line["lineOpacity"] as! Double
            let drawPoints:DrawPoints = DrawPoints(x: x, y: y, lineColor: lineColor, lineThickness: lineThickness, lineOpacity: lineOpacity)
            self.drawPointsArray.append(drawPoints)
        }
    }
    func getLineColor(colorString:String)->Color{
        switch colorString{
        case "black":
            return Color.black
        default:
            return Color.black
        }
    }
}
class GetRecords{
    
    func setRecords()->[Record]{
        
        var records:[Record] = []
        Firestore.firestore().collection("points").getDocuments(completion: { (querySnapShot, error) in
            guard let documents = querySnapShot?.documents else{
                return
            }
            for document in documents{
                let record = Record(document: document)
                records.append(record)
                print(record.createdAt)
            }
            
            
        })
        return records
    }
    
}

struct ListView:View{
    @State private var records:[Record] = []
    var completed:Bool = false
    init(){
        self.completed = true
        setRecords()
    }
    
    func setRecords(){
        
        var records:[Record] = []
        Firestore.firestore().collection("points").getDocuments(completion: { (querySnapShot, error) in
            guard let documents = querySnapShot?.documents else{
                return
            }
            for document in documents{
                let record = Record(document: document)
                records.append(record)
                print(record.createdAt)
            }
            
            //self.records = records
            //print(records)
            
        })
        self.records = records
        print(self.records)
    }
  
    var body: some View{
        //Text("\(self.completed ? "OK":"not yet")")
        List(self.records){record in
            Text("\(self.records.count)")
        }
    }
}


struct ArrowDown:View{
    @Binding var isShown:Bool
    var body: some View{
        Button(action: {self.isShown.toggle()}, label: {Image(systemName: "icloud.and.arrow.down")})
    }
}


struct ArrowUp:View{
    @Binding var drawnPointsArray:[DrawPoints]
    @Binding var drawingPoints:DrawPoints
    var body: some View{
        Button(action: {
            //show all array
            var allDic:[String:Any] = ["timeStamp":FieldValue.serverTimestamp()]
            
            var lineNum = 0
            for line in self.drawnPointsArray{
                var myDic:[String:Any] = [:]
                myDic["lineColor"] = line.lineColor.description
                myDic["lineThickness"] = line.lineThickness
                myDic["lineOpacity"] = line.lineOpacity
                
                myDic["x"] = line.x.map{$0}
                myDic["y"] = line.y.map{$0}
                
                allDic[String(lineNum)] = myDic
                lineNum += 1
                
            }
            allDic["totalLines"] = lineNum
            //
            let docRef = Firestore.firestore().collection("points").document(UUID().uuidString)
            print("setting data")
            docRef.setData(allDic,merge: true){(error) in
                if let error = error{
                    print("error = \(error)")
                }else{
                    print("data update successfully\(lineNum)")
                }
            }
            self.drawnPointsArray.removeAll()
        }, label: {Image(systemName: "icloud.and.arrow.up")})
    }
}

struct Trash:View{
    @Binding var drawnPointsArray:[DrawPoints]
    @Binding var drawingPoints:DrawPoints
    var body: some View{
        Button(action: {self.drawnPointsArray.removeAll()}, label: {Image(systemName: "trash")})
    }
}




struct ContentView: View {
    var body: some View{
        //FirebaseView()
        //Text("Text")
        BaseView()
    }
    
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
