/*

Jump Force SP2 model animation data library for 3ds Max
Created:	05/01/2021
Author: 	Chris Weermann (aka TGE)
Web page:	https://github.com/TGEnigma, https://checkpoint.cc/tge
Rivision History:

	??.??.2020 v1.00
	- first public release
	
*/

FileIn "sp2.ms";

SP2_MODEL_ANIMATION_DATA_HEADER_SIGNATURE = 0x24414E4D;

fn Sp2CalcVector3LengthSquared x y z =
(
    local lenSq = 0.0;
    local len = 1.0 - (x * x) + (y * y) + (z * z);
    if ( len > 0.0 ) then
        lenSq = sqrt(len);
	
	lenSq;
)

-- Smallest three method, adapted from https://gist.github.com/StagPoint/bb7edf61c2e97ce54e3e4561627f6582
fn Sp2ModelAnimationDataCompressRotation dec =
(
	local maxIndex = 0; 
	local maxValue = 1.175494351E-38;
	local sign = 1f;

	-- Determine the index of the largest (absolute value) element in the Quaternion.
	-- We will transmit only the three smallest elements, and reconstruct the largest
	-- element during decoding. 
	local absVal = abs( dec.x );
	if( absVal > maxValue ) then
	(
		-- We don't need to explicitly transmit the sign bit of the omitted element because you 
		-- can make the omitted element always positive by negating the entire quaternion if 
		-- the omitted element is negative (in quaternion space (x,y,z,w) and (-x,-y,-z,-w) 
		-- represent the same rotation.), but we need to keep track of the sign for use below.
		if ( dec.x < 0 ) then sign = -1; 
		else sign = 1;

		-- Keep track of the index of the largest element
		maxIndex = 0;
		maxValue = absVal;
	)
	
	absVal = abs( dec.y );
	if( absVal > maxValue ) then
	(
		if ( dec.y < 0 ) then sign = -1; 
		else sign = 1;
		maxIndex = 1;
		maxValue = absVal;
	)
	
	absVal = abs( dec.z );
	if( absVal > maxValue ) then
	(
		if ( dec.z < 0 ) then sign = -1; 
		else sign = 1;
		maxIndex = 2;
		maxValue = absVal;
	)
	
	absVal = abs( dec.w );
	if( absVal > maxValue ) then
	(
		if ( dec.w < 0 ) then sign = -1; 
		else sign = 1;
		maxIndex = 3;
		maxValue = absVal;
	)


-- 	-- If the maximum value is approximately 1f (such as Quaternion.identity [0,0,0,1]), then we can 
-- 	-- reduce storage even further due to the fact that all other fields must be 0f by definition, so 
-- 	-- we only need to send the index of the largest field.
-- 	if( close_enough maxValue 1f 10 )
-- 	(
-- 		-- Again, don't need to transmit the sign since in quaternion space (x,y,z,w) and (-x,-y,-z,-w) 
-- 		-- represent the same rotation. We only need to send the index of the single element whose value
-- 		-- is 1f in order to recreate an equivalent rotation on the receiver.
-- 		writer.Write( maxIndex + 4 );
-- 		return;
-- 	)

	local a = 0;
	local b = 0;
	local c = 0;
	
	if( maxIndex == 0 ) then
	(
		a = dec.y * sign;
		b = dec.z * sign;
		c = dec.w * sign;
	)
	else if( maxIndex == 1 ) then
	(
		a = dec.x * sign;
		b = dec.z * sign;
		c = dec.w * sign;
	)
	else if( maxIndex == 2 ) then
	(
		a = dec.x * sign;
		b = dec.y * sign;
		c = dec.w * sign;
	)
	else
	(
		a = dec.x * sign;
		b = dec.y * sign;
		c = dec.z * sign;
	)
	
	local cmp = 0 as Integer64;
	cmp = bit.or cmp (             bit.and ( ( ( ( a / 1.4142135 ) + 0.5 ) / 0.00000095367523 ) as Integer64 ) 0xFFFFF );
	cmp = bit.or cmp ( bit.shift ( bit.and ( ( ( ( b / 1.4142135 ) + 0.5 ) / 0.00000095367523 ) as Integer64 ) 0xFFFFF ) 20 );
	cmp = bit.or cmp ( bit.shift ( bit.and ( ( ( ( c / 1.4142135 ) + 0.5 ) / 0.00000095367523 ) as Integer64 ) 0xFFFFF ) 40 );
	cmp = bit.or cmp ( bit.shift ( ( bit.and maxIndex 0xF ) as Integer64 ) 60 );
	cmp;
)

