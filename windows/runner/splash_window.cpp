#include "splash_window.h"

#include <mfapi.h>
#include <mferror.h>

#include <algorithm>
#include <cstddef>
#include <cstring>

namespace {

constexpr const wchar_t kSplashWindowClassName[] = L"SEEKU_NATIVE_SPLASH";
constexpr UINT_PTR kFrameTimerId = 1;
constexpr UINT_PTR kCloseTimerId = 2;
constexpr UINT kMinimumSplashDurationMs = 1200;
constexpr int kMaxSplashWidth = 640;
constexpr int kMaxSplashHeight = 480;
constexpr DWORD kFirstVideoStream =
    static_cast<DWORD>(MF_SOURCE_READER_FIRST_VIDEO_STREAM);
constexpr DWORD kEndOfStreamFlag =
    static_cast<DWORD>(MF_SOURCE_READERF_ENDOFSTREAM);

bool RegisterSplashWindowClass() {
  WNDCLASS window_class{};
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.lpszClassName = kSplashWindowClassName;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.hbrBackground = nullptr;
  window_class.lpfnWndProc = SplashWindow::WndProc;

  if (RegisterClass(&window_class) != 0) {
    return true;
  }

  return GetLastError() == ERROR_CLASS_ALREADY_EXISTS;
}

RECT GetCenteredWindowRect(int width, int height) {
  POINT origin{0, 0};
  HMONITOR monitor = MonitorFromPoint(origin, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO monitor_info{};
  monitor_info.cbSize = sizeof(monitor_info);
  GetMonitorInfo(monitor, &monitor_info);

  const RECT work_area = monitor_info.rcWork;
  const int left = work_area.left + (work_area.right - work_area.left - width) / 2;
  const int top = work_area.top + (work_area.bottom - work_area.top - height) / 2;
  return RECT{left, top, left + width, top + height};
}

RECT GetLetterboxedRect(const RECT& bounds, UINT32 content_width,
                        UINT32 content_height) {
  const int bounds_width = bounds.right - bounds.left;
  const int bounds_height = bounds.bottom - bounds.top;
  if (bounds_width <= 0 || bounds_height <= 0 || content_width == 0 ||
      content_height == 0) {
    return bounds;
  }

  const double width_scale =
      static_cast<double>(bounds_width) / static_cast<double>(content_width);
  const double height_scale =
      static_cast<double>(bounds_height) / static_cast<double>(content_height);
  const double scale = std::min(width_scale, height_scale);
  const int width = static_cast<int>(content_width * scale);
  const int height = static_cast<int>(content_height * scale);
  const int left = bounds.left + (bounds_width - width) / 2;
  const int top = bounds.top + (bounds_height - height) / 2;

  return RECT{left, top, left + width, top + height};
}

}  // namespace

SplashWindow::SplashWindow() = default;

SplashWindow::~SplashWindow() {
  Close();
}

bool SplashWindow::CreateAndShow(const std::wstring& video_path) {
  Close();

  {
    std::lock_guard<std::mutex> lock(state_mutex_);
    startup_complete_ = false;
    startup_succeeded_ = false;
    window_handle_ = nullptr;
    close_requested_ = false;
    start_tick_ms_ = 0;
  }

  splash_thread_ = std::thread(&SplashWindow::ThreadMain, this, video_path);

  std::unique_lock<std::mutex> lock(state_mutex_);
  startup_condition_.wait(lock, [this]() { return startup_complete_; });
  const bool succeeded = startup_succeeded_;
  lock.unlock();

  if (!succeeded) {
    Close();
  }
  return succeeded;
}

void SplashWindow::Close() {
  HWND window = nullptr;
  {
    std::lock_guard<std::mutex> lock(state_mutex_);
    window = window_handle_;
  }

  if (window != nullptr) {
    PostMessage(window, WM_CLOSE, 0, 0);
  }

  if (splash_thread_.joinable() &&
      splash_thread_.get_id() != std::this_thread::get_id()) {
    splash_thread_.join();
  }
}

void SplashWindow::ThreadMain(std::wstring video_path) {
  const HRESULT com_result = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  const bool com_initialized = SUCCEEDED(com_result);

  const bool created = com_initialized && CreateWindowOnCurrentThread(video_path);
  NotifyStartupComplete(created);

  if (created) {
    MSG message;
    while (GetMessage(&message, nullptr, 0, 0)) {
      TranslateMessage(&message);
      DispatchMessage(&message);
    }
  }

  ReleaseMedia();

  {
    std::lock_guard<std::mutex> lock(state_mutex_);
    window_handle_ = nullptr;
  }

  if (com_initialized) {
    CoUninitialize();
  }
}

bool SplashWindow::CreateWindowOnCurrentThread(const std::wstring& video_path) {
  if (!RegisterSplashWindowClass()) {
    return false;
  }

  if (!InitializeMedia(video_path)) {
    return false;
  }

  if (!ReadNextFrame()) {
    return false;
  }

  int window_width = static_cast<int>(frame_width_);
  int window_height = static_cast<int>(frame_height_);
  const double scale =
      std::min(1.0, std::min(static_cast<double>(kMaxSplashWidth) /
                                 static_cast<double>(window_width),
                             static_cast<double>(kMaxSplashHeight) /
                                 static_cast<double>(window_height)));
  window_width = std::max(1, static_cast<int>(window_width * scale));
  window_height = std::max(1, static_cast<int>(window_height * scale));

  const RECT window_rect = GetCenteredWindowRect(window_width, window_height);
  HWND window = CreateWindowEx(
      WS_EX_TOOLWINDOW | WS_EX_TOPMOST, kSplashWindowClassName, L"SeekU",
      WS_POPUP, window_rect.left, window_rect.top,
      window_rect.right - window_rect.left,
      window_rect.bottom - window_rect.top, nullptr, nullptr,
      GetModuleHandle(nullptr), this);

  if (window == nullptr) {
    return false;
  }

  start_tick_ms_ = GetTickCount64();
  ShowWindow(window, SW_SHOWNORMAL);
  UpdateWindow(window);
  SetTimer(window, kFrameTimerId, timer_interval_ms_, nullptr);
  return true;
}

bool SplashWindow::InitializeMedia(const std::wstring& video_path) {
  HRESULT result = MFStartup(MF_VERSION);
  if (FAILED(result)) {
    return false;
  }
  media_foundation_started_ = true;

  Microsoft::WRL::ComPtr<IMFAttributes> attributes;
  result = MFCreateAttributes(&attributes, 1);
  if (FAILED(result)) {
    return false;
  }

  result =
      attributes->SetUINT32(MF_SOURCE_READER_ENABLE_VIDEO_PROCESSING, TRUE);
  if (FAILED(result)) {
    return false;
  }

  result = MFCreateSourceReaderFromURL(video_path.c_str(), attributes.Get(),
                                       &source_reader_);
  if (FAILED(result)) {
    return false;
  }

  Microsoft::WRL::ComPtr<IMFMediaType> media_type;
  result = MFCreateMediaType(&media_type);
  if (FAILED(result)) {
    return false;
  }

  result = media_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
  if (FAILED(result)) {
    return false;
  }

  result = media_type->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_RGB32);
  if (FAILED(result)) {
    return false;
  }

