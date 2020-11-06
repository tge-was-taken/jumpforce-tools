UTIL_Y_TO_Z_UP_MATRIX = matrix3 [1, 0, 0, 0] [0, 0, 1, 0] [0, -1, 0, 0] [0, 0, 0, 1] -- x, z, -y
UTIL_Z_TO_Y_UP_MATRIX = matrix3  [1, 0, 0, 0] [0, 0, -1, 0] [0, 1, 0, 0] [0, 0, 0, 1] -- x, z, -y

fn utilHandleException = 
(
	local msg = "Exception: " + (getCurrentException()) + \
		"\nStacktrace: " + (getCurrentExceptionStackTrace()) + \
		"\nCallstack: " + (getCurrentExceptionCallStack());
	
	local theFrm = dotNetObject "MaxCustomControls.MaxForm";
	local theBox = dotNetObject "MaxCustomControls.MaxTextBox";
	local dockMode = (dotNetClass "System.Windows.Forms.DockStyle").Fill;
	theBox.Multiline = true;
	theBox.Text = (replace_LF_with_CRLF msg);
	theBox.Dock = dockMode;
	theBox.WordWrap = false;
	theFrm.controls.add theBox;
	theFrm.topmost = true;
	theFrm.text = "Error occured";
	theFrm.width = 1024;
	theFrm.height = 768;
	thePtr = DotNetObject "System.IntPtr" (windows.getMAXHWND());
	theHwnd = (dotNetObject "System.Windows.Forms.NativeWindow").FromHandle thePtr;
	theFrm.Show(theHwnd);
)