-- SpJobAnimation::DecompressRotation
fn Sp2ModelAnimationDataDecompressRotation cmp =
(
    local maxIndex = bit.shift cmp -60;
    local a = ((((bit.and cmp                 0xFFFFF) as float) * 0.00000095367523) - 0.5) * 1.4142135;
    local b = ((((bit.and (bit.shift cmp -20) 0xFFFFF) as float) * 0.00000095367523) - 0.5) * 1.4142135;
    local c = ((((bit.and (bit.shift cmp -40) 0xFFFFF) as float) * 0.00000095367523) - 0.5) * 1.4142135;
    
    local decX = a;
    local decY = b;
    local decZ = c;
    local decW = 0.0;

    local lenSq = 0.0;
    local len = 1.0 - ((a * a) + (b * b) + (c * c));
    if ( len > 0.0 ) then
        lenSq = sqrt(len);

    case ( maxIndex ) of
    (
        0:
        (
            decY = a;
            decZ = b;
            decW = c;
        )
        1:
        (
            decZ = b;
            decW = c;
        )
        2:
        (
            decW = c;
        )
    )

    case ( maxIndex ) of
    (
        0:
        (
            decX = lenSq;
        )
        1:
        (
            decY = lenSq;
        )
        2:
        (
            decZ = lenSq;
        )
        3:
        (
            decW = lenSq;
        )
        default:
        (
            Assert(false);
        )
    )
	
    local dec = quat decX decY decZ decW;
)

struct Sp2ModelAnimationDataCamFovController
(
	fn GetStructSize = 20,
		
	NameOffset = 0,
	Field04 = 0,
	KeyCount = 0,
	KeyTimesOffset = 0,
	KeyValuesOffset = 0,
	--
	Name = "",
	KeyTimes = #(),
	KeyValues = #(),
	
	fn Read ctx = 
	(
		NameOffset = ioReadU32LE();
		Field04 = ioReadU32LE();
		KeyCount = ioReadU32LE();
		KeyTimesOffset = ioReadU32LE();
		KeyValuesOffset = ioReadU32LE();
		local next = ioTell();
		
        ioSeekSet( ctx.BaseOffset + NameOffset );
        Name = ioReadCString();
		
		if ( KeyCount > 0 ) then
		(
			ioSeekSet( ctx.BaseOffset + KeyTimesOffset );
			for i = 1 to KeyCount do KeyTimes[i] = ioReadF32LE();
			
			ioSeekSet( ctx.BaseOffset + KeyValuesOffset );
			for i = 1 to KeyCount do KeyValues[i] = ioReadF32LE();
		)
		
		ioSeekSet( next );
	),
	
	fn BeginWrite ctx =
	(
		KeyCount = KeyValues.Count;
	),
	
	fn EndWrite ctx =
	(
        ioWriteU32LE( NameOffset );
        ioWriteU32LE( Field04 );
        ioWriteU32LE( KeyCount );
        ioWriteU32LE( KeyTimesOffset );
        ioWriteU32LE( KeyValuesOffset );
		local structEnd = ioTell();
		
		ioSeekSet( ctx.BaseOffset + NameOffset );
		ioWriteCString( Name );
		
		if ( KeyCount > 0 ) then
		(
			ioSeekSet( ctx.BaseOffset + KeyTimesOffset );
			for i = 1 to KeyCount do ioWriteF32LE( KeyTimes[i] );
			
			ioSeekSet( ctx.BaseOffset + KeyValuesOffset );
			for i = 1 to KeyCount do ioWriteF32LE( KeyValues[i] );
		)
		
		ioSeekSet( structEnd );
	),

    fn Write ctx =
    (
		BeginWrite ctx;
		EndWrite ctx;
    )
)

