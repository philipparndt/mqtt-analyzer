//
//  ClientImplFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct ClientImplFormView: View {
	@Binding var host: HostFormModel

	var body: some View {
		return Section(header: Text("Client Implementation")) {
			ClientImplTypePicker(type: $host.clientImpl)
		}
	}
}