  result = source_reader_->SetCurrentMediaType(
      kFirstVideoStream, nullptr, media_type.Get());
  if (FAILED(result)) {
    return false;
  }

  Microsoft::WRL::ComPtr<IMFMediaType> current_media_type;
  result = source_reader_->GetCurrentMediaType(
      kFirstVideoStream, &current_media_type);
  if (FAILED(result)) {
    return false;
  }

  result = MFGetAttributeSize(current_media_type.Get(), MF_MT_FRAME_SIZE,
                              &frame_width_, &frame_height_);
  if (FAILED(result) || frame_width_ == 0 || frame_height_ == 0) {
    return false;
  }

  UINT32 numerator = 0;
  UINT32 denominator = 0;
  if (SUCCEEDED(MFGetAttributeRatio(current_media_type.Get(), MF_MT_FRAME_RATE,
                                    &numerator, &denominator)) &&
      numerator > 0 && denominator > 0) {
    timer_interval_ms_ =
        std::max(1U, static_cast<UINT>((1000ULL * denominator) / numerator));
  }

  UINT32 raw_stride = 0;
  if (SUCCEEDED(current_media_type->GetUINT32(MF_MT_DEFAULT_STRIDE,
                                              &raw_stride))) {
    frame_stride_ = static_cast<LONG>(raw_stride);
  } else {
    LONG computed_stride = 0;
    result = MFGetStrideForBitmapInfoHeader(MFVideoFormat_RGB32.Data1,
                                            frame_width_, &computed_stride);
    if (FAILED(result)) {
      return false;
    }
    frame_stride_ = computed_stride;
  }

