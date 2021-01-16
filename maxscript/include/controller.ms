FileIn "san.ms";
FileIn "skl.ms";

struct ObjectBasePose
(
	Object,
	Position,
	Rotation,
	Scale,
	Fov
)

struct JfController
(
	mObjBasePoses,
	
	-- Settings
	UseInverseBindPose = true,
	ConvertToZUp = true,
	GlobalScale = 100,
	PlaybackSpeed = 1,
	ResourceName,
	DefaultCamFov = 45,
	DefaultCamRot = EulerAngles 0 0 0,
	
	fn SecondsToFrames seconds fps =
	(
		local frames = abs ( seconds * fps );
		assert ( ( frames / fps ) == seconds ) message:("WARNING: Time value truncated: sec=" + (seconds as string) + " frame=" + (frames as string) + " fps=" + (fps as string));
		frames;
	),
	
	fn FramesToSeconds frames fps =
	(
		local seconds = frames * fps;
		seconds;
	),
	
	fn CleanBasePose =
	(
		for i = mObjBasePoses.count to 1 by -1 do
		(
			local bp = mObjBasePoses[i];
			if ( bp.Object != undefined and isDeleted bp.Object ) then
				deleteItem mObjBasePoses i;
		)
	),
	
	fn AddBasePose obj =
	(
		local fov = undefined;
		if ( superClassOf obj == camera ) then fov = obj.Fov;
		
		local basePose = (ObjectBasePose Object:obj Position:obj.Controller.Position \
			Rotation:obj.Controller.Rotation Scale:obj.Controller.Scale \
			Fov:fov);	
		append mObjBasePoses basePose;
		basePose;
	),
	
	fn SaveBasePose =
	(
		mObjBasePoses = #()
		for obj in objects do
		(
			AddBasePose obj;
		)
	),
	
	fn RestoreBasePose = 
	(
		CleanBasePose();
		
        for i = 1 to mObjBasePoses.Count do DeleteKeys mObjBasePoses[i].Object.Controller #allkeys
        for i = 1 to mObjBasePoses.Count do
        (
            local obj = mObjBasePoses[i].Object;
            obj.Controller.Position = mObjBasePoses[i].Position;
            obj.Controller.Rotation = mObjBasePoses[i].Rotation;
            obj.Controller.Scale = mObjBasePoses[i].Scale;
			if ( superClassOf obj == camera ) then obj.Fov = mObjBasePoses[i].Fov;
        )
	),
	
	fn GetBasePose obj =
	(
		CleanBasePose();
		
		for i = 1 to mObjBasePoses.Count do
		(
			if ( mObjBasePoses[i].Object.name == obj.name ) then return mObjBasePoses[i];
		)
		
		AddBasePose obj;
	),
	
	fn ConvertSp2RotationToControllerRotation rot t = (),
	
	fn ConvertControllerRotationToSp2Rotation prevCtrlRot ctrlRot t =
	(
		local rotTfm = inverse ctrlRot;
		local prevRotTfm = undefined;
		if ( prevCtrlRot != undefined ) then prevRotTfm = inverse prevCtrlRot;
		local rot = Sp2ExportTransformRotation prevRotTfm rotTfm ConvertToZUp;
		rot;
	),
	
	fn ConvertSp2RotationToControllerRotation prevRot rot t =
	(
 		local rotTfm = Sp2ImportTransformRotation prevRot rot ConvertToZUp;
 		local ctrlRot = inverse rotTfm;
 		ctrlRot;
	),
	
	fn ImportSanTrsController ctrl type =
	(
		local ctrlNode = getNodeByName ctrl.Name exact: true;
		if ( ctrlNode == undefined ) then
		(
			print("Creating dummy for " + ctrl.Name + " because it does not exist in the scene.");
			
			if ( type == #cam ) then
				ctrlNode = Freecamera name:ctrl.Name fov:DefaultCamFov nearclip:1 farclip:1000 nearrange:0 farrange:1000;
			else
				ctrlNode = dummy name:ctrl.Name;
			
			ctrlNode.Pos.Controller = TCB_position();
			ctrlNode.Rotation.Controller = TCB_rotation();
			ctrlNode.Scale.Controller = TCB_scale();
			AddBasePose ctrlNode;
		)
		
		--print ctrlNode.Name;
		local basePose = GetBasePose ctrlNode;
		local prevTranslation = undefined;
		for i = 1 to ctrl.TranslationKeyCount do
		(
			local translation = basePose.Position + ( Sp2ImportTransformTranslation ctrl.TranslationKeyValues[i] ConvertToZUp GlobalScale);
			at time (SecondsToFrames ctrl.TranslationKeyTimes[i] PlaybackSpeed)
				ctrlNode.Controller.Position = translation;
			
			prevTranslation = translation;
		)

		local prevRot = undefined;
		for i = 1 to ctrl.RotationKeyCount do
		(
			local t = (SecondsToFrames ctrl.RotationKeyTimes[i] PlaybackSpeed);
			local rot = ConvertSp2RotationToControllerRotation prevRot ctrl.RotationKeyValues[i] t;
			at time t
			(
				if ( type == #cam ) then
				(
					ctrlNode.Controller.Rotation = DefaultCamRot as quat * rot;	
				)
				else
				(
					ctrlNode.Controller.Rotation = rot;	
				)
			)
			
			prevRot = rot;
		)

		local prevScale = undefined;
		for i = 1 to ctrl.ScaleKeyCount do
		(
			local scl = Sp2ImportTransformScale ctrl.ScaleKeyValues[i] ConvertToZUp;;
			at time (SecondsToFrames ctrl.ScaleKeyTimes[i] PlaybackSpeed)
				ctrlNode.Controller.Scale = scl;
			prevScale = scl;
		)
		
		-- Add dummy keys for single frame animations so max doesn't delete them
		if ( ctrl.TranslationKeyCount == 1 ) then at time animationRange.end ctrlNode.Controller.Position = prevTranslation;
		if ( ctrl.RotationKeyCount == 1 ) then at time animationRange.end ctrlNode.Controller.Rotation = prevRot;
		if ( ctrl.ScaleKeyCount == 1 ) then at time animationRange.end ctrlNode.Controller.Scale = prevScale;
	),
	
	fn ImportSanCamFovController ctrl =
	(
		local ctrlNode = getNodeByName ctrl.Name exact: true;
		if ( ctrlNode == undefined ) then
		(
			print("Creating dummy for " + ctrl.Name + " because it does not exist in the scene.");
			ctrlNode = Freecamera name:ctrl.Name fov:DefaultCamFov nearclip:1 farclip:1000 nearrange:0 farrange:1000;
			ctrlNode.Pos.Controller = TCB_position();
			ctrlNode.Rotation.Controller = TCB_rotation();
			ctrlNode.Scale.Controller = TCB_scale();
			AddBasePose ctrlNode;
		)
		
		local basePose = GetBasePose ctrlNode;
		
		for i = 1 to ctrl.KeyCount do
		(
			at time (SecondsToFrames ctrl.KeyTimes[i] PlaybackSpeed)
				ctrlNode.Fov = basePose.Fov + ctrl.KeyValues[i];
		)
	),
	
	fn ImportSan filePath =
	(
		-- open file
		local fileStrm = ioOpenFileRead( filePath );
		ioSetStream fileStrm filePath;
		
		-- read Sp2ResourceFile
		local resourceFile = Sp2ResourceFile();
		resourceFile.Read (Sp2ReadContext());
		
		-- load Sp2ModelAnimationData
		local animation = resourceFile.ResourceItems[1].Data;
        local durationInFrames = SecondsToFrames animation.Duration PlaybackSpeed;
		
        animationRange = interval 0 durationInFrames;
		--frameRate =fps;
        format "Importing animation with % frames (% sec)\n" durationInFrames animation.Duration;
			
		if ( mObjBasePoses == undefined ) then
			SaveBasePose();

        with animate on
        (
            for ctrl in animation.BoneControllers do ImportSanTrsController ctrl #bone;
			for ctrl in animation.AttachControllers do ImportSanTrsController ctrl #attach;
			for ctrl in animation.CamControllers do ImportSanTrsController ctrl #cam;
			for ctrl in animation.UnkControllers do ImportSanTrsController ctrl #unk;
			for ctrl in animation.CamFovControllers do ImportSanCamFovController ctrl;
        )

		resourceFile;
	),
	
	fn CreateTrsController obj type =
	(
		local ctrl = Sp2ModelAnimationDataTrsController();
		ctrl.Name = obj.Name;
		
		local basePose = GetBasePose obj;
		for i = 1 to obj.Position.Controller.Keys.Count do
		(
			local keyTime = obj.Position.Controller.Keys[i].Time;
			at time keyTime
			(
				local translation = obj.Controller.Position - basePose.Position;
				append ctrl.TranslationKeyValues ( Sp2ExportTransformTranslation translation ConvertToZUp GlobalScale );
				append ctrl.TranslationKeyTimes keyTime;
			)
		)
		
		local prevRot = undefined;
		for i = 1 to obj.Rotation.Controller.Keys.Count do
		(
			local keyTime = obj.Rotation.Controller.Keys[i].Time;
			at time keyTime
			(
				local keyValue = obj.Controller.Rotation;
				if ( type == #cam ) then
				(
					keyValue = ( inverse ( DefaultCamRot as quat ) ) * keyValue;
				)
				
				append ctrl.RotationKeyValues (ConvertControllerRotationToSp2Rotation prevRot keyValue keyTime);
				append ctrl.RotationKeyTimes keyTime;
			)
			
			prevRot = obj.Controller.Rotation;
		)
		
		for i = 1 to obj.Scale.Controller.Keys.Count do
		(
			local keyTime = obj.Scale.Controller.Keys[i].Time;
			at time keyTime
			(
				append ctrl.ScaleKeyValues ( Sp2ExportTransformScale obj.Controller.Scale ConvertToZUp GlobalScale );
				append ctrl.ScaleKeyTimes keyTime;
			)
		)
				
		ctrl;
	),
	
	fn CreateCamFovController obj =
	(
		local ctrl = Sp2ModelAnimationDataCamFovController();
		ctrl.Name = obj.Name;
		ctrl.Field04 = 1;
		
		local basePose = GetBasePose obj;
		for i = 1 to obj.Fov.Controller.Keys.Count do
		(
			local t = obj.Fov.Controller.Keys[i].Time;
			at time t
			(
				append ctrl.KeyValues ( obj.Fov.Controller.Keys[i].Value - basePose.Fov );
				append ctrl.KeyTimes t;
			)
		)
		
		ctrl;
	),
	
	fn ExportSan filePath =
	(
		local fileStrm = ioOpenFileWrite( filePath );
		ioSetStream fileStrm filePath;
		
		-- create animation
		local mad = Sp2ModelAnimationData();
		mad.Data.Field00 = 4;
		mad.Data.Duration = FramesToSeconds animationRange.end PlaybackSpeed;
		local durationInFrames = SecondsToFrames mad.Data.Duration PlaybackSpeed;
		
        format "Exporting animation with % frames (% sec)\n" durationInFrames mad.Data.Duration;
		
		with animate on
		(
			for obj in objects do
			(
				if ( classOf obj == BoneGeometry or superClassOf obj == Helper ) then
				(
					append mad.Data.BoneControllers ( CreateTrsController obj #bone );
				)
				else if ( superClassOf obj == camera ) then
				(
					append mad.Data.CamControllers ( CreateTrsController obj #cam );
					append mad.Data.CamFovControllers ( CreateCamFovController obj );
				)	
			)
		)
		
		mad.ResourceItem.Data.Field00 = 0xFF0506;
		mad.ResourceItem.Data.Name = ResourceName;
		
		-- write Sp2ResourceFile

		local resourceFile = Sp2ResourceFile();
		append resourceFile.ResourceItems mad;
		resourceFile.Write (Sp2WriteContext());
			
		ioClose();
	),
	
	fn ImportSkl filePath =
	(
		g_sklConfigUseInverseBindPose = UseInverseBindPose;
		g_sklConfigConvertToZUP = ConvertToZUp;
		g_sklConfigScale = GlobalScale;
		sklImportFromFile filePath;
	),
	
	fn ExportSkl filePath =
	(
		g_sklConfigUseInverseBindPose = UseInverseBindPose;
		g_sklConfigConvertToZUP = ConvertToZUp;
		g_sklConfigScale = GlobalScale;
		sklExportToFile filePath;
	)
)