struct Sp2ModelAnimationDataTrsController
(
	fn GetStructSize = 40,
	
    NameOffset = 0,
    TranslationKeyCount = 0,
    RotationKeyCount = 0,
    ScaleKeyCount = 0,
    TranslationKeyTimesOffset = 0,
    RotationKeyTimesOffset = 0,
    ScaleKeyTimesOffset = 0,
    TranslationKeyValuesOffset = 0,
    RotationKeyValuesOffset = 0,
    ScaleKeyValuesOffset = 0,
    --
    Name = "",
    TranslationKeyTimes = #(),
    RotationKeyTimes = #(),
    ScaleKeyTimes = #(),
    TranslationKeyValues = #(),
    RotationKeyValues = #(),
	RotationKeyValuesCmp = #(),
    ScaleKeyValues = #(),

    fn Read ctx =
    (
        NameOffset = ioReadU32LE();
        TranslationKeyCount = ioReadU32LE();
        RotationKeyCount = ioReadU32LE();
        ScaleKeyCount = ioReadU32LE();
        TranslationKeyTimesOffset = ioReadU32LE();
        RotationKeyTimesOffset = ioReadU32LE();
        ScaleKeyTimesOffset = ioReadU32LE();
        TranslationKeyValuesOffset = ioReadU32LE();
        RotationKeyValuesOffset = ioReadU32LE();
        ScaleKeyValuesOffset = ioReadU32LE();
        local next = ioTell();
        
        ioSeekSet( ctx.BaseOffset + NameOffset );
        Name = ioReadCString();

		if ( TranslationKeyCount > 0 ) then
		(
			ioSeekSet( ctx.BaseOffset + TranslationKeyTimesOffset );
			for i = 1 to TranslationKeyCount do TranslationKeyTimes[i] = ioReadF32LE();
			
			ioSeekSet( ctx.BaseOffset + TranslationKeyValuesOffset );
			for i = 1 to TranslationKeyCount do TranslationKeyValues[i] = [ioReadF32LE(), ioReadF32LE(), ioReadF32LE(), ioReadF32LE()];
		)

		if ( RotationKeyCount > 0 ) then
		(
			ioSeekSet( ctx.BaseOffset + RotationKeyTimesOffset );
			for i = 1 to RotationKeyCount do RotationKeyTimes[i] = ioReadF32LE();
			
			ioSeekSet( ctx.BaseOffset + RotationKeyValuesOffset );
			for i = 1 to RotationKeyCount do 
			(
				local cmp = ioReadU64LE();
				local dec = Sp2ModelAnimationDataDecompressRotation( cmp );
/* 				local newCmp = Sp2ModelAnimationDataCompressRotation dec;
* 				local newDec = Sp2ModelAnimationDataDecompressRotation newCmp;
* 				if ( not ( close_enough dec.x newDec.x 10 and \
* 						   close_enough dec.y newDec.y 10 and \
* 						   close_enough dec.z newDec.z 10 and \
* 						   close_enough dec.w newDec.w 10 ) ) then
* 				(
* 					print ( "o:" + (bit.intAsHex cmp));
* 					print ( "n:" + (bit.intAsHex newCmp));
* 					print ( "decoded o:" + (Sp2ModelAnimationDataDecompressRotation(cmp)) as string);
* 					print ( "decoded n:" + (Sp2ModelAnimationDataDecompressRotation(newCmp)) as string);
* 				)
*/
				
				RotationKeyValues[i] = dec;
			)
		)

		if ( ScaleKeyCount > 0 ) then
		(
			ioSeekSet( ctx.BaseOffset + ScaleKeyTimesOffset );
			for i = 1 to ScaleKeyCount do ScaleKeyTimes[i] = ioReadF32LE();
			
			ioSeekSet( ctx.BaseOffset + ScaleKeyValuesOffset );
			for i = 1 to ScaleKeyCount do ScaleKeyValues[i] = [ioReadF32LE(), ioReadF32LE(), ioReadF32LE(), ioReadF32LE()];
		)
		
		ioSeekSet( next );
    ),
	
	fn BeginWrite ctx =
	(
		TranslationKeyCount = TranslationKeyValues.Count;
		RotationKeyCount = RotationKeyValues.Count;
		ScaleKeyCount = ScaleKeyValues.Count;
	),
	
	fn EndWrite ctx =
	(
        ioWriteU32LE( NameOffset );
        ioWriteU32LE( TranslationKeyCount );
        ioWriteU32LE( RotationKeyCount );
        ioWriteU32LE( ScaleKeyCount );
        ioWriteU32LE( TranslationKeyTimesOffset );
        ioWriteU32LE( RotationKeyTimesOffset );
        ioWriteU32LE( ScaleKeyTimesOffset );
        ioWriteU32LE( TranslationKeyValuesOffset );
        ioWriteU32LE( RotationKeyValuesOffset );
        ioWriteU32LE( ScaleKeyValuesOffset );
		local structEnd = ioTell();
		
		ioSeekSet( ctx.BaseOffset + NameOffset );
		ioWriteCString( Name );
		
		if ( TranslationKeyCount > 0 ) then
		(
			ioSeekSet( ctx.BaseOffset + TranslationKeyTimesOffset );
			for i = 1 to TranslationKeyCount do ioWriteF32LE( TranslationKeyTimes[i] );
			
			ioSeekSet( ctx.BaseOffset + TranslationKeyValuesOffset );
			for i = 1 to TranslationKeyCount do
			(
				local val = TranslationKeyValues[i];
				ioWriteF32LE val.X;
				ioWriteF32LE val.Y;
				ioWriteF32LE val.Z;
				ioWriteF32LE 1.0;
			)
		)
		
		if ( RotationKeyCount > 0 ) then
		(
			ioSeekSet( ctx.BaseOffset + RotationKeyTimesOffset );
			for i = 1 to RotationKeyCount do ioWriteF32LE( RotationKeyTimes[i] );
			
			ioSeekSet( ctx.BaseOffset + RotationKeyValuesOffset );
			for i = 1 to RotationKeyCount do 
			(
				local cmp = Sp2ModelAnimationDataCompressRotation RotationKeyValues[i];
				ioWriteU64LE( cmp );
			)
		)
		
		if ( ScaleKeyCount > 0 ) then
		(
			ioSeekSet( ctx.BaseOffset + ScaleKeyTimesOffset );
			for i = 1 to ScaleKeyCount do ioWriteF32LE( ScaleKeyTimes[i] );
			
			ioSeekSet( ctx.BaseOffset + ScaleKeyValuesOffset );
			for i = 1 to ScaleKeyCount do 
			(
				local val = ScaleKeyValuesOffset[i];
				ioWriteF32LE val.X;
				ioWriteF32LE val.Y;
				ioWriteF32LE val.Z;
				ioWriteF32LE 1.0;
			)
		)
		
		ioSeekSet( structEnd );
	),

    fn Write ctx =
    (
		BeginWrite ctx;
		EndWrite ctx;
    )
)

