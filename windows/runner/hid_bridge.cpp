#include "hid_bridge.h"

#include <flutter/standard_method_codec.h>
#include <hidsdi.h>
#include <hidpi.h>
#include <setupapi.h>
#include <windows.h>

#include <algorithm>
#include <cstdint>
#include <optional>
#include <string>
#include <vector>

#include "utils.h"

namespace {

using EncodableList = flutter::EncodableList;
using EncodableMap = flutter::EncodableMap;
using EncodableValue = flutter::EncodableValue;
using MethodCall = flutter::MethodCall<EncodableValue>;
using MethodResult = flutter::MethodResult<EncodableValue>;

struct HidDeviceFilter {
  std::optional<uint16_t> vendor_id;
  std::optional<uint16_t> product_id;
  std::optional<uint16_t> usage_page;
  std::optional<uint16_t> usage;
};

std::optional<int64_t> GetIntArgument(const EncodableMap& map,
                                      const char* key) {
  auto it = map.find(EncodableValue(std::string(key)));
  if (it == map.end()) {
    return std::nullopt;
  }
  if (const auto* value = std::get_if<int32_t>(&it->second)) {
    return *value;
  }
  if (const auto* value = std::get_if<int64_t>(&it->second)) {
    return *value;
  }
  return std::nullopt;
}

std::optional<std::string> GetStringArgument(const EncodableMap& map,
                                             const char* key) {
  auto it = map.find(EncodableValue(std::string(key)));
  if (it == map.end()) {
    return std::nullopt;
  }
  if (const auto* value = std::get_if<std::string>(&it->second)) {
    return *value;
  }
  return std::nullopt;
}

bool ExtractFilter(const EncodableValue* arguments, HidDeviceFilter* filter) {
  if (arguments == nullptr) {
    return true;
  }

  const auto* map = std::get_if<EncodableMap>(arguments);
  if (map == nullptr) {
    return false;
  }

  if (const auto value = GetIntArgument(*map, "vendorId")) {
    filter->vendor_id = static_cast<uint16_t>(*value);
  }
  if (const auto value = GetIntArgument(*map, "productId")) {
    filter->product_id = static_cast<uint16_t>(*value);
  }
  if (const auto value = GetIntArgument(*map, "usagePage")) {
    filter->usage_page = static_cast<uint16_t>(*value);
  }
  if (const auto value = GetIntArgument(*map, "usage")) {
    filter->usage = static_cast<uint16_t>(*value);
  }

  return true;
}

bool MatchesFilter(const HidDeviceInfo& device, const HidDeviceFilter& filter) {
  if (filter.vendor_id && device.vendor_id != *filter.vendor_id) {
    return false;
  }
  if (filter.product_id && device.product_id != *filter.product_id) {
    return false;
  }
  if (filter.usage_page && device.usage_page != *filter.usage_page) {
    return false;
  }
  if (filter.usage && device.usage != *filter.usage) {
    return false;
  }
  return true;
}

std::string ReadHidString(HANDLE handle,
                          BOOLEAN(WINAPI* reader)(HANDLE, PVOID, ULONG)) {
  wchar_t buffer[256] = {};
  if (!reader(handle, buffer, sizeof(buffer))) {
    return std::string();
  }
  buffer[255] = L'\0';
  return Utf8FromUtf16(buffer);
}

bool QueryDeviceCaps(HANDLE handle, HIDP_CAPS* caps) {
  PHIDP_PREPARSED_DATA preparsed_data = nullptr;
  if (!HidD_GetPreparsedData(handle, &preparsed_data)) {
    return false;
  }

  const NTSTATUS status = HidP_GetCaps(preparsed_data, caps);
  HidD_FreePreparsedData(preparsed_data);
  return status == HIDP_STATUS_SUCCESS;
}

std::optional<HidDeviceInfo> BuildDeviceInfo(const std::wstring& path,
                                             HANDLE handle) {
  HIDD_ATTRIBUTES attributes = {};
  attributes.Size = sizeof(attributes);
  if (!HidD_GetAttributes(handle, &attributes)) {
    return std::nullopt;
  }

  HIDP_CAPS caps = {};
  if (!QueryDeviceCaps(handle, &caps)) {
    return std::nullopt;
  }

  HidDeviceInfo device;
  device.path = Utf8FromUtf16(path.c_str());
  device.vendor_id = attributes.VendorID;
  device.product_id = attributes.ProductID;
  device.usage_page = caps.UsagePage;
  device.usage = caps.Usage;
  device.input_report_byte_length = caps.InputReportByteLength;
  device.output_report_byte_length = caps.OutputReportByteLength;
  device.feature_report_byte_length = caps.FeatureReportByteLength;
  device.product_name = ReadHidString(handle, HidD_GetProductString);
  device.manufacturer_name = ReadHidString(handle, HidD_GetManufacturerString);
  device.serial_number = ReadHidString(handle, HidD_GetSerialNumberString);
  return device;
}

std::vector<HidDeviceInfo> EnumerateDevices(const HidDeviceFilter& filter) {
  GUID hid_guid;
  HidD_GetHidGuid(&hid_guid);

  HDEVINFO device_info_set =
      SetupDiGetClassDevsW(&hid_guid, nullptr, nullptr,
                           DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
  if (device_info_set == INVALID_HANDLE_VALUE) {
    return {};
  }

  std::vector<HidDeviceInfo> devices;
  SP_DEVICE_INTERFACE_DATA interface_data = {};
  interface_data.cbSize = sizeof(interface_data);

  for (DWORD index = 0;
       SetupDiEnumDeviceInterfaces(device_info_set, nullptr, &hid_guid, index,
                                   &interface_data);
       ++index) {
    DWORD required_size = 0;
    SetupDiGetDeviceInterfaceDetailW(device_info_set, &interface_data, nullptr,
                                     0, &required_size, nullptr);
    if (required_size == 0) {
      continue;
    }

    std::vector<uint8_t> detail_buffer(required_size);
    auto* detail_data =
        reinterpret_cast<SP_DEVICE_INTERFACE_DETAIL_DATA_W*>(
            detail_buffer.data());
    detail_data->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_W);

    if (!SetupDiGetDeviceInterfaceDetailW(device_info_set, &interface_data,
                                          detail_data, required_size, nullptr,
                                          nullptr)) {
      continue;
    }

    const std::wstring device_path = detail_data->DevicePath;
    HANDLE handle = CreateFileW(device_path.c_str(), 0,
                                FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                                OPEN_EXISTING, 0, nullptr);
    if (handle == INVALID_HANDLE_VALUE) {
      continue;
    }

    const auto device = BuildDeviceInfo(device_path, handle);
    CloseHandle(handle);
    if (!device || !MatchesFilter(*device, filter)) {
      continue;
    }

    devices.push_back(*device);
  }

  SetupDiDestroyDeviceInfoList(device_info_set);
  return devices;
}

EncodableMap DeviceToMap(const HidDeviceInfo& device) {
  return EncodableMap{
      {EncodableValue("path"), EncodableValue(device.path)},
      {EncodableValue("vendorId"),
       EncodableValue(static_cast<int32_t>(device.vendor_id))},
      {EncodableValue("productId"),
       EncodableValue(static_cast<int32_t>(device.product_id))},
      {EncodableValue("usagePage"),
       EncodableValue(static_cast<int32_t>(device.usage_page))},
      {EncodableValue("usage"),
       EncodableValue(static_cast<int32_t>(device.usage))},
      {EncodableValue("inputReportByteLength"),
       EncodableValue(static_cast<int32_t>(device.input_report_byte_length))},
      {EncodableValue("outputReportByteLength"),
       EncodableValue(static_cast<int32_t>(device.output_report_byte_length))},
      {EncodableValue("featureReportByteLength"),
       EncodableValue(static_cast<int32_t>(device.feature_report_byte_length))},
      {EncodableValue("productName"), EncodableValue(device.product_name)},
      {EncodableValue("manufacturerName"),
       EncodableValue(device.manufacturer_name)},
      {EncodableValue("serialNumber"), EncodableValue(device.serial_number)},
  };
}

std::string LastErrorMessage(const char* action) {
  const DWORD error = GetLastError();
  return std::string(action) + " failed with Windows error " +
         std::to_string(error) + ".";
}

}  // namespace

