//
//  CustomListView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-02-05.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

/// CustomList is a list view that does not consume all the space at the end of the view.
struct CustomList: View {
	private let views: [AnyView]
	@Environment(\.colorScheme) var colorScheme

	init<Views>(@ViewBuilder content: @escaping () -> TupleView<Views>) {
		views = content().getViews
	}
	
	var body: some View {
		HStack {
			VStack {
				ForEach(views.indices, id: \.self) { index in
					views[index]
					if index < views.count - 1 {
						Divider()
					}
				}
			}
			.padding([.leading, .top, .bottom])
			.background(Color.listItemBackground(colorScheme))
			.cornerRadius(10)
		}
		.padding()
		.background(Color.listBackground(colorScheme))
	}
}
