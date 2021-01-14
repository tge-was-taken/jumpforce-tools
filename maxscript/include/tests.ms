FileIn "san.ms";
FileIn "sp2.ms";
FileIn "controller.ms";

fn TestCompare expected actual =
(
	local result = ( expected == actual );
	if ( expected == actual ) then
	(
		format("Passed\n");
	)
	else
	(
		format("Failed\n");
	)
	
	result;
)

fn TestFormatAssertMessage expected actual =
(
	("Expected: " + (expected as string) + " Actual: " + (actual as string) + "\n");
)

fn TestDecompressRotation =
(
	format("TestDecompressRotation: ");
	local expected = quat 0.0051446129 -0.034348037 -0.56635368 0.82343018;
	local actual = Sp2ModelAnimationDataDecompressRotation (0x3197AA79C8480EE6L as Integer64);
	assert (TestCompare expected actual) message:(TestFormatAssertMessage expected actual);
)

fn TestDecompressRotation2 =
(
	format("TestDecompressRotation2: ");
	local expected = quat -0.081334 0.708529 0.038896 -0.699899;
	local actual = Sp2ModelAnimationDataDecompressRotation (0x1014E0870A77146EL as Integer64);
	assert (TestCompare expected actual) message:(TestFormatAssertMessage expected actual);
)

fn TestCompressRotation = 
(
	format("TestCompressRotation: ");
	local expected = 0x3197AA79C8480EE6L as Integer64;
	local actual = Sp2ModelAnimationDataCompressRotation (quat 0.0051446129 -0.034348037 -0.56635368 0.82343018);
	assert (TestCompare expected actual) message:(TestFormatAssertMessage expected actual);
)

fn TestCompressRotation2 =
(
	format("TestCompressRotation2: ");
	local expected = 0x1014E0870A77146EL as Integer64;
	local actual = Sp2ModelAnimationDataCompressRotation (quat -0.081334 0.708529 0.038896 -0.699899);
	assert (TestCompare expected actual) message:(TestFormatAssertMessage expected actual);
)

fn TestSanImportExport =
(
	format("TestSanImportExport: ");
	-- read Sp2ResourceFile
	ioOpenFileRead( @"D:\work\jumpforce_anim\Samples\chr0240_0100100_STD_LP.anm" );
	local resourceFile = Sp2ResourceFile();
	resourceFile.Read (Sp2ReadContext());
	
	-- write Sp2ResourceFile
	ioOpenFileWrite( @"D:\work\jumpforce_anim\Samples\test.san" );
	resourceFile.Write (Sp2WriteContext());
	assert (TestCompare true true) message:(TestFormatAssertMessage expected actual);
)

fn TestUpAxisConversion =
(
	format("TestUpAxisConversion: ");
	local original = quat -0.081334 0.708529 0.038896 -0.699899; -- y up
	local imported = quat -0.081334 0.0388959 -0.708528 0.699899; -- z up
	local exported = quat 0.081334 0.708529 -0.038897 0.699899; -- y up
	local imported2 = quat -0.081334 0.0388972 0.708528 0.699899; -- z up
	
	local controller = JfController();
	controller.ConvertToZUp = true;
	local newImported = controller.ConvertSp2RotationToControllerRotation original 0;
	local newExported = controller.ConvertControllerRotationToSp2Rotation newImported 0;
	local newImported2 = controller.ConvertSp2RotationToControllerRotation newExported 0;
	local newExported2 = controller.ConvertControllerRotationToSp2Rotation newImported2 0;
	
	assert (TestCompare original newExported) message:(TestFormatAssertMessage original newExported);
	assert (TestCompare newImported newImported2) message:(TestFormatAssertMessage newImported newImported2);
	assert (TestCompare original newExported2) message:(TestFormatAssertMessage original newExported2);
	
	-- Compress it
	local newImported3 = controller.ConvertSp2RotationToControllerRotation (Sp2ModelAnimationDataDecompressRotation (Sp2ModelAnimationDataCompressRotation newExported)) 0;
	local newExported3 = controller.ConvertControllerRotationToSp2Rotation newImported3 0;
	assert (TestCompare original newExported3) message:(TestFormatAssertMessage original newExported3);
	
	assert (TestCompare imported newImported) message:(TestFormatAssertMessage imported newImported);
	assert (TestCompare exported newExported) message:(TestFormatAssertMessage exported newExported);
)

fn RunTests =
(
	clearListener();
	TestDecompressRotation();
	TestDecompressRotation2();
	TestCompressRotation();
	TestCompressRotation2();
	--TestSanImportExport();
	TestUpAxisConversion();
	OK;
)

RunTests();