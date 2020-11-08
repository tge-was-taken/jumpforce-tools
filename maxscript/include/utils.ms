UTIL_Y_TO_Z_UP_MATRIX = matrix3 [1, 0, 0, 0] [0, 0, 1, 0] [0, -1, 0, 0] [0, 0, 0, 1] -- x, -z, y
UTIL_Z_TO_Y_UP_MATRIX = matrix3  [1, 0, 0, 0] [0, 0, -1, 0] [0, 1, 0, 0] [0, 0, 0, 1]  -- x, z, -y
UTIL_MIRROR_X_MATRIX = matrix3 [-1, 0, 0, 0] [0, 1, 0, 0] [0, 0, 1, 0] [0, 0, 0, 1] -- -x, z, y

fn utilMatrixComponentMultiply m v =
(
	-- Decompose
	local t = m.translationpart;
	local r = m.rotationpart;
	local s = m.scalepart;
	
	-- Mirror translation
	t *= v; 
	
	-- Mirror rotation
	local rDeg = quatToEuler r order:1;
	rDeg.x *= v.x;
	rDeg.y *= v.y;
	rDeg.z *= v.z;
	r = eulerToQuat rDeg order:1;
	
	-- Mirror scale
	s *= v;
	
	-- Rebuild matrix
	m = matrix3 1;
	rotate m r;
	scale m s;
	translate m t;
	m;
)

fn utilMatrixMirrorX m =
(
	utilMatrixComponentMultiply m [-1, 1, 1];
)

-- Component-wise conversion of a matrix from Y to Z up 
fn utilMatrixYToZUp m =
(
	-- Decompose
	local t = m.translationpart;
	local r = m.rotationpart;
	local s = m.scalepart;
	
	-- Flip translation
	local tmp;
	y = t.y;
	t.y = -t.z;
	t.z = y;
	
	-- Flip rotation
	local rDeg = quatToEuler r order:1;
	y = rDeg.y;
	rDeg.y = -rDeg.z;
	rDeg.z = y;
	r = eulerToQuat rDeg order:1;
	
	-- Flip scale
	y = s.y;
	s.y = -s.z;
	s.z = y;
	
	-- Rebuild matrix
	m = matrix3 1;
	rotate m r;
	scale m s;
	translate m t;
	m;
)

-- Component-wise conversion of a matrix from Z to Y up 
fn utilMatrixZToYUp m =
(
	-- Decompose
	local t = m.translationpart;
	local r = m.rotationpart;
	local s = m.scalepart;
	
	-- Flip translation
	local tmp;
	y = t.y;
	t.y = -t.z;
	t.z = y;
	
	-- Flip rotation
	local rDeg = quatToEuler r order:1;
	y = rDeg.y;
	rDeg.y = -rDeg.z;
	rDeg.z = y;
	r = eulerToQuat rDeg order:1;
	
	-- Flip scale
	y = s.y;
	s.y = -s.z;
	s.z = y;
	
	-- Rebuild matrix
	m = matrix3 1;
	rotate m r;
	scale m s;
	translate m t;
	m;
)

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