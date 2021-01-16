/*

Jump Force importer/exporter GUI for 3ds Max
Created:	06/11/2020
Author: 	Chris Weermann (aka TGE)
Web page:	https://github.com/TGEnigma, https://checkpoint.cc/tge
Credits:	
			alphaZomega - For helping me fix the animation export code
			jstpierre - Technical advice
			
Rivision History:

	??.??.2020 v1.00
	- first public release
*/

FileIn "include/controller.ms"

global g_jfController = JfController();
global g_jfFloater;
global g_jfRollouts = undefined;

fn jfHandleFileAction filePath action =
(
	local result = undefined;
	if ( filePath != undefined ) then
	(
		with redraw off
		(
			--try 
			( 
				result = action( filePath ); 
			) 
			--catch 
			(
				--utilHandleException();
			)
		)
	)
	
	result;
)

rollout jfInfoRollout "Jump Force Importer/Exporter"
(
	label lblVersion "Version 0.9 alpha" align:#center
	label lblAuthor "© 2020-2021 TGE" align:#center
)

rollout jfSettingsRollout "Settings"
(
	checkbox chkConvertToZUp "Convert to Z Up" checked:true align:#left;
	spinner spnScale "Scale" range:[0,1000000,100] align:#left;
	
	on chkConvertToZUp changed state do g_jfController.ConvertToZUp = state;
	on spnScale changed state do g_jfController.GlobalScale = state;
)

rollout jfSklRollout "Skeleton" width:162 height:300
(
	checkbox chkUseInvBindPose "Use Inverse Bind Pose" checked:false align:#left;
	button btnImport "Import" align:#center across:2;
	button btnExport "Export" align:#center;
	
	on chkUseInvBindPose changed state do g_jfController.UseInverseBindPose = state;
	
	on btnImport pressed do
	(
		local filePath = getOpenFileName \
			caption:"Open a skeleton file" \
			filename:"" \
			types:"Jump Force Skeleton Files (*.skl)|*.skl" \
			historyCategory: "JfSklImp";
		jfHandleFileAction filePath g_jfController.ImportSkl;
	)
	
	on btnExport pressed do
	(
		local filePath = getSaveFileName \
			caption:"Save a skeleton file" \
			filename:"" \
			types:"Jump Force Skeleton Files (*.skl)|*.skl" \
			historyCategory: "JfSklExp";
		jfHandleFileAction filePath g_jfController.ExportSkl;
	)
)

rollout jfAnmRollout "Animation" width:162 height:300
(
	spinner spnSpeed "Speed" range:[0,1000000,1] align:#left width:100;
	edittext edtName "Name";
	spinner spnCamFov "Base camera FOV" range:[0,1000000,45] align:#left width:100;
	label lblCamRot "Base camera rotation (Euler degrees)" align:#left;
	spinner spnCamRotX "" range:[0,1000000,90] width:50 across:3;
	spinner spnCamRotY "" range:[0,1000000,0] width:50;
	spinner spnCamRotZ "" range:[0,1000000,180] width:50;
	checkbox chkCreateDummies "Create dummies for missing objects" checked:true;
	
	button btnSaveBasePose "Save base pose" across:2;
	button btnLoadBasePose "Restore base pose" enabled:false;
	button btnImport "Import" align:#center across:2;
	button btnExport "Export" align:#center;
	
	on spnSpeed changed state do g_jfController.PlaybackSpeed = state;
	on spnCamFov changed state do g_jfController.DefaultCamFov = state;
	on spnCamRotX changed state do g_jfController.DefaultCamRot = EulerAngles spnCamRotX.value spnCamRotY.value spnCamRotZ.value;
	on spnCamRotY changed state do g_jfController.DefaultCamRot = EulerAngles spnCamRotX.value spnCamRotY.value spnCamRotZ.value;
	on spnCamRotZ changed state do g_jfController.DefaultCamRot = EulerAngles spnCamRotX.value spnCamRotY.value spnCamRotZ.value;
	on chkCreateDummies changed state do g_jfController.CreateDummies = state;
	
	on btnSaveBasePose pressed do
	(
		g_jfController.SaveBasePose();
		btnLoadBasePose.enabled = true;
	)
	
	on btnLoadBasePose pressed do
	(
		g_jfController.RestoreBasePose();
	)
	
	on btnImport pressed do
	(
		local filePath = getOpenFileName \
			caption:"Open an animation file" \
			filename:"" \
			types:"Jump Force Animation Files (*.san;*.anm)|*.san;*.anm" \
			historyCategory: "JfSanImp";
		
		if ( filePath != undefined ) then
		(
			local resourceFile = jfHandleFileAction filePath g_jfController.ImportSan;
			local animation = resourceFile.ResourceItems[1];
			local name = animation.ResourceItem.Data.Name;
			if ( name != undefined ) then
				edtName.text = name;
			
			btnLoadBasePose.enabled = true;
		)
	)
	
	on btnExport pressed do
	(
		local filePath = getSaveFileName \
			caption:"Save an animation file" \
			filename:"" \
			types:"Jump Force Animation Files (*.san)|*.san" \
			historyCategory: "JfSanExp";
		jfHandleFileAction filePath g_jfController.ExportSan;
	)
)

fn SetDefaults =
(
	-- Set JfController defaults to match UI defaults
	g_jfController.ConvertToZUp = true;
	g_jfController.GlobalScale = 100;
	g_jfController.UseInverseBindPose = false;
	g_jfController.PlaybackSpeed = 1;
	g_jfController.ResourceName = "";
	g_jfController.DefaultCamFov = 45;
	g_jfController.DefaultCamRot = EulerAngles 90 0 180;
	g_jfController.CreateDummies = true;
)

fn main =
(
	SetDefaults();
	
	-- adapted from ActorXImporter by Gildor
	-- request position of previous window, if it was already opened
	local x = 30;
	local y = 100;
	local w = 250;
	local h = 700;
	
	if ( g_jfFloater != undefined ) then
	(
		x = g_jfFloater.pos.x;
		y = g_jfFloater.pos.y;
		w = g_jfFloater.size.x;
		h = g_jfFloater.size.y;
		
		-- close old window
		closeRolloutFloater g_jfFloater;
	)
	-- Create plugin window
	g_jfFloater = newRolloutFloater "JF Plugin" w h x y -- create a new window

	-- init axRolloutList
	g_jfRollouts = #(jfInfoRollout, jfSettingsRollout, jfSklRollout, jfAnmRollout);

	-- add controls
	for i = 1 to g_jfRollouts.count do
	(
		addRollout g_jfRollouts[i] g_jfFloater;
	)
)

main();
