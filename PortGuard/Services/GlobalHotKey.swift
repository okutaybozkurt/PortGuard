import Carbon.HIToolbox
import Foundation

/// Carbon RegisterEventHotKey sarmalayıcısı (ek izin gerektirmez).
public final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let handler: () -> Void
    private let keyCode: UInt32
    private let modifiers: UInt32

    public init(keyCode: UInt32 = UInt32(kVK_ANSI_P), modifiers: UInt32 = UInt32(optionKey | cmdKey), handler: @escaping () -> Void) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.handler = handler
    }

    deinit { unregister() }

    @discardableResult
    public func register() -> Bool {
        guard hotKeyRef == nil else { return true }

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData = userData else { return noErr }
                let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { hotKey.handler() }
                return noErr
            },
            1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handlerRef
        )
        guard status == noErr else { return false }

        let id = EventHotKeyID(signature: OSType(0x5047_4B31), id: 1) // 'PGK1'
        let reg = RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
        if reg != noErr {
            if let h = handlerRef { RemoveEventHandler(h); handlerRef = nil }
            hotKeyRef = nil
            return false
        }
        return true
    }

    public func unregister() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }
        if let h = handlerRef { RemoveEventHandler(h); handlerRef = nil }
    }
}
