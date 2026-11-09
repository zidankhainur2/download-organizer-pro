using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;
using System.Windows.Forms;

internal class Program
{
    // Windows command-line quoting, including quotes and trailing backslashes.
    internal static string Quote(string value)
    {
        var result = new StringBuilder("\"");
        int slashes = 0;
        foreach (char c in value)
        {
            if (c == '\\') { slashes++; continue; }
            result.Append('\\', c == '"' ? slashes * 2 + 1 : slashes);
            result.Append(c);
            slashes = 0;
        }
        result.Append('\\', slashes * 2);
        return result.Append('"').ToString();
    }

    [STAThread]
    private static int Main(string[] args)
    {
        bool gui = args.Length == 0 || Array.Exists(args, a => string.Equals(a, "-GUI", StringComparison.OrdinalIgnoreCase));
        Mutex mutex = null;
        bool ownsMutex = false;
        try
        {
            if (gui)
            {
                mutex = new Mutex(false, "Local\\DownloadOrganizerPro_GUI");
                try { ownsMutex = mutex.WaitOne(0); }
                catch (AbandonedMutexException) { ownsMutex = true; }
                if (!ownsMutex) { return 0; }
            }
            string script = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "DownloadOrganizer.ps1");
            if (!File.Exists(script)) { throw new FileNotFoundException("Organizer script is missing.", script); }
            var arguments = new StringBuilder("-NoProfile -STA -ExecutionPolicy Bypass -File ");
            arguments.Append(Quote(script));
            if (args.Length == 0) { arguments.Append(" -GUI"); }
            foreach (string arg in args) { arguments.Append(' ').Append(Quote(arg)); }
            var info = new ProcessStartInfo
            {
                FileName = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "WindowsPowerShell\\v1.0\\powershell.exe"),
                Arguments = arguments.ToString(),
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden
            };
            // Windows PowerShell must not inherit incompatible PowerShell 7 module paths.
            info.EnvironmentVariables.Remove("PSModulePath");
            using (Process worker = Process.Start(info))
            {
                worker.WaitForExit();
                return worker.ExitCode;
            }
        }
        catch (Exception error)
        {
            if (gui) { MessageBox.Show(error.Message, "Download Organizer Pro", MessageBoxButtons.OK, MessageBoxIcon.Error); }
            return 1;
        }
        finally
        {
            if (ownsMutex) { mutex.ReleaseMutex(); }
            if (mutex != null) { mutex.Dispose(); }
        }
    }
}
