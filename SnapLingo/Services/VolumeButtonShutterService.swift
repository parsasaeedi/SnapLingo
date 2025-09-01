import Foundation
import MediaPlayer
import AVFoundation
import UIKit

final class VolumeButtonShutterService {
    private var observation: NSKeyValueObservation?
    private var volumeView: MPVolumeView?
    private weak var slider: UISlider?
    private var lastVolume: Float = AVAudioSession.sharedInstance().outputVolume
    private var suppressReset = false

    var onTrigger: (() -> Void)?

    func start(in containerView: UIView) {
        // Activate audio session so volume changes are observable
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        // Add a hidden MPVolumeView to suppress the system volume HUD and allow programmatic resets
        let vv = MPVolumeView(frame: .zero)
        vv.isHidden = true
        containerView.addSubview(vv)
        volumeView = vv
        slider = vv.subviews.compactMap { $0 as? UISlider }.first

        // Set a baseline volume so up or down both produce changes repeatedly
        setVolume(0.5)
        lastVolume = session.outputVolume

        observation = session.observe(\.outputVolume, options: [.new]) { [weak self] session, change in
            guard let self = self else { return }
            let newValue = change.newValue ?? session.outputVolume
            // Ignore changes triggered by our own reset
            if self.suppressReset {
                self.lastVolume = newValue
                return
            }
            // Trigger on any meaningful change
            if abs(newValue - self.lastVolume) > 0.01 {
                self.onTrigger?()
                // Reset to baseline shortly after to allow repeated presses,
                // and suppress the reset-driven volume change from re-triggering.
                self.suppressReset = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self.setVolume(0.5)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                    self.lastVolume = session.outputVolume
                    self.suppressReset = false
                }
            }
        }
    }

    func stop() {
        observation?.invalidate()
        observation = nil
        volumeView?.removeFromSuperview()
        volumeView = nil
        slider = nil
    }

    private func setVolume(_ value: Float) {
        guard let slider else { return }
        slider.setValue(value, animated: false)
        slider.sendActions(for: .touchUpInside)
    }
}
