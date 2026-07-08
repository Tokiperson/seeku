#ifndef RUNNER_SPLASH_WINDOW_H_
#define RUNNER_SPLASH_WINDOW_H_

#include <windows.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <wrl/client.h>

#include <condition_variable>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

// A lightweight native splash window that loops an MP4 before Flutter's first
// frame is ready.
class SplashWindow {
 public:
  SplashWindow();
  ~SplashWindow();

  bool CreateAndShow(const std::wstring& video_path);
  void Close();

  static LRESULT CALLBACK WndProc(HWND window, UINT message, WPARAM wparam,
                                  LPARAM lparam) noexcept;

 private:
  LRESULT MessageHandler(HWND window, UINT message, WPARAM wparam,
                         LPARAM lparam) noexcept;

  void ThreadMain(std::wstring video_path);
  bool CreateWindowOnCurrentThread(const std::wstring& video_path);
  bool InitializeMedia(const std::wstring& video_path);
  bool ReadNextFrame();
  void Paint(HDC dc);
  void ReleaseMedia();
  void NotifyStartupComplete(bool succeeded);

  std::thread splash_thread_;
  std::mutex state_mutex_;
  std::condition_variable startup_condition_;
  bool startup_complete_ = false;
  bool startup_succeeded_ = false;
  HWND window_handle_ = nullptr;

  bool close_requested_ = false;
  ULONGLONG start_tick_ms_ = 0;
  bool media_foundation_started_ = false;
  UINT timer_interval_ms_ = 33;
  UINT32 frame_width_ = 0;
  UINT32 frame_height_ = 0;
  LONG frame_stride_ = 0;
  std::vector<BYTE> frame_pixels_;
  Microsoft::WRL::ComPtr<IMFSourceReader> source_reader_;
};

#endif  // RUNNER_SPLASH_WINDOW_H_