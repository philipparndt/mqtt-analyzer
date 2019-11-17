//
//  AttributedUILabelRepresentation.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI


class LabelUIView : UIView {
    private var label = UILabel()
    var height : CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        self.addSubview(label)
        label.numberOfLines = 0
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setString(_ attributedString:NSAttributedString) {
        self.label.attributedText = attributedString
        self.label.numberOfLines = 0
        self.label.sizeToFit()
        self.height = self.label.frame.height
    }
    
    func scale() {
        self.label.layoutSubviews()
        self.label.sizeToFit()
        self.height = self.label.frame.height
    }
}

struct AttributedUILabel : UIViewRepresentable {
    let attributedString:NSAttributedString
    
    @Binding var height: CGFloat
    
    func makeUIView(context: UIViewRepresentableContext<AttributedUILabel>) -> LabelUIView {
        let label = LabelUIView(frame: .zero)
        return label
    }
    
    func updateUIView(_ uiView: LabelUIView, context: UIViewRepresentableContext<AttributedUILabel>) {
        uiView.setString(attributedString)
        context.coordinator.heightChanged(uiView)
    }
    
    func makeCoordinator() -> AttributedUILabel.Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var label: AttributedUILabel
        
        init(_ label: AttributedUILabel) {
            self.label = label
        }
        
        @objc func heightChanged(_ sender: LabelUIView) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10 )) {
                 self.label.height = sender.height
            }
        }
    }
}
