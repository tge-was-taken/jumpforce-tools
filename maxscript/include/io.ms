global g_io_file = undefined
global g_io_filePath = undefined

fn ioSelectOpenFile caption filename types historyCategory =
(
	local filePath = getOpenFileName \
		caption:caption \
		filename:filename \
		types:types \
		historyCategory: historyCategory;
	filePath
)

fn ioSelectSaveFile caption filename types historyCategory =
(
	local filePath = getSaveFileName \
		caption:caption \
		filename:filename \
		types:types \
		historyCategory: historyCategory;
	filePath
)

fn ioOpenFileRead filePath =
(
	g_io_file = fopen filePath "rb";
	g_io_filePath = filePath;
	g_io_file;
)

fn ioOpenFileWrite filePath =
(
	g_io_file = fopen filePath "wb";
	g_io_filePath = filePath;
	g_io_file;
)

fn ioSetStream file fileName =
(
	g_io_file = file;
	g_io_filePath = fileName;
)

fn ioTell =
(
	FTell g_io_file
)

fn ioPrintTell =
(
	print("File offset: 0x" + (bit.intashex(ioTell()) as string))
)

fn ioAlign val align =
(
	bit.and (val + (align - 1)) (bit.not (align - 1))
)

fn ioSeekSet pos =
(
	FSeek g_io_file pos #seek_set
)

fn ioSeekCur pos =
(
	FSeek g_io_file pos #seek_cur
)

fn ioSeekEnd pos = 
(
	FSeek g_io_file pos #seek_end; 
)

fn ioClose =
(
	FClose g_io_file
)

-- Read functions

fn ioReadS8 =
(
	ReadByte g_io_file #signed
)

fn ioReadU8 =
(
	ReadByte g_io_file #unsigned
)

fn ioReadCString =
(
	ReadString g_io_file
)

-- Read functions (LE)

fn ioReadS16LE =
(
	ReadShort g_io_file #signed
)

fn ioReadU16LE =
(
	ReadShort g_io_file #unsigned
)

fn ioReadS32LE =
(
	ReadLong g_io_file #signed
)

fn ioReadU32LE =
(
	ReadLong g_io_file #unsigned
)

fn ioReadS64LE =
(
	ReadLongLong g_io_file #signed
)

fn ioReadU64LE =
(
	ReadLongLong g_io_file #unsigned
)

fn ioReadF32LE =
(
	ReadFloat g_io_file
)

fn ioReadVec2LE =
(
	[ (ReadFloat g_io_file), (ReadFloat g_io_file) ]
)

fn ioReadVec2LEAsVec3 z =
(
	[ (ReadFloat g_io_file), (ReadFloat g_io_file), z ]
)

fn ioReadVec3LE =
(
	[ (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file) ]
)

fn ioReadVec3LEAsVec4 w =
(
	[ (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file), w ]
)

fn ioReadVec4LE =
(
	[ (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file) ]
)

fn ioReadMtx43LE =
(
	matrix3 [ (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file) ] \
			[ (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file) ] \
			[ (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file) ] \
			[ (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file) ];
)

fn ioReadMtx44LE =
(
	matrix3 [ (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file) ] \
			[ (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file) ] \
			[ (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file) ] \
			[ (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file), (ReadFloat g_io_file) ];
)

fn ioReadQuatLE =
(
	quat (ReadFloat g_io_file) (ReadFloat g_io_file) (ReadFloat g_io_file) (ReadFloat g_io_file)
)

fn ioReadQuatNoWLE =
(
	quat (ReadFloat g_io_file) (ReadFloat g_io_file) (ReadFloat g_io_file) 1
)

-- Read functions (BE)

