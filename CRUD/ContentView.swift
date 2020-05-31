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


// MARK: - Drawing


struct DrawPoints:Identifiable{
    let id = UUID()
    var x:[CGFloat] = []
    var y:[CGFloat] = []
    var lineColor:Color = .black
    var lineThickness:CGFloat = 5.0
    var lineOpacity:Double = 1.0
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
            var x = line["x"] as! [CGFloat]
            x = x.map{$0 * UIScreen.main.bounds.width}
            var y = line["y"] as! [CGFloat]
            y = y.map{$0 * UIScreen.main.bounds.height}
            let lineThickness = line["lineThickness"] as! CGFloat
            let colorString = line["lineColor"] as! String
            let lineColor = self.getLineColor(colorString: colorString)
            let lineOpacity = line["lineOpacity"] as! Double
            let drawPoints:DrawPoints = DrawPoints(x: x, y: y, lineColor: lineColor, lineThickness: lineThickness, lineOpacity: lineOpacity)
            self.drawPointsArray.append(drawPoints)
        }
    }
    func getLineColor(colorString:String)->Color{
        let colors:[Color] = [.black,.blue,.gray,.green,.orange,.pink,.purple,.red,.yellow,.white]
        var colorDic:[String:Color] = [:]
        for color in colors{
            colorDic[color.description] = color
        }
        return colorDic[colorString]!
    }
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
        }.stroke(drawPoints.lineColor,lineWidth: drawPoints.lineThickness)
            .opacity(drawPoints.lineOpacity)
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
    @State private var records:[Record] = []
    
    @State private var colorIndex:Int = 0
    let colors:[Color] = [.black,.blue,.gray,.green,.orange,.pink,.purple,.red,.yellow,.white]
    
    @State private var lineThickness:Float = 5.0
    @State private var lineOpacity:Float = 1.0
    var body: some View{
        let dragGeststure = DragGesture()
            .onChanged({value in
                self.drawingPoints.x.append(value.location.x)
                self.drawingPoints.y.append(value.location.y)
            })
            .onEnded({value in
                self.drawnPointsArray.append(self.drawingPoints)
                self.drawingPoints = DrawPoints(lineColor: self.colors[self.colorIndex], lineThickness: CGFloat(self.lineThickness), lineOpacity: Double(self.lineOpacity))//
            })
        
        return
            ZStack{
                DrawingView(drawnPointsArray: drawnPointsArray, drawingPoints: drawingPoints)
                    .frame(width:UIScreen.main.bounds.size.width,height: UIScreen.main.bounds.height)
                    .background(Color.white)
                    .gesture(dragGeststure)
                VStack{
                    Spacer()
                    VStack{
                        HStack{
                            Spacer()
                            ArrowUp(drawnPointsArray: self.$drawnPointsArray, drawingPoints: self.$drawingPoints)
                            Spacer()
                            ArrowDown(isShown: self.$isShown)
                            Spacer()
                            Trash(drawnPointsArray: self.$drawnPointsArray, drawingPoints: self.$drawingPoints)
                            Spacer()
                        }
                        HStack{
                            Spacer()
                            Button(action: {
                                self.colorIndex = (self.colorIndex + 1) % self.colors.count
                                self.drawingPoints.lineColor = self.colors[self.colorIndex]
                                
                            }, label: {
                                VStack{
                                Image(systemName: "square.fill").font(.largeTitle).foregroundColor(self.colors[self.colorIndex])
                                Text("\(self.colors[self.colorIndex].description)").font(.caption)
                                }
                            })
                            Spacer()
                            VStack{
                            Slider(value: self.$lineThickness, in: Float(1)...Float(50)){value in
                                self.drawingPoints.lineThickness = CGFloat(self.lineThickness)
                            }.frame(width: 100.0, alignment: .center)
                                Text("LineWidth:\(String(format: "%.0f", self.drawingPoints.lineThickness))").font(.caption)
                            }
                            Spacer()
                            VStack{
                                Slider(value: self.$lineOpacity, in: Float(0.1)...Float(1.0)){value in
                                    self.drawingPoints.lineOpacity = Double(self.lineOpacity)
                            }.frame(width: 100.0, alignment: .center)
                                Text("LineOpacity:\(String(format: "%.1f", self.drawingPoints.lineOpacity))").font(.caption)
                            }
                            Spacer()
                        }
                    }.offset(x: 0.0, y: -50.0)
                        .foregroundColor(.black)
                    
                }
            }.onAppear(){
                
                
                Firestore.firestore().collection("points").addSnapshotListener ({ (querySnapShot, error) in
                    guard let documents = querySnapShot?.documents else{
                        return
                    }
                    print("onAppear")
                    self.records.removeAll()
                    for document in documents{
                        let record = Record(document: document)
                        self.records.append(record)
                    }
                    self.records.sort(by: {(a,b) -> Bool in return a.createdAt > b.createdAt})
                })
                
            }
            .edgesIgnoringSafeArea(.all)
            .sheet(isPresented: self.$isShown, content: {
                List{
                    ForEach(0..<self.records.count){i in
                        Button(action: {
                            print("\(i)")
                            self.isShown = false
                            self.drawnPointsArray = self.records[i].drawPointsArray
                        }, label: {
                            Text("\(self.records[i].createdAt)")
                                .font(.caption)
                        })
                    }
                }
            })
    }
}

struct ArrowDown:View{
    @Binding var isShown:Bool
    var body: some View{
        Button(action: {self.isShown.toggle()}, label: {
            VStack{
                Image(systemName: "icloud.and.arrow.down").font(.largeTitle)
                Text("LOAD").font(.caption)
            }
        })
    }
}


struct ArrowUp:View{
    @Binding var drawnPointsArray:[DrawPoints]
    @Binding var drawingPoints:DrawPoints
    var body: some View{
        Button(action: {
            if self.drawnPointsArray.count>0{
                var allDic:[String:Any] = ["timeStamp":Date()]
                
                var lineNum = 0
                for line in self.drawnPointsArray{
                    var myDic:[String:Any] = [:]
                    myDic["lineColor"] = line.lineColor.description
                    myDic["lineThickness"] = line.lineThickness
                    myDic["lineOpacity"] = line.lineOpacity
                    
                    myDic["x"] = line.x.map{$0/UIScreen.main.bounds.width}
                    myDic["y"] = line.y.map{$0/UIScreen.main.bounds.height}
                    
                    allDic[String(lineNum)] = myDic
                    lineNum += 1
                    
                }
                allDic["totalLines"] = lineNum
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
            }
        }, label: {
            
            VStack{
                if self.drawnPointsArray.count>0{
                    Image(systemName: "icloud.and.arrow.up").font(.largeTitle)
                }else{
                    Image(systemName: "icloud.slash").font(.largeTitle)
                }
                Text("SAVE").font(.caption)
            }
        })
        
    }
}

struct Trash:View{
    @Binding var drawnPointsArray:[DrawPoints]
    @Binding var drawingPoints:DrawPoints
    var body: some View{
        Button(action: {self.drawnPointsArray.removeAll()}, label: {VStack{
            Image(systemName: "trash").font(.largeTitle)
            Text("DELETE").font(.caption)
            
            }
        })
    }
}




struct ContentView: View {
    var body: some View{
        BaseView()
    }
    
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
