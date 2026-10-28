
Melter.ps1

A PowerShell script that leverages inline C# and Win32 GDI API functions to capture the current desktop screen and create a "melting" visual artifact effect, where columns of pixels gradually slide down the display.

⚠️ Safety & Usage Notice

• Visual Obstruction: This script opens a borderless, full-screen, top-most window to animate the melting effect. It will completely obstruct the view of your desktop while running.
• Input Behavior: Depending on your exact implementation configuration, mouse clicks or keyboard strokes may either pass through or be blocked by the full-screen overlay.
• Safe Testing: It is highly recommended to run this tool in a virtual machine or controlled test environment before executing it on a production system.

Features

• Live Screen Capture: Uses Win32 Graphics Device Interface (GDI) hooks to grab a snapshot of the primary display context immediately upon execution.
• Dripping/Melting Animation: Implements a pixel-manipulation loop that randomly shifts individual vertical strips or blocks of pixels downward over time.
• Native Integration: Requires no heavy external dependencies; compiles its core C# drawing wrapper directly into memory at runtime using PowerShell's native compilation capability (Add-Type).

Requirements

• Operating System: Windows 10 / 11 or Windows Server.
• Environment: PowerShell 5.1+ (Desktop edition) with access to the .NET Framework assemblies System.Windows.Forms and System.Drawing.

How to Run

1. Open a PowerShell console.
2. Execute the script using your local execution path:powershell
.\Melter.ps1
Use code with caution.
