import Flutter
import UIKit
import os

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let registrar = self.registrar(forPlugin: "NoriaMemoryProbe") {
      let channel = FlutterMethodChannel(
        name: "app.noria/memory",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "getMemoryInfo":
          result(MemoryProbe.read())
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

enum MemoryProbe {
  static func read() -> [String: Any] {
    let total = Int64(ProcessInfo.processInfo.physicalMemory)
    let available: Int64
    if #available(iOS 13.0, *) {
      available = Int64(os_proc_available_memory())
    } else {
      available = -1
    }

    return [
      "totalBytes": total,
      "availableBytes": available,
      "appBytes": physFootprint(),
      "lowMemory": available >= 0 && available < 200 * 1024 * 1024,
      "chip": machineIdentifier(),
    ]
  }

  private static func physFootprint() -> Int64 {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(
      MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size
    )
    let status = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
      }
    }
    return status == KERN_SUCCESS ? Int64(info.phys_footprint) : -1
  }

  private static func machineIdentifier() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    return withUnsafeBytes(of: &systemInfo.machine) { buffer in
      String(decoding: buffer.prefix(while: { $0 != 0 }), as: UTF8.self)
    }
  }
}
