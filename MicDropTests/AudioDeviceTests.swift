import Foundation
import Testing
@testable import MicDrop

@Suite struct AudioDeviceTests {
    @Test(arguments: [DeviceTarget.defaultDevice, .allDevices, .specific(uid: "BuiltInMicrophoneDevice")])
    func deviceTargetRoundTripsThroughJSON(_ target: DeviceTarget) throws {
        let data = try JSONEncoder().encode(target)
        #expect(try JSONDecoder().decode(DeviceTarget.self, from: data) == target)
    }
}