  frame_pixels_.resize(static_cast<size_t>(frame_width_) * frame_height_ * 4);
  return true;
}

bool SplashWindow::ReadNextFrame() {
  if (!source_reader_) {
    return false;
  }

  for (;;) {
    DWORD stream_flags = 0;
    Microsoft::WRL::ComPtr<IMFSample> sample;
    HRESULT result = source_reader_->ReadSample(
        kFirstVideoStream, 0, nullptr, &stream_flags, nullptr, &sample);
    if (FAILED(result)) {
      return false;
    }

    if ((stream_flags & kEndOfStreamFlag) != 0) {
      return false;
    }

    if (!sample) {
      continue;
    }

    Microsoft::WRL::ComPtr<IMFMediaBuffer> buffer;
    result = sample->ConvertToContiguousBuffer(&buffer);
    if (FAILED(result)) {
      return false;
    }

    BYTE* data = nullptr;
    DWORD max_length = 0;
    DWORD current_length = 0;
    result = buffer->Lock(&data, &max_length, &current_length);
    if (FAILED(result)) {
      return false;
    }
    static_cast<void>(max_length);
    static_cast<void>(current_length);

    const LONG source_stride =
        frame_stride_ == 0 ? static_cast<LONG>(frame_width_ * 4) : frame_stride_;
    const size_t row_bytes = static_cast<size_t>(frame_width_) * 4;
    BYTE* first_row = data;
    if (source_stride < 0) {
      first_row = data + static_cast<size_t>(frame_height_ - 1) *
                             static_cast<size_t>(-source_stride);
    }

    for (UINT32 row = 0; row < frame_height_; ++row) {
      const BYTE* source = source_stride >= 0
                               ? first_row + static_cast<size_t>(row) *
                                                 static_cast<size_t>(source_stride)
                               : first_row - static_cast<size_t>(row) *
                                                 static_cast<size_t>(-source_stride);
      BYTE* target = frame_pixels_.data() + static_cast<size_t>(row) * row_bytes;
      memcpy(target, source, row_bytes);
    }

    buffer->Unlock();
    return true;
  }
}


