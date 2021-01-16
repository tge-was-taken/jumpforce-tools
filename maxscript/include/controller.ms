FileIn "san.ms";
FileIn "skl.ms";

struct ObjectBasePose
(
	Object,
	Position,
	Rotation,
	Scale,
	Fov,
	Visibility
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
	CreateDummies,
	
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
	
	fn GetVisibilityFloat obj =
	(
		local visibility = 1.0f;
		if ( classof obj.visibility == linear_float ) then
		(
			visibility = obj.visibility.controller.value;
		)
		else if ( classof obj.visibility == Booleanclass ) then
		(
			if ( obj.visibility ) then visibility = 1.0f;
			else visibility = 0.0f;
		)
		else
		(
			assert false message:("Unsupported visibility controller: "+obj as string+" type:"+(classof obj.visibility as string));
		)
		
		visibility;
	),
	
	fn AddBasePose obj =
	(
		-- Get FOV value if the obj is a camera
		local fov = DefaultCamFov;
		if ( superClassOf obj == camera ) then 
		(
			fov = obj.Fov;
		)
		
		-- Get visibility as float
		local visibility = GetVisibilityFloat obj;
		local basePose = (ObjectBasePose Object:obj Position:obj.Controller.Position \
			Rotation:obj.Controller.Rotation Scale:obj.Controller.Scale \
			Fov:fov Visibility:visibility);	
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
			local bp = mObjBasePoses[i];
            local obj = bp.Object;
            obj.Controller.Position = bp.Position;
            obj.Controller.Rotation = bp.Rotation;
            obj.Controller.Scale = bp.Scale;
			if ( superClassOf obj == camera ) then obj.Fov = bp.Fov;
			if ( classof obj.visibility == linear_float ) then obj.visibility.controller.value = bp.Visibility;
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
	
	fn ImportTrsController ctrl type =
	(
		local ctrlNode = getNodeByName ctrl.Name exact: true;
		if ( ctrlNode == undefined ) then
		(
			if ( type == #cam ) then
			(
				ctrlNode = Freecamera name:ctrl.Name fov:DefaultCamFov nearclip:1 farclip:1000 nearrange:0 farrange:1000;
			)
			else
			(
				if ( not CreateDummies ) then
				(
					print("Skipping " + ctrl.Name + " because it does not exist in the scene.");
					return ok; -- skip controller
				)
				
				ctrlNode = dummy name:ctrl.Name;
			)
			
			print("Created dummy for " + ctrl.Name + " because it does not exist in the scene.");
			ctrlNode.Pos.Controller = TCB_position();
			ctrlNode.Rotation.Controller = TCB_rotation();
			ctrlNode.Scale.Controller = TCB_scale();
			AddBasePose ctrlNode;
		)
		
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
	
	fn ImportCamFovController ctrl =
	(
		local ctrlNode = getNodeByName ctrl.Name exact: true;
		if ( ctrlNode == undefined ) then
		(			
			print("Creating dummy for " + ctrl.Name + " because it does not exist in the scene.");
			ctrlNode = Freecamera name:ctrl.Name fov:(radtodeg ctrl.BaseValue) nearclip:1 farclip:1000 nearrange:0 farrange:1000;
			ctrlNode.Pos.Controller = TCB_position();
			ctrlNode.Rotation.Controller = TCB_rotation();
			ctrlNode.Scale.Controller = TCB_scale();
			AddBasePose ctrlNode;
		)
		
		local basePose = GetBasePose ctrlNode;
		-- Update the base FOV here due to it being stored in the animation
		basePose.Fov = radtodeg ctrl.BaseValue;
		
		local prevValue = undefined;
		for i = 1 to ctrl.KeyCount do
		(
			at time (SecondsToFrames ctrl.KeyTimes[i] PlaybackSpeed)
			(
				ctrlNode.Fov = radtodeg ctrl.KeyValues[i];
				prevValue = ctrlNode.Fov; 
			)
		)
		
		if ( ctrl.KeyCount == 1 ) then at time animationRange.end ctrlNode.Fov = prevValue;
	),
	
	fn UpdateVisController obj baseValue =
	(
		if ( classof obj.Visibility != linear_float ) then
		(
			-- Add visibility controller 
			obj.Visibility = linear_float();
		)
		
		-- Set base visibility in controller
		obj.Visibility.Controller.Value = baseValue;
		
		-- Set base visibility in base pose
		local basePose = GetBasePose obj;
		basePose.Visibility = baseValue;
	),
	
	fn ImportVisController ctrl =
	(
		local ctrlNode = getNodeByName ctrl.Name exact: true;
		if ( ctrlNode == undefined ) then
		(			
			print("Creating dummy for " + ctrl.Name + " because it does not exist in the scene.");
			ctrlNode = dummy name:ctrl.Name;
		)
		
		-- Adds visibility controller if it doesnt exist, and updates it
		UpdateVisController ctrlNode ctrl.BaseValue;

		local prevValue = undefined;
		for i = 1 to ctrl.KeyCount do
		(
			at time (SecondsToFrames ctrl.KeyTimes[i] PlaybackSpeed)
			(
				ctrlNode.Visibility.Controller.Value = ctrl.KeyValues[i];
				prevValue = ctrlNode.Visibility.Controller.Value;
			)
		)
		
		if ( ctrl.KeyCount == 1 ) then at time animationRange.end ctrlNode.Visibility.Controller.Value = prevValue;
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
        format "Importing animation with % frames (% sec)\n" durationInFrames animation.Duration;
			
		if ( mObjBasePoses == undefined ) then
			SaveBasePose();

        with animate on
        (
            for ctrl in animation.BoneControllers do ImportTrsController ctrl #bone;
			for ctrl in animation.AttachControllers do ImportTrsController ctrl #attach;
			for ctrl in animation.CamControllers do ImportTrsController ctrl #cam;
			for ctrl in animation.UnkControllers do ImportTrsController ctrl #unk;
			for ctrl in animation.ExControllers do
			(
				case ctrl.SubType of
				(
					0: ImportVisController ctrl;
					1: ImportCamFovController ctrl;
				)
			)
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
				append ctrl.ScaleKeyValues ( Sp2ExportTransformScale obj.Controller.Scale ConvertToZUp );
				append ctrl.ScaleKeyTimes keyTime;
			)
		)
				
		ctrl;
	),
	
	fn CreateCamFovController obj =
	(
		local ctrl = Sp2ModelAnimationDataExController();
		ctrl.Name = obj.Name;
		ctrl.SubType = SP2_MODEL_ANIMATION_DATA_EX_CONTROLLER_TYPE_FOV;
		
		local basePose = GetBasePose obj;
		ctrl.BaseValue = degtorad basePose.Fov;
		
		for i = 1 to obj.Fov.Controller.Keys.Count do
		(
			local t = obj.Fov.Controller.Keys[i].Time;
			at time t
			(
				append ctrl.KeyValues ( degtorad obj.Fov.Controller.Keys[i].Value );
				append ctrl.KeyTimes t;
			)
		)
		
		ctrl;
	),
	
	fn CreateVisController obj =
	(
		local ctrl = Sp2ModelAnimationDataExController();
		ctrl.Name = obj.Name;
		ctrl.SubType = SP2_MODEL_ANIMATION_DATA_EX_CONTROLLER_TYPE_VIS;
		
		local basePose = GetBasePose obj;
		ctrl.BaseValue = basePose.Visibility;		
		for i = 1 to obj.Visibility.Controller.Keys.Count do
		(
			local t = obj.Visibility.Controller.Keys[i].Time;
			at time t
			(
				append ctrl.KeyValues ( obj.Visibility.Controller.Keys[i].Value );
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
				if ( ( findString obj.Name "|" ) == 1 ) then
				(
					-- special handling for external objs
					if ( superClassOf obj == camera ) then
					(
						append mad.Data.CamControllers ( CreateTrsController obj #cam );
						append mad.Data.ExControllers ( CreateCamFovController obj );
					)
					else
					(
						append mad.Data.AttachControllers ( CreateTrsController obj #attach );
						append mad.Data.ExControllers ( CreateVisController obj );
					)
				)
				else
				(
					-- generic case
					if ( classOf obj == BoneGeometry or superClassOf obj == Helper ) then
					(
						append mad.Data.BoneControllers ( CreateTrsController obj #bone );
					)
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