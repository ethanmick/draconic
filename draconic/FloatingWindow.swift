//
//  FloatingWindow.swift
//  draconic
//
//  Created by Ethan Mick on 9/3/25.
//

import SwiftUI
import AppKit

class FloatingWindowController: NSWindowController {
    convenience init() {
        let panel = FloatingPanel()
        self.init(window: panel)
    }
}

class FloatingPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.collectionBehavior = .canJoinAllSpaces
        
        self.center()
        
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        
        let hostingView = NSHostingView(rootView: FloatingWindowContent())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        visualEffect.addSubview(hostingView)
        self.contentView = visualEffect
        
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor)
        ])
        
        self.orderFrontRegardless()
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            self.close()
            return
        }
        super.keyDown(with: event)
    }
}

struct FloatingWindowContent: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Listening...")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text("Press")
                    .foregroundColor(.secondary)
                Text("ESC")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .cornerRadius(4)
                    .font(.caption.monospaced())
                Text("to cancel")
                    .foregroundColor(.secondary)
            }
            .font(.caption)
        }
        .padding(24)
        .background(.clear)
    }
}