void SplashWindow::Paint(HDC dc) {
  RECT client_rect{};
  HWND window = nullptr;
  {
    std::lock_guard<std::mutex> lock(state_mutex_);
    window = window_handle_;
  }
  if (window == nullptr) {
    return;
  }

  GetClientRect(window, &client_rect);
  const int client_width = client_rect.right - client_rect.left;
  const int client_height = client_rect.bottom - client_rect.top;
  if (client_width <= 0 || client_height <= 0) {
    return;
  }

  HDC buffer_dc = CreateCompatibleDC(dc);
  HBITMAP buffer_bitmap = CreateCompatibleBitmap(dc, client_width, client_height);
  if (buffer_dc == nullptr || buffer_bitmap == nullptr) {
    if (buffer_bitmap != nullptr) {
      DeleteObject(buffer_bitmap);
    }
    if (buffer_dc != nullptr) {
      DeleteDC(buffer_dc);
    }
    return;
  }

  HGDIOBJ previous_bitmap = SelectObject(buffer_dc, buffer_bitmap);
  HBRUSH background = CreateSolidBrush(RGB(248, 250, 252));
  FillRect(buffer_dc, &client_rect, background);
  DeleteObject(background);

  if (!frame_pixels_.empty() && frame_width_ != 0 && frame_height_ != 0) {
    BITMAPINFO bitmap_info{};
    bitmap_info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bitmap_info.bmiHeader.biWidth = static_cast<LONG>(frame_width_);
    bitmap_info.bmiHeader.biHeight = -static_cast<LONG>(frame_height_);
    bitmap_info.bmiHeader.biPlanes = 1;
    bitmap_info.bmiHeader.biBitCount = 32;
    bitmap_info.bmiHeader.biCompression = BI_RGB;

    const RECT target_rect =
        GetLetterboxedRect(client_rect, frame_width_, frame_height_);

    SetStretchBltMode(buffer_dc, HALFTONE);
    SetBrushOrgEx(buffer_dc, 0, 0, nullptr);
    StretchDIBits(buffer_dc, target_rect.left, target_rect.top,
                  target_rect.right - target_rect.left,
                  target_rect.bottom - target_rect.top, 0, 0, frame_width_,
                  frame_height_, frame_pixels_.data(), &bitmap_info,
                  DIB_RGB_COLORS, SRCCOPY);
  }

  BitBlt(dc, 0, 0, client_width, client_height, buffer_dc, 0, 0, SRCCOPY);
  SelectObject(buffer_dc, previous_bitmap);
  DeleteObject(buffer_bitmap);
  DeleteDC(buffer_dc);
}

void SplashWindow::ReleaseMedia() {
  source_reader_.Reset();
  frame_pixels_.clear();
  if (media_foundation_started_) {
    MFShutdown();
    media_foundation_started_ = false;
  }
}

void SplashWindow::NotifyStartupComplete(bool succeeded) {
  {
    std::lock_guard<std::mutex> lock(state_mutex_);
    startup_succeeded_ = succeeded;
    startup_complete_ = true;
  }
  startup_condition_.notify_all();
}

LRESULT CALLBACK SplashWindow::WndProc(HWND window, UINT message,
                                       WPARAM wparam,
                                       LPARAM lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto create_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    auto splash_window =
        static_cast<SplashWindow*>(create_struct->lpCreateParams);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(splash_window));
    {
      std::lock_guard<std::mutex> lock(splash_window->state_mutex_);
      splash_window->window_handle_ = window;
    }
  }

  auto splash_window = reinterpret_cast<SplashWindow*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
  if (splash_window) {
    return splash_window->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT SplashWindow::MessageHandler(HWND window, UINT message, WPARAM wparam,
                                     LPARAM lparam) noexcept {
  switch (message) {
    case WM_CLOSE: {
      const ULONGLONG elapsed = GetTickCount64() - start_tick_ms_;
      if (elapsed < kMinimumSplashDurationMs) {
        close_requested_ = true;
        SetTimer(window, kCloseTimerId,
                 static_cast<UINT>(kMinimumSplashDurationMs - elapsed),
                 nullptr);
        return 0;
      }
      DestroyWindow(window);
      return 0;
    }

    case WM_TIMER:
      if (wparam == kCloseTimerId && close_requested_) {
        DestroyWindow(window);
        return 0;
      }
      if (wparam == kFrameTimerId) {
        if (ReadNextFrame()) {
          InvalidateRect(window, nullptr, FALSE);
        } else {
          KillTimer(window, kFrameTimerId);
        }
      }
      return 0;

    case WM_PAINT: {
      PAINTSTRUCT paint_struct{};
      HDC dc = BeginPaint(window, &paint_struct);
      Paint(dc);
      EndPaint(window, &paint_struct);
      return 0;
    }

    case WM_ERASEBKGND:
      return 1;

    case WM_DESTROY:
      KillTimer(window, kFrameTimerId);
      KillTimer(window, kCloseTimerId);
      {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (window == window_handle_) {
          window_handle_ = nullptr;
        }
      }
      PostQuitMessage(0);
      return 0;
  }

  return DefWindowProc(window, message, wparam, lparam);
}