/*

Jump Force skeleton (skl) importer for 3ds Max
Created:	04/11/2020
Author: 	Chris Weermann (aka TGE)
Web page:	https://github.com/TGEnigma, https://checkpoint.cc/tge
Rivision History:

	??.??.2020 v1.00
	- first public release
	
*/

FileIn "io.ms";
FileIn "utils.ms";
FileIn "dbg.ms";
FileIn "sp2.ms";

SP2_MODEL_SKELETON_DATA_FILE_SIGNATURE = 0x24534B4C;
SP2_MODEL_SKELETON_DATA_FILE_RESOURCE_INFO_SIZE = 0x40;
SP2_MODEL_SKELETON_DATA_FILE_HEADER_SIZE = 12;
SP2_MODEL_SKELETON_DATA_FILE_BONE_SIZE = 0x80;

global g_sklConfigUseInverseBindPose = false;
global g_sklConfigConvertToZUP = true;
global g_sklConfigScale = 100;
global g_sklProfileTitle = undefined;
global g_sklProfileStartTime = 0;
global g_sklProfileEndTime = 0;

struct sklExpSkeletonInfo
(
	MaxDepth = -1,
	BoneInfo = #(),
	NameLookup = #()
)

struct sklExpBoneInfo
(
	MaxBone,
	Index,
	Depth,
	NameOffset,
	Next,
	NextDistance,
	LocalTransform,
	InvBindPoseMatrix
)

struct sklExpBoneNameLookup
(
	BoneName,
	Index
)

fn sklEndProfile =
(
	g_sklProfileEndTime = timeStamp();
	local delta = g_sklProfileEndTime - g_sklProfileStartTime;
	format "% took % s\n" g_sklProfileTitle (delta/1000.0);
)

fn sklBeginProfile title =
(
	if ( g_sklProfileTitle != undefined ) then
		sklEndProfile();
	
	g_sklProfileTitle = title;
	g_sklProfileStartTime = timeStamp();
)

fn sklImpTransformMatrix m =
(
	Sp2ImportTransformMatrix m g_sklConfigConvertToZUP g_sklConfigScale;
)

/*
Given tree:
- x
 - y
  - z
   - a
- b
Find the shortest distance between a & b
*/
fn sklExpCalcDistanceBetweenNodes a b =
(
	local dist;
	if ( a.Children.Count > 0 ) then
	(
		-- Always -1 for branches
		dist = -1;
	)
	else
	(
		local curNode = a.Parent;
		local found = false;
		dist = 0;
		while ( curNode != undefined ) do
		(
			for c in curNode.Children do
			(
				if ( c == b ) then
				(
					found = true;
					exit;
				)
			)
			
			if ( found ) then
			(
				exit;
			)
			else
			(
				dist += 1;
				curNode = curNode.Parent;
			)
		)
		
		dist;
	)
)

-- inverted z & y compared to sklImpTransformMatrix
fn sklExpTransformMatrix2 m =
(
	Sp2ExportTransformMatrix m g_sklConfigConvertToZUP g_sklConfigScale;
)

fn sklExpCalcSkeletonInfoRecursive sklInfo maxBone curDepth Depth =
(
	if ( curDepth > sklInfo.MaxDepth ) then
		sklInfo.MaxDepth = curDepth;
	
	local bInfo = sklExpBoneInfo();
	bInfo.MaxBone = maxBone;
	bInfo.Index = sklInfo.BoneInfo.Count;
	bInfo.Depth = curDepth + 1;
	bInfo.NextDistance = -1;
	
	local worldTfm = maxBone.Transform;	
	bInfo.InvBindPoseMatrix = inverse (sklExpTransformMatrix2 worldTfm);
	bInfo.LocalTransform = worldTfm;
	
	if ( maxBone.Parent != undefined ) then
	(
		-- Subtract parent's world transform from bone's transform
		bInfo.LocalTransform *= inverse ((maxBone.Parent.Transform));
	)
	
	bInfo.LocalTransform = sklExpTransformMatrix2 bInfo.LocalTransform;
	
	append sklInfo.BoneInfo bInfo;
	append sklInfo.NameLookup (sklExpBoneNameLookup BoneName:maxBone.Name Index:bInfo.Index)
	
	if ( bInfo.Index > 0 ) then
	(
		-- Link previous bone with current
		local prev = sklInfo.BoneInfo[(bInfo.Index - 1) + 1]
		prev.Next = bInfo;
		prev.NextDistance = sklExpCalcDistanceBetweenNodes prev.MaxBone bInfo.MaxBone;
	)
	
	for cb in maxBone.Children do
		sklExpCalcSkeletonInfoRecursive sklInfo cb (curDepth + 1) (bInfo.Index + 1);
)	

