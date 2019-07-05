//
//  Multimap.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-04.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

class Multimap<K: Hashable, V> {
    var _dict = Dictionary<K, [V]>()
    
    func put(key: K, value: V) {
        if var existingValues = self._dict[key] {
            existingValues.append(value)
            self._dict[key] = existingValues
        } else {
            self._dict[key] = [value]
        }
    }
}
