//
//  MapWidgetEntryView.swift
//  RideTogether
//
//  Created by 00591630 on 2022/11/3.
//

import SwiftUI

struct NearbyBikesView: View {
    @State var bike: Bike

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image(systemName: "flag.fill")
                    .renderingMode(.template)
                    .foregroundColor(Color(#colorLiteral(red: 0.7211458683, green: 0.8630903363, blue: 0, alpha: 1)))
                    .padding(.leading, 10.0)
                    .frame(width: 18.0)
                Text(bike.sna)
                    .font(.caption)
                    .foregroundColor(Color.gray)
                    .lineLimit(3)
                    .padding(.leading, 10.0)
            }
//            Spacer()
            HStack {
                Image(systemName: "bicycle")
                    .renderingMode(.template)
                    .foregroundColor(Color(#colorLiteral(red: 0, green: 0.6627757549, blue: 0.2614499331, alpha: 1)))
                    .padding(.leading, 10.0)
                    .frame(width: 18.0)
                Text("可還數量:\(bike.bemp)")
                    .font(.caption)
                    .fontWeight(/*@START_MENU_TOKEN@*/ .semibold/*@END_MENU_TOKEN@*/)
                    .padding(.leading, 10)
                Text("可租數量 :\(bike.sbi)")
                    .font(.caption)
                    .fontWeight(/*@START_MENU_TOKEN@*/ .semibold/*@END_MENU_TOKEN@*/)
                    .padding(.leading, 5)
            }
        }
    }
}
