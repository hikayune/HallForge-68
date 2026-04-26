#ifndef RUNNER_HID_BRIDGE_H_
#define RUNNER_HID_BRIDGE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

struct HidDeviceInfo {
  std::string path;
  uint16_t vendor_id = 0;
  uint16_t product_id = 0;
  uint16_t usage_page = 0;
  uint16_t usage = 0;
  uint16_t input_report_byte_length = 0;
  uint16_t output_report_byte_length = 0;
  uint16_t feature_report_byte_length = 0;
  std::string product_name;
  std::string manufacturer_name;
  std::string serial_number;
};

class HidBridge {
 public:
  explicit HidBridge(flutter::BinaryMessenger* messenger);
  ~HidBridge();

  HidBridge(const HidBridge&) = delete;
  HidBridge& operator=(const HidBridge&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::mutex state_mutex_;
  std::mutex io_mutex_;
  HANDLE device_handle_ = INVALID_HANDLE_VALUE;
  std::optional<HidDeviceInfo> connected_device_;
};

#endif  // RUNNER_HID_BRIDGE_H_
