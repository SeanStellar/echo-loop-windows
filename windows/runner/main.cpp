#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// 单实例：同一用户会话只允许一个进程，避免两个实例同时写 SQLite。
constexpr wchar_t kSingleInstanceMutexName[] =
    L"Local\\EchoLoop.Windows.SingleInstance";
constexpr wchar_t kMainWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";
constexpr wchar_t kMainWindowTitle[] = L"Echo Loop";

// 找到已运行实例的主窗口并激活；窗口可能尚未完成首帧，调用方负责重试。
bool ActivateExistingWindow() {
  HWND hwnd = nullptr;
  while ((hwnd = FindWindowExW(nullptr, hwnd, kMainWindowClassName,
                               kMainWindowTitle)) != nullptr) {
    if (!IsWindowVisible(hwnd)) continue;
    ShowWindow(hwnd, IsIconic(hwnd) ? SW_RESTORE : SW_SHOW);
    SetForegroundWindow(hwnd);
    return true;
  }
  return false;
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // 互斥量句柄随进程存活，不主动关闭，否则其他实例会误判为可启动。
  HANDLE single_instance_mutex =
      CreateMutexW(nullptr, FALSE, kSingleInstanceMutexName);
  if (single_instance_mutex != nullptr &&
      GetLastError() == ERROR_ALREADY_EXISTS) {
    // 第一个实例可能仍在启动，最多等待约 3 秒让它创建窗口。
    for (int attempt = 0; attempt < 15; ++attempt) {
      if (ActivateExistingWindow()) break;
      Sleep(200);
    }
    return EXIT_SUCCESS;
  }
  // 句柄保持打开直到进程退出；显式引用避免未使用变量告警。
  (void)single_instance_mutex;

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Echo Loop", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