fn ioReadS16BE =
(
	bit.swapBytes ( ReadShort g_io_file #signed ) 1 2
)

fn ioReadU16BE =
(
	bit.swapBytes ( ReadShort g_io_file #unsigned ) 1 2
)

fn ioReadS32BE =
(
	bit.swapBytes ( bit.swapBytes ( ReadLong g_io_file #signed ) 1 4 ) 2 3
)

fn ioReadU32BE =
(
	bit.swapBytes ( bit.swapBytes ( ReadLong g_io_file #unsigned ) 1 4 ) 2 3
)

fn ioReadF32BE =
(
	bit.intAsFloat (bit.swapBytes (bit.swapBytes (ReadLong g_io_file #unsigned) 1 4) 2 3)
)

-- Write functions

fn ioWriteS8 val =
(
	WriteByte g_io_file val #signed
)

fn ioWriteU8 val =
(
	WriteByte g_io_file val #unsigned
)

fn ioWriteCString val =
(
	WriteString g_io_file val
)

-- Write functions (LE)
fn ioWriteS16LE val =
(
	WriteShort g_io_file val #signed
)

fn ioWriteU16LE val =
(
	WriteShort g_io_file val #unsigned
)

fn ioWriteS32LE val =
(
	WriteLong g_io_file val #signed
)

fn ioWriteU32LE val =
(
	WriteLong g_io_file val #unsigned
)

fn ioWriteS64LE val = 
(
	WriteLongLong g_io_file val #signed
)

fn ioWriteU64LE val = 
(
	WriteLongLong g_io_file val #unsigned
)

fn ioWriteF32LE val =
(
	WriteFloat g_io_file val
)

fn ioWriteVec2LE val =
(
	WriteFloat g_io_file val.X
	WriteFloat g_io_file val.Y
)

fn ioWriteVec3LE val =
(
	WriteFloat g_io_file val.X
	WriteFloat g_io_file val.Y
	WriteFloat g_io_file val.Z
)

fn ioWriteVec4LE val =
(
	WriteFloat g_io_file val.X
	WriteFloat g_io_file val.Y
	WriteFloat g_io_file val.Z
	WriteFloat g_io_file val.W
)

fn ioWriteMtx43LE val =
(
	WriteFloat g_io_file val.row1.X
	WriteFloat g_io_file val.row1.Y
	WriteFloat g_io_file val.row1.Z
	WriteFloat g_io_file val.row2.X
	WriteFloat g_io_file val.row2.Y
	WriteFloat g_io_file val.row2.Z
	WriteFloat g_io_file val.row3.X
	WriteFloat g_io_file val.row3.Y
	WriteFloat g_io_file val.row3.Z
	WriteFloat g_io_file val.row4.X
	WriteFloat g_io_file val.row4.Y
	WriteFloat g_io_file val.row4.Z
)

fn ioWriteMtx44LE =
(
	WriteFloat g_io_file val.row1.X
	WriteFloat g_io_file val.row1.Y
	WriteFloat g_io_file val.row1.Z
	WriteFloat g_io_file val.row1.W
	WriteFloat g_io_file val.row2.X
	WriteFloat g_io_file val.row2.Y
	WriteFloat g_io_file val.row2.Z
	WriteFloat g_io_file val.row2.W
	WriteFloat g_io_file val.row3.X
	WriteFloat g_io_file val.row3.Y
	WriteFloat g_io_file val.row3.Z
	WriteFloat g_io_file val.row3.W
	WriteFloat g_io_file val.row4.X
	WriteFloat g_io_file val.row4.Y
	WriteFloat g_io_file val.row4.Z
	WriteFloat g_io_file val.row4.W
)

fn ioWriteQuatLE val =
(
	WriteFloat g_io_file val.X
	WriteFloat g_io_file val.Y
	WriteFloat g_io_file val.Z
	WriteFloat g_io_file val.W
)

fn ioWriteQuatNoWLE val =
(
	WriteFloat g_io_file val.X
	WriteFloat g_io_file val.Y
	WriteFloat g_io_file val.Z
	WriteFloat g_io_file 1
)

-- Write functions (BE)

fn ioWriteS16BE val =
(
	WriteShort g_io_file (bit.swapBytes val 1 2) #signed
)

fn ioWriteU16BE val =
(
	WriteShort g_io_file (bit.swapBytes val 1 2) #unsigned
)

fn ioWriteS32BE val =
(
	WriteLong g_io_file (bit.swapBytes ( bit.swapBytes val 1 4 ) 2 3) #signed
)

fn ioWriteU32BE val =
(
	WriteLong g_io_file (bit.swapBytes ( bit.swapBytes val 1 4 ) 2 3) #unsigned
)

fn ioWriteF32BE val =
(
	WriteLong (bit.swapBytes (bit.swapBytes (bit.floatAsInt val) 1 4) 2 3) #unsigned
)

fn ioWriteAlign align =
(
	local alignedPos = ioAlign (ioTell()) align;
	while (ioTell() < alignedPos ) do
	(
		WriteByte g_io_file 0
	)
)

fn ioWriteZeroFill count =
(
	for i = 1 to count do WriteByte g_io_file 0;
)
