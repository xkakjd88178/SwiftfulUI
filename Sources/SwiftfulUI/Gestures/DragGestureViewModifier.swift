//
//  DragGestureViewModifier.swift
//  
//
//  Created by Nick Sarno on 4/10/22.
//

import SwiftUI

struct DragGestureViewModifier: ViewModifier {
    
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1

    let axes: Axis.Set
    let minimumDistance: CGFloat
    let resets: Bool
    let animation: Animation
    let rotationMultiplier: CGFloat
    let scaleMultiplier: CGFloat
    let onChanged: ((_ dragOffset: CGSize) -> ())?
    let onEnded: ((_ dragOffset: CGSize) -> ())?

    init(
        _ axes: Axis.Set = [.horizontal, .vertical],
        minimumDistance: CGFloat = 0,
        resets: Bool,
        animation: Animation,
        rotationMultiplier: CGFloat = 0,
        scaleMultiplier: CGFloat = 0,
        onChanged: ((_ dragOffset: CGSize) -> ())?,
        onEnded: ((_ dragOffset: CGSize) -> ())?) {
            self.axes = axes
            self.minimumDistance = minimumDistance
            self.resets = resets
            self.animation = animation
            self.rotationMultiplier = rotationMultiplier
            self.scaleMultiplier = scaleMultiplier
            self.onChanged = onChanged
            self.onEnded = onEnded
        }
        
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .rotationEffect(Angle(degrees: rotation), anchor: .center)
            .offset(getOffset(offset: lastOffset))
            .offset(getOffset(offset: offset))
            .simultaneousGesture(
                DragGesture(minimumDistance: minimumDistance, coordinateSpace: .global)
                    .onChanged({ value in
                        onChanged?(value.translation)
                        
                        withAnimation(animation) {
                            offset = value.translation
                            
                            rotation = getRotation(translation: value.translation)
                            scale = getScale(translation: value.translation)
                        }
                    })
                    .onEnded({ value in
                        if !resets {
                            onEnded?(lastOffset)
                        } else {
                            onEnded?(value.translation)
                        }

                        withAnimation(animation) {
                            offset = .zero
                            rotation = 0
                            scale = 1
                            
                            if !resets {
                                lastOffset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height)
                            } else {
                                onChanged?(offset)
                            }
                        }
                    })
            )
    }
    
    
    private func getOffset(offset: CGSize) -> CGSize {
        switch axes {
        case .vertical:
            return CGSize(width: 0, height: offset.height)
        case .horizontal:
            return CGSize(width: offset.width, height: 0)
        default:
            return offset
        }
    }
    
    private func getRotation(translation: CGSize) -> CGFloat {
        #if os(iOS)
        let max = UIScreen.main.bounds.width / 2
        #elseif os(macOS)
        let max = NSScreen.main?.frame.width ?? 0 / 2
        #endif
        let percentage = translation.width * rotationMultiplier / max
        let maxRotation: CGFloat = 10
        return percentage * maxRotation
    }
    
    private func getScale(translation: CGSize) -> CGFloat {
        #if os(iOS)
        let max = UIScreen.main.bounds.width / 2
        #elseif os(macOS)
        let max = NSScreen.main?.frame.width ?? 0 / 2
        #endif
        
        var offsetAmount: CGFloat = 0
        switch axes {
        case .vertical:
            offsetAmount = abs(translation.height + lastOffset.height)
        case .horizontal:
            offsetAmount = abs(translation.width + lastOffset.width)
        default:
            offsetAmount = (abs(translation.width + lastOffset.width) + abs(translation.height + lastOffset.height)) / 2
        }
        
        let percentage = offsetAmount * scaleMultiplier / max
        let minScale: CGFloat = 0.8
        let range = 1 - minScale
        return 1 - (range * percentage)
    }
    
}

public extension View {
    
    /// Add a DragGesture to a View.
    ///
    /// DragGesture is added as a simultaneousGesture, to not interfere with other gestures Developer may add.
    ///
    /// - Parameters:
    ///   - axes: Determines the drag axes. Default allows for both horizontal and vertical movement.
    ///   - resets: If the View should reset to starting state onEnded.
    ///   - animation: The drag animation.
    ///   - rotationMultiplier: Used to rotate the View while dragging. Only applies to horizontal movement.
    ///   - scaleMultiplier: Used to scale the View while dragging.
    ///   - onEnded: The modifier will handle the View's offset onEnded. This escaping closure is for Developer convenience.
    ///
    func withDragGesture(
        _ axes: Axis.Set = [.horizontal, .vertical],
        minimumDistance: CGFloat = 0,
        resets: Bool = true,
        animation: Animation = .spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.0),
        rotationMultiplier: CGFloat = 0,
        scaleMultiplier: CGFloat = 0,
        onChanged: ((_ dragOffset: CGSize) -> ())? = nil,
        onEnded: ((_ dragOffset: CGSize) -> ())? = nil) -> some View {
            modifier(DragGestureViewModifier(axes, minimumDistance: minimumDistance, resets: resets, animation: animation, rotationMultiplier: rotationMultiplier, scaleMultiplier: scaleMultiplier, onChanged: onChanged, onEnded: onEnded))
    }
    
}

struct DragGestureViewModifier_Previews: PreviewProvider {
    
    static var previews: some View {
        RoundedRectangle(cornerRadius: 10)
            .frame(width: 300, height: 200)
            .withDragGesture(
                [.vertical, .horizontal],
                resets: true,
                animation: .smooth,
                rotationMultiplier: 1.1,
                scaleMultiplier: 1.1,
                onChanged: { dragOffset in
                    let tx = dragOffset.height
                    let ty = dragOffset.width
                },
                onEnded: { dragOffset in
                    let tx = dragOffset.height
                    let ty = dragOffset.width
                }
            )
    }
}
