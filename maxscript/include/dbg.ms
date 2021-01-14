fn str v =
(
	v as string;
)

fn vec3ToStr v =
(
	"[" + str(v.x) + "," + str(v.y) + "," + str(v.z) + "]";
)

fn vec4ToStr v =
(
	"[" + str(v.x) + "," + str(v.y) + "," + str(v.z) + "," + str(v.w) + "]";
)

fn dbgDumpBones =
(
	local maxBones = for obj in objects where (classof obj == BoneGeometry) collect obj;
	for b in maxBones do
	(
		local m = b.transform;
		local t = m.translationpart;
		local r = m.rotationpart;
		local s = m.scalepart;
		local rDeg = quatToEuler r order:1;
		
		print (b.Name + "\t" + vec3ToStr(t) + "\t" + vec4ToStr(r) + "\t" + vec3ToStr(rDeg) + "\t" + vec3ToStr(s))
	)	
)

fn dbgPrintHex n v =
(
	print(n + " = 0x" + (bit.intAsHex v))
)

--dbgDumpBones();