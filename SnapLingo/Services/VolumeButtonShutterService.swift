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
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        let vv = MPVolumeView(frame: .zero)
        vv.isHidden = true
        containerView.addSubview(vv)
        volumeView = vv
        slider = vv.subviews.compactMap { $0 as? UISlider }.first

        setVolume(0.5)
        lastVolume = session.outputVolume

        observation = session.observe(\.outputVolume, options: [.new]) { [weak self] session, change in
            guard let self = self else { return }
            let newValue = change.newValue ?? session.outputVolume
            if self.suppressReset {
                self.lastVolume = newValue
                return
            }
            if abs(newValue - self.lastVolume) > 0.01 {
                self.onTrigger?()
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
