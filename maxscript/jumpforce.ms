/*

Jump Force importer/exporter GUI for 3ds Max
Created:	06/11/2020
Author: 	Chris Weermann (aka TGE)
Web page:	https://github.com/TGEnigma, https://checkpoint.cc/tge
Rivision History:

	??.??.2020 v1.00
	- first public release
*/

FileIn "include/skl.ms"

rollout jfImpExpGUI "Jump Force skeleton/animation importer" width:391 height:425
(
	bitmap 'bmp1' "Bitmap" pos:[45,31] width:300 height:100 fileName:"logo.png" align:#left
	GroupBox 'grp1' "Skeleton" pos:[10,214] width:180 height:200 align:#left
	GroupBox 'grp2' "Animation" pos:[200,214] width:180 height:200 align:#left
	button 'btnSklImp' "Import" pos:[26,373] width:70 height:28 align:#left
	button 'btnSklExp' "Export" pos:[104,373] width:70 height:28 align:#left
	checkbutton 'chkSklInvBind' "Use Inverse Bind Pose" pos:[25,300] width:152 height:25 checked:false align:#left
	checkbutton 'chkSklZUp' "Convert to Z Up" pos:[25,264] width:152 height:25 enabled:true checked:true align:#left
	spinner 'spnSklScale' "Scale" pos:[25,237] width:125 height:16 range:[0,100000,1000] align:#left
	label 'lbl2' "Jump Force skeleton / animation importer v1.0 alpha" pos:[64,154] width:263 height:22 align:#left
	label 'lbl3' "by TGE" pos:[279,176] width:40 height:22 align:#left
	
	fn updateSklConfig =
	(
		g_sklConfigUseInverseBindPose = chkSklInvBind.checked;
		g_sklConfigConvertToZUP = chkSklZUp.checked;
		g_sklConfigScale = spnSklScale.value;
	)
	
	fn handleFileAction filePath action =
	(
		if ( filePath != undefined ) then
		(
			with redraw off
			(
				try 
				( 
					action( filePath ); 
				) 
				catch 
				(
					utilHandleException();
				)
			)
		)
	)
	
	on btnSklImp pressed do
	(
		updateSklConfig();
		local filePath = getOpenFileName \
			caption:"Open a SKL file" \
			filename:"test.skl" \
			types:"Jump Force Skeleton Files (*.skl)|*.skl" \
			historyCategory: "JfSklImp";
		handleFileAction filePath sklImportFromFile;
	)
	on btnSklExp pressed do
	(
		updateSklConfig();
		local filePath = getSaveFileName \
			caption:"Save a SKL file" \
			filename:"test.skl" \
			types:"Jump Force Skeleton Files (*.skl)|*.skl" \
			historyCategory: "JfSklExp";
		
		handleFileAction filePath sklExportToFile;
	)
)

CreateDialog jfImpExpGUI