fn sklExpCalcSkeletonInfo maxRootBone =
(
	local sklInfo = sklExpSkeletonInfo();
	
	if (maxRootBone != undefined) then
	(
		sklExpCalcSkeletonInfoRecursive sklInfo maxRootBone -1 0
		
		-- Link last & first bone end-to-end
		local firstBInfo = sklInfo.BoneInfo[ 1 ];
		local lastBInfo = sklInfo.BoneInfo[ sklInfo.BoneInfo.Count ];
		lastBInfo.Next = firstBInfo;
		lastBInfo.NextDistance = sklExpCalcDistanceBetweenNodes lastBInfo.MaxBone firstBInfo.MaxBone;
	)
	
	sklInfo;
)

fn sklExpCompareNameLookup a b =
(
	if ( a.BoneName < b.BoneName ) then
	(
		-1
	)
	else if ( a.BoneName == b.BoneName ) then
	(
		0
	)
	else
	(
		1
	)
)

fn sklImportFromStream file fileName =
(
	sklBeginProfile("SKL Import");

	ioSetStream file fileName;
	
	-- Read Sp2ResourceItemFileHeader
	local sig = ioReadU32BE();
	if ( sig != SP2_MODEL_SKELETON_DATA_FILE_SIGNATURE ) then
		throw "Invalid SKL file (unexpected signature)";

	ioSeekCur( 8 ); -- DataSize, ResourceInfoSize
	local addHeaderCount = ioReadU8();
	ioSeekCur( 3 ); -- Unused
	
	-- Skip additional headers
	ioSeekCur( addHeaderCount * 16 );
	
	-- Read Sp2ModelSkeletonDataFileHeader
	local dataHeaderStart = ioTell();
	ioSeekCur( 4 ); -- unused
	local bonesOffset = ioReadU16LE();
	local boneCount = ioReadU16LE();
	ioSeekCur( 4 ); -- MaxDepth, NamesOffset
	
	-- Read Sp2ModelSkeletonDataFileBone list
	ioSeekSet( dataHeaderStart + bonesOffset );
	local maxBones = #();
	local boneOrigMtx = #();
	if ( boneCount > 0 ) then maxBones[boneCount] = undefined;
	
	for i = 1 to boneCount do
	(
		local nameOffset = ioReadU16LE();
		ioSeekCur( 3 ); -- unused
		local depth = ioReadS8();
		local nextDistance = ioReadS8();
		local type = ioReadS8();
		local localTfm = ioReadMtx43LE();
		local invBindPoseMatrix = ioReadMtx43LE();
		ioSeekCur( 24 ); -- WorldTransform, Min, Max
		
		-- Read bone name
		local tmp = ioTell();
		ioSeekSet( dataHeaderStart + nameOffset );
		local boneName = ioReadCString();
		ioSeekSet( tmp );

		-- Create bone
		local tfm;
		if ( g_sklConfigUseInverseBindPose ) then
		(
			tfm = (inverse invBindPoseMatrix);
		)
		else
		(
			tfm = localTfm;
		)
		
		local maxBone = BoneSys.createBone tfm.row4 (tfm.row4 + 0.01 * (normalize tfm.row1)) (normalize tfm.row3);
		maxBone.Name = boneName;
		maxBone.Width  = 0.01;
		maxBone.Height = 0.01;
		maxBone.Transform = tfm;
		maxBone.SetBoneEnable false 0;
		maxBone.Wirecolor = yellow;
		maxBone.Showlinks = true;
		maxBone.Pos.Controller      = TCB_position();
		maxBone.Rotation.Controller = TCB_rotation();
			
		if ( Depth > 0 ) then
		(
			local parentIdx = (depth - 1) + 1;
			maxBone.Parent = maxBones[ parentIdx];
			
			if ( not g_sklConfigUseInverseBindPose ) then
				maxBone.Transform *= boneOrigMtx[ parentIdx ];
		)
		
		boneOrigMtx[ depth + 1 ] = maxBone.Transform;
		maxBones[depth + 1] = maxBone;
		maxBone.Transform = sklImpTransformMatrix maxBone.Transform;
	)
	
	sklEndProfile();
)

