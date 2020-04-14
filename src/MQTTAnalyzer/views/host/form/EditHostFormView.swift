//
//  NewHostFormView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-25.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct EditHostFormView: View {
	@Binding var host: HostFormModel
	@Binding var auth: HostAuthenticationType
	@Binding var connectionMethod: HostProtocol
	@Binding var clientImpl: HostClientImplType
	@State var advanced = false
	
	var body: some View {
		Form {
			ServerFormView(host: $host, protocolMethod: $connectionMethod, clientImpl: $clientImpl)
			AuthFormView(host: $host, type: $auth)
			TopicFormView(host: $host)
			
			Toggle(isOn: $advanced) {
				Text("More settings")
					.font(.headline)
			}
			
			if self.advanced {
				ClientIDFormView(host: $host)
				LimitsFormView(host: $host)
			}
		}.keyboardResponsive()
	}
}

struct FormFieldInvalidMark: View {
	var invalid: Bool
	
	var body: some View {
		Group {
			if invalid {
				Image(systemName: "xmark.octagon.fill")
				.font(.headline)
					.foregroundColor(.red)
			}
		}
	}
}

#if DEBUG
//struct NewHostFormView_Previews : PreviewProvider {
//	static var previews: some View {
//		NavigationView {
//			NewHostFormView(host: Host())
//		}
//	}
//}
#endif