HidBridge::HidBridge(flutter::BinaryMessenger* messenger) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "hallforge68/win_hid",
      &flutter::StandardMethodCodec::GetInstance());

  channel_->SetMethodCallHandler(
      [this](const MethodCall& call, std::unique_ptr<MethodResult> result) {
        HandleMethodCall(call, std::move(result));
      });
}

HidBridge::~HidBridge() {
  {
    std::lock_guard<std::mutex> io_lock(io_mutex_);
    std::lock_guard<std::mutex> state_lock(state_mutex_);
    if (device_handle_ != INVALID_HANDLE_VALUE) {
      CloseHandle(device_handle_);
      device_handle_ = INVALID_HANDLE_VALUE;
      connected_device_.reset();
    }
  }
}

void HidBridge::HandleMethodCall(const MethodCall& call,
                                 std::unique_ptr<MethodResult> result) {
  const std::string& method = call.method_name();

  if (method == "enumerateDevices") {
    HidDeviceFilter filter;
    if (!ExtractFilter(call.arguments(), &filter)) {
      result->Error("bad_args", "enumerateDevices expects a map or null.");
      return;
    }

    const auto devices = EnumerateDevices(filter);
    EncodableList encoded_devices;
    encoded_devices.reserve(devices.size());
    for (const auto& device : devices) {
      encoded_devices.emplace_back(DeviceToMap(device));
    }
    result->Success(encoded_devices);
    return;
  }

  if (method == "connect") {
    const auto* args = std::get_if<EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("bad_args", "connect expects a map with a path.");
      return;
    }

    const auto path = GetStringArgument(*args, "path");
    if (!path || path->empty()) {
      result->Error("bad_args", "connect requires a non-empty path.");
      return;
    }

    const std::wstring path_wide = Utf16FromUtf8(*path);
    if (path_wide.empty()) {
      result->Error("bad_args", "connect received an invalid UTF-8 path.");
      return;
    }

    HANDLE handle = CreateFileW(
        path_wide.c_str(), GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_EXISTING,
        FILE_FLAG_OVERLAPPED, nullptr);
    if (handle == INVALID_HANDLE_VALUE) {
      result->Error("open_failed", LastErrorMessage("CreateFileW"));
      return;
    }

    const auto device = BuildDeviceInfo(path_wide, handle);
    if (!device) {
      CloseHandle(handle);
      result->Error("query_failed", "Opened HID device but could not query capabilities.");
      return;
    }

    {
      std::lock_guard<std::mutex> io_lock(io_mutex_);
      std::lock_guard<std::mutex> state_lock(state_mutex_);
      if (device_handle_ != INVALID_HANDLE_VALUE) {
        CloseHandle(device_handle_);
      }
      device_handle_ = handle;
      connected_device_ = *device;
    }

    result->Success(DeviceToMap(*device));
    return;
  }

  if (method == "disconnect") {
    std::lock_guard<std::mutex> io_lock(io_mutex_);
    std::lock_guard<std::mutex> state_lock(state_mutex_);
    if (device_handle_ != INVALID_HANDLE_VALUE) {
      CloseHandle(device_handle_);
      device_handle_ = INVALID_HANDLE_VALUE;
      connected_device_.reset();
    }
    result->Success();
    return;
  }

  if (method == "isConnected") {
    std::lock_guard<std::mutex> state_lock(state_mutex_);
    result->Success(device_handle_ != INVALID_HANDLE_VALUE);
    return;
  }

  if (method == "getConnectedDevice") {
    std::lock_guard<std::mutex> state_lock(state_mutex_);
    if (!connected_device_) {
      result->Success();
      return;
    }
    result->Success(DeviceToMap(*connected_device_));
    return;
  }

  if (method == "writeOutputReport") {
    const auto* args = std::get_if<EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("bad_args",
                    "writeOutputReport expects reportId and data.");
      return;
    }

    const auto report_id = GetIntArgument(*args, "reportId");
    auto data_it = args->find(EncodableValue("data"));
    if (!report_id || data_it == args->end()) {
      result->Error("bad_args",
                    "writeOutputReport requires reportId and data.");
      return;
    }

    const auto* data = std::get_if<std::vector<uint8_t>>(&data_it->second);
    if (data == nullptr) {
      result->Error("bad_args", "data must be a Uint8List.");
      return;
    }

    HANDLE handle = INVALID_HANDLE_VALUE;
    uint16_t output_report_length = 0;
    {
      std::lock_guard<std::mutex> state_lock(state_mutex_);
      if (device_handle_ == INVALID_HANDLE_VALUE || !connected_device_) {
        result->Error("not_connected", "No HID device is currently connected.");
        return;
      }
      handle = device_handle_;
      output_report_length = connected_device_->output_report_byte_length;
    }

    const size_t payload_size = std::max<size_t>(
        output_report_length > 0 ? output_report_length : 0, data->size() + 1);
    std::vector<uint8_t> buffer(payload_size, 0);
    buffer[0] = static_cast<uint8_t>(*report_id);
    std::copy(data->begin(), data->end(), buffer.begin() + 1);

    OVERLAPPED overlapped = {};
    overlapped.hEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    if (overlapped.hEvent == nullptr) {
      result->Error("write_failed", LastErrorMessage("CreateEventW"));
      return;
    }

    DWORD bytes_written = 0;
    {
      std::lock_guard<std::mutex> io_lock(io_mutex_);
      if (!WriteFile(handle, buffer.data(), static_cast<DWORD>(buffer.size()),
                     nullptr, &overlapped)) {
        const DWORD error = GetLastError();
        if (error != ERROR_IO_PENDING) {
          CloseHandle(overlapped.hEvent);
          result->Error("write_failed", LastErrorMessage("WriteFile"));
          return;
        }
      }

      const DWORD wait_result = WaitForSingleObject(overlapped.hEvent, 5000);
      if (wait_result != WAIT_OBJECT_0) {
        CancelIoEx(handle, &overlapped);
        CloseHandle(overlapped.hEvent);
        result->Error("write_timeout", "Timed out waiting for HID write.");
        return;
      }

      if (!GetOverlappedResult(handle, &overlapped, &bytes_written, FALSE)) {
        CloseHandle(overlapped.hEvent);
        result->Error("write_failed", LastErrorMessage("GetOverlappedResult"));
        return;
      }
    }

    CloseHandle(overlapped.hEvent);
    result->Success(static_cast<int32_t>(bytes_written));
    return;
  }

  if (method == "readInputReport") {
    const auto* args = std::get_if<EncodableMap>(call.arguments());
    int64_t timeout_ms = 100;
    if (args != nullptr) {
      if (const auto timeout_value = GetIntArgument(*args, "timeoutMs")) {
        timeout_ms = std::max<int64_t>(0, *timeout_value);
      }
    }

    HANDLE handle = INVALID_HANDLE_VALUE;
    uint16_t input_report_length = 0;
    {
      std::lock_guard<std::mutex> state_lock(state_mutex_);
      if (device_handle_ == INVALID_HANDLE_VALUE || !connected_device_) {
        result->Error("not_connected", "No HID device is currently connected.");
        return;
      }
      handle = device_handle_;
      input_report_length = connected_device_->input_report_byte_length;
    }

    const size_t read_size =
        std::max<size_t>(input_report_length > 0 ? input_report_length : 0, 1);
    std::vector<uint8_t> buffer(read_size, 0);

    OVERLAPPED overlapped = {};
    overlapped.hEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    if (overlapped.hEvent == nullptr) {
      result->Error("read_failed", LastErrorMessage("CreateEventW"));
      return;
    }

    DWORD bytes_read = 0;
    {
      std::lock_guard<std::mutex> io_lock(io_mutex_);
      if (!ReadFile(handle, buffer.data(), static_cast<DWORD>(buffer.size()),
                    nullptr, &overlapped)) {
        const DWORD error = GetLastError();
        if (error != ERROR_IO_PENDING) {
          CloseHandle(overlapped.hEvent);
          result->Error("read_failed", LastErrorMessage("ReadFile"));
          return;
        }
      }

      const DWORD wait_result = WaitForSingleObject(
          overlapped.hEvent, static_cast<DWORD>(timeout_ms));
      if (wait_result == WAIT_TIMEOUT) {
        CancelIoEx(handle, &overlapped);
        CloseHandle(overlapped.hEvent);
        result->Success();
        return;
      }
      if (wait_result != WAIT_OBJECT_0) {
        CancelIoEx(handle, &overlapped);
        CloseHandle(overlapped.hEvent);
        result->Error("read_failed", "Unexpected wait result while reading HID input.");
        return;
      }

      if (!GetOverlappedResult(handle, &overlapped, &bytes_read, FALSE)) {
        CloseHandle(overlapped.hEvent);
        result->Error("read_failed", LastErrorMessage("GetOverlappedResult"));
        return;
      }
    }

    CloseHandle(overlapped.hEvent);
    if (bytes_read == 0) {
      result->Success();
      return;
    }

    std::vector<uint8_t> payload;
    if (bytes_read > 1) {
      payload.assign(buffer.begin() + 1, buffer.begin() + bytes_read);
    }

    EncodableMap report;
    report[EncodableValue("reportId")] = EncodableValue(buffer[0]);
    report[EncodableValue("data")] = EncodableValue(payload);
    report[EncodableValue("bytesRead")] =
        EncodableValue(static_cast<int32_t>(bytes_read));
    result->Success(report);
    return;
  }

  result->NotImplemented();
}