fn sklImportFromFile filePath =
(
	local file = ioOpenFileRead( filePath );
	sklImportFromStream file filePath;
)

fn sklExportToStream file fileName =
(
	-- Collect data for export
	sklBeginProfile("SKL Export - Collecting scene data");
	local maxBones = for obj in objects where (classof obj == BoneGeometry) collect obj;
	local sklInfo = sklExpCalcSkeletonInfo maxBones[1];
	
	-- Start writing file
	sklBeginProfile("SKL Export - Writing file");
	ioSetStream file fileName;
	
	local fileStart = ioTell();
	local dataStart = fileStart + SP2_RESOURCE_ITEM_FILE_HEADER_SIZE;
	local bonesOffset = dataStart + SP2_MODEL_SKELETON_DATA_FILE_HEADER_SIZE;
	local namesOffset = bonesOffset + (maxBones.Count * SP2_MODEL_SKELETON_DATA_FILE_BONE_SIZE);
	
	-- Write bone names	
	ioSeekSet( namesOffset );
	ioWriteU8( 0 );
	qsort sklInfo.NameLookup sklExpCompareNameLookup;
	for i = 1 to sklInfo.NameLookup.Count do
	(
		sklInfo.BoneInfo[ sklInfo.NameLookup[i].Index + 1 ].NameOffset = ioTell();
		ioWriteCString( sklInfo.NameLookup[i].BoneName );
	)
	local fileEnd = ioTell();
	local fileSize = fileEnd - fileStart;

	-- Write bones (Sp2ModelSkeletonDataFileBone)
	ioSeekSet( bonesOffset );
	for i = 1 to sklInfo.BoneInfo.Count do
	(
		local bInfo = sklInfo.BoneInfo[i];
		ioWriteU16LE( bInfo.NameOffset - dataStart ); 
		ioWriteU16LE( 0 ); -- Field02, unused
		ioWriteU8( 0 ); -- Field04, unused
		ioWriteS8( bInfo.Depth );
		ioWriteS8( bInfo.NextDistance );
		ioWriteS8( 0 ); -- Type
		ioWriteMtx43LE( bInfo.LocalTransform );
		ioWriteMtx43LE( bInfo.InvBindPoseMatrix );
		ioWriteVec3LE( [-3.141593, 3.141593, -3.141593] ); -- always constant. min extents/flip rot in rads?
		ioWriteVec3LE( [3.141593, -3.141593, 3.141593] ); -- always constant. max extents/inverse flip rot?
	)
	
	-- Write data header (Sp2ModelSkeletonDataFileHeader)
	ioSeekSet( dataStart );
	ioWriteU32LE( 3 ); -- Field00, unused
	ioWriteU16LE( bonesOffset - dataStart ); -- BonesOffset
	ioWriteU16LE( maxBones.Count ); 
	ioWriteU16LE( sklInfo.MaxDepth + 1 );
	ioWriteU16LE( namesOffset - dataStart );

	-- Write header (Sp2ResourceItemFileHeader)
	ioSeekSet( fileStart );
	ioWriteU32BE( SP2_MODEL_SKELETON_DATA_FILE_SIGNATURE );
	ioWriteU32BE( fileSize - SP2_RESOURCE_ITEM_FILE_HEADER_SIZE );
	ioWriteU32BE( SP2_MODEL_SKELETON_DATA_FILE_RESOURCE_INFO_SIZE );
	ioWriteU8( 0 ); -- AdditionalHeaderCount
	ioWriteU8( 0 ); -- Field0D, unused
	ioWriteU8( 0 ); -- Field0E, unused
	ioWriteU8( 0 ); -- Field0F, unused
	
	-- Done
	ioSeekSet( fileEnd );
	ioWriteAlign( 16 );
	sklEndProfile();
)

fn sklExportToFile filePath =
(
	local file = ioOpenFileWrite( filePath );
	sklExportToStream file filePath;
	ioClose();
)

--sklImportFromFile "D:\work\jumpforce_anim\Samples\chr0000.skl"
--sklExportToFile "D:\work\jumpforce_anim\Samples\chr0000.exp.skl"
--sklImportFromFile "D:\work\jumpforce_anim\Samples\chr0000.exp.skl"
--sklImportFromFile "Nami.skl";
--sklExportToFile "test.skl";
--sklImportFromFile "test.skl";
--clearListener()
--dbgDumpBones();
