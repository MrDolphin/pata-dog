param(
    [string]$HostIP = "127.0.0.1",
    [int]$Port = 4000,
    [int]$ParentPid = 0
)

# C# Source for global keyboard hook with self-termination and clean UDP forwarding
$source = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Net;
using System.Net.Sockets;
using System.Text;

public class GlobalKeyboardHook {
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_SYSKEYDOWN = 0x0104;
    private const uint WM_QUIT = 0x0012;

    private LowLevelKeyboardProc _proc;
    private IntPtr _hookID = IntPtr.Zero;
    private UdpClient _udpClient;
    private IPEndPoint _endPoint;
    private int _parentPid;
    private uint _hookThreadId;

    public delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    public struct MSG {
        public IntPtr hwnd;
        public uint message;
        public IntPtr wParam;
        public IntPtr lParam;
        public uint time;
        public int ptX;
        public int ptY;
    }

    public GlobalKeyboardHook(string host, int port, int parentPid) {
        _proc = HookCallback;
        _udpClient = new UdpClient();
        _endPoint = new IPEndPoint(IPAddress.Parse(host), port);
        _parentPid = parentPid;
    }

    public void Start() {
        _hookThreadId = GetCurrentThreadId();
        _hookID = SetHook(_proc);
        
        if (_parentPid > 0) {
            System.Threading.Thread checkThread = new System.Threading.Thread(CheckParentProcess);
            checkThread.IsBackground = true;
            checkThread.Start();
        }
    }

    public void RunLoop() {
        MSG msg;
        while (GetMessage(out msg, IntPtr.Zero, 0, 0) > 0) {
            TranslateMessage(ref msg);
            DispatchMessage(ref msg);
        }
        Stop();
    }

    public void Stop() {
        if (_hookID != IntPtr.Zero) {
            UnhookWindowsHookEx(_hookID);
            _hookID = IntPtr.Zero;
        }
        if (_udpClient != null) {
            _udpClient.Close();
            _udpClient = null;
        }
    }

    private IntPtr SetHook(LowLevelKeyboardProc proc) {
        using (Process curProcess = Process.GetCurrentProcess())
        using (ProcessModule curModule = curProcess.MainModule) {
            return SetWindowsHookEx(WH_KEYBOARD_LL, proc,
                GetModuleHandle(curModule.ModuleName), 0);
        }
    }

    private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && (wParam == (IntPtr)WM_KEYDOWN || wParam == (IntPtr)WM_SYSKEYDOWN)) {
            int vkCode = Marshal.ReadInt32(lParam);
            byte[] data = Encoding.UTF8.GetBytes(vkCode.ToString());
            try {
                _udpClient.Send(data, data.Length, _endPoint);
            } catch {
                // Ignore send errors
            }
        }
        return CallNextHookEx(_hookID, nCode, wParam, lParam);
    }

    private void CheckParentProcess() {
        while (true) {
            try {
                System.Diagnostics.Process.GetProcessById(_parentPid);
            } catch {
                // Parent process is dead, send WM_QUIT to hook thread
                PostThreadMessage(_hookThreadId, WM_QUIT, IntPtr.Zero, IntPtr.Zero);
                break;
            }
            System.Threading.Thread.Sleep(1000);
        }
    }

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook,
        LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode,
        IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("kernel32.dll")]
    private static extern uint GetCurrentThreadId();

    [DllImport("user32.dll")]
    private static extern sbyte GetMessage(out MSG lpMsg, IntPtr hWnd, uint wMsgFilterMin, uint wMsgFilterMax);

    [DllImport("user32.dll")]
    private static extern bool TranslateMessage(ref MSG lpMsg);

    [DllImport("user32.dll")]
    private static extern IntPtr DispatchMessage(ref MSG lpMsg);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool PostThreadMessage(uint idThread, uint Msg, IntPtr wParam, IntPtr lParam);
}
"@

Add-Type -TypeDefinition $source

$hook = New-Object GlobalKeyboardHook -ArgumentList $HostIP, $Port, $ParentPid

# Ensure event unregistration and cleanup on exit
[System.Management.Automation.PSEventJob]$job = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    if ($hook) { $hook.Stop() }
}

try {
    $hook.Start()
    $hook.RunLoop()
} finally {
    if ($hook) { $hook.Stop() }
    Unregister-Event -SourceIdentifier PowerShell.Exiting -ErrorAction SilentlyContinue
}
