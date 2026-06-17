//
//  Cache.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import Foundation

/// A type-safe wrapper around NSCache
/// Key must be Hashable (to convert to NSString)
/// Value can be any class type
final class Cache<Key: Hashable, Value> {

    // NSCache requires keys/values to be classes (NSObject subclasses)
    // We wrap our Swift types in a Box class
    private final class WrappedKey: NSObject {
        let key: Key

        init(_ key: Key) { self.key = key }

        // NSCache uses hash and isEqual for key lookup
        override var hash: Int { key.hashValue }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? WrappedKey else { return false }
            return key == other.key
        }
    }

    private final class WrappedValue {
        let value: Value
        init(_ value: Value) { self.value = value }
    }

    private let cache = NSCache<WrappedKey, WrappedValue>()

    /// Maximum number of items to hold in cache
    /// NSCache uses this as a hint, not a hard limit
    var countLimit: Int {
        get { cache.countLimit }
        set { cache.countLimit = newValue }
    }

    init(countLimit: Int = 100) {
        self.countLimit = countLimit
    }

    /// Store a value for a key
    func set(_ value: Value, for key: Key) {
        let wrappedKey = WrappedKey(key)
        let wrappedValue = WrappedValue(value)
        cache.setObject(wrappedValue, forKey: wrappedKey)
    }

    /// Retrieve a value for a key, or nil if not cached / evicted
    func get(for key: Key) -> Value? {
        let wrappedKey = WrappedKey(key)
        return cache.object(forKey: wrappedKey)?.value
    }

    /// Remove a specific key
    func remove(for key: Key) {
        let wrappedKey = WrappedKey(key)
        cache.removeObject(forKey: wrappedKey)
    }

    /// Clear everything
    func removeAll() {
        cache.removeAllObjects()
    }
}