struct Sp2ObjectOffsetDict
(
	Dict = #(),
	
	fn GetListOffset list =
	(
		if ( list.count == 0 ) then return -1;
		
		for k = 1 to dict.count do
		(
			local dictEntry = dict[k];
			local dictValue = dictEntry[1];
			local dictKey = dictEntry[2];
			
			if ( not ( dictValue.count == list.count ) ) then
				continue;
			
			local isEqual = true;
			for l = 1 to dictValue.count do
			(
				if ( list[l] != dictValue[l] ) then
				(
					isEqual = false;
					exit;
				)
			)
			
			if ( isEqual ) then
			(
				return dictKey;
			)
		)
		
		-1;
	),
	
	fn AddListOffset list offset =
	(
		append dict #( list, offset );
	)
)

struct Sp2ModelAnimationDataFileHeader
(
	fn GetStructSize = 38,
	
    Field00 = 4,
    Duration = 0.0,
    BoneControllersOffset = 0,
    AttachControllersOffset = 0,
    CamControllersOffset = 0,
    UnkControllersOffset = 0,
    CamFovControllersOffset = 0,
    BoneControllerCount = 0,
    AttachControllerCount = 0,
    CamControllerCount = 0,
    UnkControllerCount = 0,
    CamFovControllerCount = 0,
    --
    BoneControllers = #(),
    AttachControllers = #(),
    CamControllers = #(),
    UnkControllers = #(),
    CamFovControllers = #(),
	
	fn GetTrsControllers =
	(
		#( BoneControllers, AttachControllers, CamControllers, UnkControllers );
	),

    fn ReadTrsControllers ctx offset count =
    (
		local list = #();
		if ( count > 0 ) then
		(
			ioSeekSet( ctx.BaseOffset + offset );
			list[count] = undefined;
			for i = 1 to count do
			(
				local anim = Sp2ModelAnimationDataTrsController();
				anim.Read ctx;
				list[i] = anim;
			)
		)
        list;
    ),
	
    fn ReadCamFovControllers ctx offset count =
    (
		local list = #();
		if ( count > 0 ) then
		(
			ioSeekSet( ctx.BaseOffset + offset );
			list[count] = undefined;
			for i = 1 to count do
			(
				local anim = Sp2ModelAnimationDataCamFovController();
				anim.Read ctx;
				list[i] = anim;
			)
		)
        list;
    ),

    fn Read ctx =
    (
        ctx.PushBaseOffset( ioTell() );
        Field00 = ioReadU32LE();
        Duration = ioReadF32LE();
        BoneControllersOffset = ioReadU32LE();
        AttachControllersOffset = ioReadU32LE();
        CamControllersOffset = ioReadU32LE();
        UnkControllersOffset = ioReadU32LE();
        CamFovControllersOffset = ioReadU32LE();
        BoneControllerCount = ioReadU16LE();
        AttachControllerCount = ioReadU16LE();
        CamControllerCount = ioReadU16LE();
        UnkControllerCount = ioReadU16LE();
        CamFovControllerCount = ioReadU16LE();
		local next = ioTell();

        BoneControllers = ReadTrsControllers ctx BoneControllersOffset BoneControllerCount;
        AttachControllers = ReadTrsControllers ctx AttachControllersOffset AttachControllerCount;
        CamControllers = ReadTrsControllers ctx CamControllersOffset CamControllerCount;
        UnkControllers = ReadTrsControllers ctx UnkControllersOffset UnkControllerCount;
        CamFovControllers = ReadCamFovControllers ctx CamFovControllersOffset CamFovControllerCount;
		
		ioSeekSet( next );
		ctx.PopBaseOffset();
    ),
	
	fn WriteControllers ctx offset list =
	(
		if ( offset > 0 ) then
		(
			ioSeekSet( ctx.BaseOffset + offset );
			for i = 1 to list.count do
				list[i].Write ctx;
		)
	),
		
	fn BoneAnimNameCompare a b =
	(
		if ( a[1] < b[1] ) then
		(
			-1
		)
		else if ( a[1] == b[1] ) then
		(
			0
		)
		else
		(
			1
		)
	),
	
	-- TODO doesnt match entirely-- more repetitions in original file
	fn BeginWrite ctx =
	(
		-- fill in counts
		BoneControllerCount = BoneControllers.Count;
		AttachControllerCount = AttachControllers.Count;
		CamControllerCount = CamControllers.Count;
		UnkControllerCount = UnkControllers.Count;
		CamFovControllerCount = CamFovControllers.Count;
		
		-- fill in offsets
		ctx.PushBaseOffset();
		local structStart = ioTell();
		local structEnd = structStart + GetStructSize();
		local dataStart = ioAlign structEnd 16;
		local dataCursor = dataStart;
		
		if ( BoneControllers.Count > 0 ) then
		(
			dataCursor = (ioAlign dataCursor 16);
			BoneControllersOffset = dataCursor - ctx.BaseOffset;
			dataCursor += Sp2ModelAnimationDataTrsController.GetStructSize() * BoneControllers.Count;
		)
		
		if ( AttachControllers.Count > 0 ) then
		(
			dataCursor = (ioAlign dataCursor 16);
			AttachControllersOffset = dataCursor - ctx.BaseOffset;
			dataCursor += Sp2ModelAnimationDataTrsController.GetStructSize() * AttachControllers.Count;
		)
		
		if ( CamControllers.Count > 0 ) then
		(
			dataCursor = (ioAlign dataCursor 16);
			CamControllersOffset = dataCursor - ctx.BaseOffset;
			dataCursor += Sp2ModelAnimationDataTrsController.GetStructSize() * CamControllers.Count;
		)
		
		if ( UnkControllers.Count > 0 ) then
		(
			dataCursor = (ioAlign dataCursor 16);
			UnkControllersOffset = dataCursor - ctx.BaseOffset;
			dataCursor += Sp2ModelAnimationDataTrsController.GetStructSize() * UnkControllers.Count;
		)
		
		if ( CamFovControllers.Count > 0 ) then
		(
			dataCursor = (ioAlign dataCursor 16);
			CamFovControllersOffset = dataCursor - ctx.BaseOffset;
			dataCursor += Sp2ModelAnimationDataCamFovController.GetStructSize() * CamFovControllers.Count;
		)
		
		local trsControllers = GetTrsControllers();
		local objectOffsetDict = Sp2ObjectOffsetDict();
		
		-- TODO deduplicate?
		local sortedNames = #();
		
		-- Collect all names & sort alphabetically
		for i = 1 to trsControllers.Count do
		(
			-- Collect all names
			for j = 1 to trsControllers[i].Count do
			(
				append sortedNames #( trsControllers[i][j].Name, trsControllers[i][j] );
			)
		)
		
		for ctrl in CamFovControllers do append sortedNames #( ctrl.Name, ctrl );
		
		
		qsort sortedNames BoneAnimNameCompare;
		
		for i = 1 to trsControllers.Count do
		(
			for j = 1 to trsControllers[i].Count do
			(
				local list = trsControllers[i][j].TranslationKeyValues;
				local offset = objectOffsetDict.GetListOffset list;
				if ( offset == -1 ) then
				(
					dataCursor = (ioAlign dataCursor 16);
					offset = dataCursor - ctx.BaseOffset;
					dataCursor += (16 * list.Count);
					objectOffsetDict.AddListOffset list offset;
				)
				
				trsControllers[i][j].TranslationKeyValuesOffset = offset;
			)
		)
		
		for i = 1 to trsControllers.Count do
		(
			for j = 1 to trsControllers[i].Count do
			(
				local list = trsControllers[i][j].RotationKeyValues;
-- 				local list = trsControllers[i][j].RotationKeyValuesCmp;
-- 				if ( list == undefined ) then
-- 				(
-- 					trsControllers[i][j].RotationKeyValuesCmp = #();
-- 					for k = 1 to trsControllers[i][j].RotationKeyValues.Count do append trsControllers[i][j].RotationKeyValuesCmp (Sp2ModelAnimationDataCompressRotation trsControllers[i][j].RotationKeyValues[k]);
-- 					list = trsControllers[i][j].RotationKeyValuesCmp;
-- 				)
				
				local offset = objectOffsetDict.GetListOffset list;
				if ( offset == -1 ) then
				(
					dataCursor = (ioAlign dataCursor 16);
					offset = dataCursor - ctx.BaseOffset;
					dataCursor += (8 * list.Count);
					objectOffsetDict.AddListOffset list offset;
				)
				
				trsControllers[i][j].RotationKeyValuesOffset = offset;
			)
		)
		
		for i = 1 to trsControllers.Count do
		(
			for j = 1 to trsControllers[i].Count do
			(
				local list = trsControllers[i][j].ScaleKeyValues;
				local offset = objectOffsetDict.GetListOffset list;
				if ( offset == -1 ) then
				(
					dataCursor = (ioAlign dataCursor 16);
					offset = dataCursor - ctx.BaseOffset;
					dataCursor += (16 * list.Count);
					objectOffsetDict.AddListOffset list offset;
				)
				
				trsControllers[i][j].ScaleKeyValuesOffset = offset;
			)
			
		)
		
		for i = 1 to CamFovControllers.Count do
		(
			local list = CamFovControllers[i].KeyValues;
			local offset = objectOffsetDict.GetListOffset list;
			if ( offset == -1 ) then
			(
				dataCursor = (ioAlign dataCursor 16);
				offset = dataCursor - ctx.BaseOffset;
				dataCursor += (4 * list.Count);
				objectOffsetDict.AddListOffset list offset;
			)
			
			CamFovControllers[i].KeyValuesOffset = offset;
		)
			
		for i = 1 to trsControllers.Count do
		(
			for j = 1 to trsControllers[i].Count do
			(
				local list = trsControllers[i][j].TranslationKeyTimes;
				local offset = objectOffsetDict.GetListOffset list;
				if ( offset == -1 ) then
				(
					dataCursor = (ioAlign dataCursor 16);
					offset = dataCursor - ctx.BaseOffset;
					dataCursor += (4 * list.Count);
					objectOffsetDict.AddListOffset list offset;
				)
				
				trsControllers[i][j].TranslationKeyTimesOffset = offset;
			)
		)
			
		for i = 1 to trsControllers.Count do
		(
			for j = 1 to trsControllers[i].Count do
			(
				local list = trsControllers[i][j].RotationKeyTimes;
				local offset = objectOffsetDict.GetListOffset list;
				if ( offset == -1 ) then
				(
					dataCursor = (ioAlign dataCursor 16);
					offset = dataCursor - ctx.BaseOffset;
					dataCursor += (4 * list.Count);
					objectOffsetDict.AddListOffset list offset;
				)
				
				trsControllers[i][j].RotationKeyTimesOffset = offset;
			)
		)
			
		for i = 1 to trsControllers.Count do
		(
			for j = 1 to trsControllers[i].Count do
			(
				local list = trsControllers[i][j].ScaleKeyTimes;
				local offset = objectOffsetDict.GetListOffset list;
				if ( offset == -1 ) then
				(
					dataCursor = (ioAlign dataCursor 16);
					offset = dataCursor - ctx.BaseOffset;
					dataCursor += (4 * list.Count);
					objectOffsetDict.AddListOffset list offset;
				)
				
				trsControllers[i][j].ScaleKeyTimesOffset = offset;
			)
		)
		
		for i = 1 to CamFovControllers.Count do
		(
			local list = CamFovControllers[i].KeyTimes;
			local offset = objectOffsetDict.GetListOffset list;
			if ( offset == -1 ) then
			(
				dataCursor = (ioAlign dataCursor 16);
				offset = dataCursor - ctx.BaseOffset;
				dataCursor += (4 * list.Count);
				objectOffsetDict.AddListOffset list offset;
			)
			
			CamFovControllers[i].KeyTimesOffset = offset;
		)
			
		-- Write names in alphabetic order
		dataCursor = (ioAlign dataCursor 16);
		for j = 1 to sortedNames.Count do
		(
			sortedNames[j][2].NameOffset = dataCursor - ctx.BaseOffset;
			dataCursor += (sortedNames[j][1].Count + 1);
		)
	),

    fn EndWrite ctx = 
    (
        ioWriteU32LE( Field00 );
        ioWriteF32LE( Duration );
        ioWriteU32LE( BoneControllersOffset );
        ioWriteU32LE( AttachControllersOffset );
        ioWriteU32LE( CamControllersOffset );
        ioWriteU32LE( UnkControllersOffset );
        ioWriteU32LE( CamFovControllersOffset );
        ioWriteU16LE( BoneControllerCount );
        ioWriteU16LE( AttachControllerCount );
        ioWriteU16LE( CamControllerCount );
        ioWriteU16LE( UnkControllerCount );
        ioWriteU16LE( CamFovControllerCount );
		local structEnd = ioTell();
		
		WriteControllers ctx BoneControllersOffset BoneControllers;
		WriteControllers ctx AttachControllersOffset AttachControllers;
		WriteControllers ctx CamControllersOffset CamControllers;
		WriteControllers ctx UnkControllersOffset UnkControllers;
		WriteControllers ctx CamFovControllersOffset CamFovControllers;
		
		ioSeekSet( structEnd );
		ctx.PopBaseOffset();
    ),
	
	fn Write ctx =
	(
		BeginWrite ctx;
		EndWrite ctx;
	)
)

struct Sp2ModelAnimationData
(
    Header = Sp2ResourceFileChunkHeader Signature:SP2_MODEL_ANIMATION_DATA_HEADER_SIGNATURE,
    Data = Sp2ModelAnimationDataFileHeader(),
	ResourceItem = Sp2ResourceItem(),

    fn Read ctx = 
    (
        Header = ctx.Header;
		local pEnd = ioTell();

        ioSeekSet( ctx.BaseOffset + (1 + Header.AdditionalHeaderCount) * 16 );
        Data.Read ctx;

        if ( Header.ResourceItemSize > 0 ) then
        (
            local next = ioTell();
            ioSeekSet( ioAlign (pEnd + Header.DataSize) 16 );
            ResourceItem.Read ctx;
        )
    ),
	
	fn Write ctx =
	(
		ctx.BeginWriteChunk Header true ResourceItem;
		Data.Write ctx;
		ctx.EndWriteChunk();
	)
)

