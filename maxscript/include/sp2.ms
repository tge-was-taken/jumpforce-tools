/*

Jump Force SP2 resource IO library for 3ds Max
Created:	05/01/2021
Author: 	Chris Weermann (aka TGE)
Web page:	https://github.com/TGEnigma, https://checkpoint.cc/tge
Rivision History:

	??.??.2020 v1.00
	- first public release
	
*/

FileIn "io.ms";
FileIn "utils.ms";
FileIn "dbg.ms";

SP2_RESOURCE_FILE_HEADER_SIGNATURE = 0x24434648;
SP2_RESOURCE_FILE_TERMINATOR_HEADER_SIGNATURE = 0x24435430;
SP2_RESOURCE_ITEM_FILE_HEADER_SIGNATURE = 0x24525349;
SP2_RESOURCE_ITEM_FILE_HEADER_SIZE = 16;

struct Sp2ResourceFileChunkHeader
(
    Signature = 0,
    DataSize = 0,
    ResourceItemSize = 0,
    AdditionalHeaderCount = 0,
    Field0D = 0,
    Field0E = 0,
    Field0F = 0,

    fn Read ctx =
    (
        Signature = ioReadU32BE();
        DataSize = ioReadU32BE();
        ResourceItemSize = ioReadU32BE();
        AdditionalHeaderCount = ioReadU8();
        Field0D = ioReadU8();
        Field0E = ioReadU8();
        Field0F = ioReadU8();
    ),

    fn Write ctx = 
    (
        ioWriteU32BE( Signature );
        ioWriteU32BE( DataSize );
        ioWriteU32BE( ResourceItemSize );
        ioWriteU8( AdditionalHeaderCount );
        ioWriteU8( Field0D );
        ioWriteU8( Field0E );
        ioWriteU8( Field0F );
    )
)

struct Sp2ResourceItemFileHeader
(
    Field00 = 0xFF0506,
    StringCount = 0,
    RelocationCount = 0,
    StringTableOffset = 0,
    RelocationTableOffset = 0,
    NameOffset = 0,
	--
	Name,

    fn Read ctx =
    (
		ctx.PushBaseOffset( ioTell() );
        Field00 = ioReadU32LE();
        StringCount = ioReadU16LE();
        RelocationCount = ioReadU16LE();
        StringTableOffset = ioReadU16LE();
        RelocationTableOffset = ioReadU16LE();
        NameOffset = ioReadU32LE();
		
		if ( NameOffset > 0 ) then
		(
			ioSeekSet( ctx.BaseOffset + NameOffset );
			Name = ioReadCString();
		)
		
		Assert( Field00 == 0xFF0506 ) options:#(#dialog);
		Assert( StringCount == 0 ) options:#(#dialog);
		Assert( RelocationCount == 0 ) options:#(#dialog);
		
		ctx.PopBaseOffset();
    ),
	
	fn BeginWrite ctx =
	(
		ctx.PushBaseOffset();
		
		if ( Name != undefined ) then
		(
			NameOffset = 16;
		)
		
		-- TODO
	),
	
	fn EndWrite ctx =
	(
        ioWriteU32LE( Field00 );
        ioWriteU16LE( StringCount );
        ioWriteU16LE( RelocationCount );
        ioWriteU16LE( StringTableOffset );
        ioWriteU16LE( RelocationTableOffset );
        ioWriteU32LE( NameOffset );
		
		if ( NameOffset > 0 ) then
		(
			ioSeekSet( ctx.BaseOffset + NameOffset );
			ioWriteCString( Name );
		)
		
		ctx.PopBaseOffset();
	),
	
	fn Write ctx =
	(
		BeginWrite ctx;
		EndWrite ctx;
	)
)

struct Sp2ResourceItem
(
    Header = Sp2ResourceFileChunkHeader Signature:SP2_RESOURCE_ITEM_FILE_HEADER_SIGNATURE,
    Data = Sp2ResourceItemFileHeader(),
	Footer = Sp2ResourceFileChunkHeader Signature:SP2_RESOURCE_FILE_TERMINATOR_HEADER_SIGNATURE,

    fn Read ctx =
    (
        local p = ioTell();
        Header.Read( ctx );
        local pEnd = ioTell();
		
        ioSeekSet( p + (1 + Header.AdditionalHeaderCount) * 16 );
        Data.Read( ctx );
        ioSeekSet( ioAlign (pEnd + Header.DataSize) 16 );
		Footer.Read( ctx );
    ),
	
	fn Write ctx =
	(
		ctx.BeginWriteChunk Header true undefined;
		ioSeekSet( ctx.BaseOffset + (1 + Header.AdditionalHeaderCount) * 16 );
		Data.Write ctx;
		ctx.EndWriteChunk(); 
		
		ctx.BeginWriteChunk Footer false undefined;
		ctx.EndWriteChunk();
	)
)

struct Sp2UnknownResourceItem 
(
	Header = Sp2ResourceFileChunkHeader(),
	ResourceItem = Sp2ResourceItem(),
	
    fn Read ctx =
    (
        Header = ctx.Header;
		local pEnd = ioTell();

        ioSeekSet( ctx.BaseOffset + (1 + Header.AdditionalHeaderCount) * 16 );

        if ( Header.ResourceItemSize > 0 ) then
        (
            local next = ioTell();
            ioSeekSet( ioAlign (pEnd + Header.DataSize) 16 );
            ResourceItem.Read ctx;
        )
    )
)

struct Sp2ResourceFile
(
    Header = Sp2ResourceFileChunkHeader Signature:SP2_RESOURCE_FILE_HEADER_SIGNATURE Field0F:1,
    ResourceItems = #(),
	Footer = Sp2ResourceFileChunkHeader Signature:SP2_RESOURCE_FILE_TERMINATOR_HEADER_SIGNATURE,

    fn Read ctx =
    (
        Header.Read( ctx );
        Assert( Header.Signature == SP2_RESOURCE_FILE_HEADER_SIGNATURE );

        ctx.BeginReadChunk();
        local resourceItem = undefined;

        while ( ctx.Header.Signature != SP2_RESOURCE_FILE_TERMINATOR_HEADER_SIGNATURE ) do
        (
            case ( ctx.Header.Signature ) of
            (
                SP2_MODEL_ANIMATION_DATA_HEADER_SIGNATURE: resourceItem = Sp2ModelAnimationData();
                default: resourceItem = Sp2UnknownResourceItem();
            )

            resourceItem.Read ctx;
            append ResourceItems resourceItem;
			
			ioSeekSet( ctx.NextItemOffset );
			ctx.EndReadChunk();
			ctx.BeginReadChunk();
        )
		
		Footer = ctx.Header;
    ),
	
	fn Write ctx =
	(
		-- Write header
		ctx.BeginWriteChunk (Sp2ResourceFileChunkHeader Signature:SP2_RESOURCE_FILE_HEADER_SIGNATURE Field0F:1) false undefined;
		ctx.EndWriteChunk();
		
		for resourceItem in ResourceItems do
			resourceItem.Write ctx;
		
		-- Write footer
		ctx.BeginWriteChunk (Sp2ResourceFileChunkHeader Signature:SP2_RESOURCE_FILE_TERMINATOR_HEADER_SIGNATURE) false undefined;
		ctx.EndWriteChunk();
	)
)

fn Sp2ImportTransformTranslation t convertToZUp scl =
(
	local nt = copy t;
	
	if ( convertToZUp ) then
	(
		-- X -> -X
		-- Y -> -Z
		-- Z -> Y
		nt.x = -t.x;
		nt.y = -t.z;
		nt.z = t.y;
	)
	
	nt *= scl;
	nt;
)

fn quatDot left right =
(
	left.x * right.x + left.y * right.y + left.z * right.z + left.w * right.w;
)

fn Sp2ImportTransformRotation pr r convertToZUp =
(
	local nr = copy r;
	if ( convertToZUp ) then
	(
		--			game	max
		-- right    +x		+x
		-- up		-y		+z
		-- forward	+z		+y
		--nr = r * matrix3 [1, 0, 0, 0] [0, 0, -1, 0] [0, 1, 0, 0] [0, 0, 0, 1];
		--nr = quat r.x r.z -r.y r.w;
		
		local aa = r as angleaxis;
		local newAA = angleaxis aa.angle [aa.axis.x, aa.axis.z, -aa.axis.y];
		nr = newAA as quat;
-- 		if ( pr != undefined ) then
-- 		(
-- 			if ( ( r.z < 0 and nr.z > 0 ) or ( r.z < 0 and nr.z > 0 ) ) then nr = inverse nr;
-- 			
-- 			
-- 			--if ( abs( ( nr as euler ).x ) == abs( ( r as euler ) ).x 
-- 			--	 nr.x != r.x ) then
-- 			
-- 			local diff = pr * inverse nr;
-- 			if ( not ( close_enough ( nr as EulerAngles ).x ( r as EulerAngles ).x 100000 ) ) then
-- 			(
-- 				nr = inverse nr; 
-- 			)
-- 			
-- 			--if ( quatDot pr nr < 0.005 ) then nr = inverse nr; 
-- 			--if ( nr.angle > 90 and r.angle < 90 ) then nr = inverse nr;
-- 			--( abs ( nr.angle - pr.angle ) > 180 ) 
-- 		)
		
		--if ( ( nr.z < 0 and r.z > 0 ) or ( nr.z > 0 and r.z < 0) ) then nr = inverse nr;
	)
	
	nr;
)

fn Sp2ExportTransformRotation pr r convertToYUp =
(
	local nr = copy r;
	if ( convertToYUp ) then
	(
		--			max		game	
		-- right    +x		+x		
		-- up		+z		-y		
		-- forward	+y		+z		
		--nr = r * matrix3 [1, 0, 0, 0] [0, 0, 1, 0] [0, -1, 0, 0] [0, 0, 0, 1];
		--nr = quat r.x -r.z r.y r.w;
		
		local aa = r as angleaxis;
		local aa2 = angleaxis aa.angle [aa.axis.x, -aa.axis.z, aa.axis.y];
		nr = aa2 as quat;
		if ( pr != undefined ) then 
		(
			--if ( ( r.z < 0 and nr.z > 0 ) ) then nr = inverse nr;
			--if ( ( pr * conjugate nr ).w < 0.01 ) then nr = inverse nr; 
			
			--if ( nr.angle > 90 and r.angle < 90 ) then nr = inverse nr;
			
			--local diff = abs ( nr.angle - pr.angle );
			--print diff;
			
			--print "AAA";
			--nr = inverse nr;
		)
		
		--if ( ( nr.z < 0 and r.z > 0 ) or ( nr.z > 0 and r.z < 0) ) then nr = inverse nr;
	)
	
	nr
)

fn Sp2ImportTransformScale s convertToZUp =
(
	local ns = copy s;
	if ( convertToZUp ) then
	(
		-- scale is relative to 1
		-- so make sure to subtract it before flipping
		ns.x = (-(s.x - 1) + 1);
		ns.y = (-(s.z - 1) + 1);
		ns.z = s.y;
	)
	
	ns;
)

fn Sp2ImportTransformMatrix m convertToZUp scl =
(
	-- Decompose
	local t = m.translationpart;
	local r = m.rotationpart;
	local s = m.scalepart;
	
	t = Sp2ImportTransformTranslation t convertToZUp scl;
	r = Sp2ImportTransformRotation undefined r convertToZUp;
	s = Sp2ImportTransformScale s convertToZUp;
	
	m = r as matrix3;
	m.translation = t;
	m *= scalematrix s;
	m;
)

fn Sp2ExportTransformTranslation t convertToZUp scl =
(
	local nt = copy t;
	
	if ( convertToZUp ) then
	(
		nt.x = -t.x;
		nt.y = t.z; 
		nt.z = -t.y;
	)
	
	nt /= scl;
	nt;
)

fn Sp2ExportTransformScale s convertToYUp =
(
	local ns = copy s;
	
	if ( convertToYUp ) then
	(
		-- scale is relative to 1
		-- so make sure to subtract it before flipping
		ns.x = (-(s.x - 1) + 1);
		ns.y = ((s.z - 1) + 1);
		ns.z = (-(s.y - 1) + 1);
	)
	
	ns;
)

-- inverted z & y compared to Sp2ImportTransformMatrix
fn Sp2ExportTransformMatrix m convertToYUp scl =
(
	-- Decompose
	local t = m.translationpart;
	local r = m.rotationpart;
	local s = m.scalepart;
	
	t = Sp2ExportTransformTranslation t convertToYUp scl;
	r = Sp2ExportTransformRotation undefined r convertToYUp;
	s = Sp2ExportTransformScale s convertToYUp;
	
	m = r as matrix3;
	m.translation = t;
	m *= scalematrix s;
	m;
)

struct Sp2ReadContext
(
    BaseOffset = 0,
	BaseOffsetStack = #(0),
    BaseOffsetStackIdx = 2,
    Header = Sp2ResourceFileChunkHeader(),
	HeaderEndOffset = 0,
	NextItemOffset,
	
	fn PushBaseOffset bo =
	(
		BaseOffset = bo;
		BaseOffsetStack[BaseOffsetStackIdx] = bo;
		BaseOffsetStackIdx += 1;
	),
	
	fn PopBaseOffset =
	(
		BaseOffsetStackIdx -= 1;
		BaseOffset = BaseOffsetStack[BaseOffsetStackIdx];
	),
	
	fn BeginReadChunk =
	(
        PushBaseOffset( ioTell() );
        Header = Sp2ResourceFileChunkHeader();
        Header.Read( this );
		HeaderEndOffset = ioTell();
		NextItemOffset = (ioAlign (HeaderEndOffset + Header.DataSize) 16) + Header.ResourceItemSize;
	),
	
	fn EndReadChunk =
	(
		NextItemOffset = -1;
		HeaderEndOffset = -1;
		Header = undefined;
		PopBaseOffset();
	)
)

struct Sp2Stack
(
	Items = #(),
	ItemIdx = 0,
	
	fn PushValue val =
	(
		ItemIdx += 1;
		Items[ItemIdx] = val;
	),
	
	fn PopValue =
	(
		local val = Items[ItemIdx];
		ItemIdx -= 1;
		val;
	),
	
	fn PeekValue =
	(
		Items[ItemIdx];
	)
)

struct Sp2WriteChunkInfo
(
	Header,
	StartOffset,
	IncludeDataSize,
	RSI
)

struct Sp2WriteContext
(
    BaseOffsetStack = Sp2Stack(),
	BaseOffset,
	ChunkStack = Sp2Stack(),
	
	fn PushBaseOffset bo: =
	(
		if ( bo == unsupplied ) then bo = ioTell();
		BaseOffset = bo;
		BaseOffsetStack.PushValue bo;
	),
	
	fn PopBaseOffset =
	(
		BaseOffset = BaseOffsetStack.PopValue();
	),
	
	fn BeginWriteChunk hdr includeDataSize rsi =
	(
		PushBaseOffset();
		ChunkStack.PushValue ( Sp2WriteChunkInfo Header:hdr StartOffset:(ioTell()) \
			IncludeDataSize:includeDataSize RSI:rsi );
		ioWriteZeroFill 16;
	),
	
	fn EndWriteChunk =
	(
		local info = ChunkStack.PopValue();
		
		-- Write padding
		ioSeekEnd( 0 );
		local endOffset = ioTell();
		ioWriteAlign 16;
		local endOffsetAligned = ioTell();
		
		if ( info.IncludeDataSize ) then info.Header.DataSize = endOffset - info.StartOffset - 16;
		if ( info.RSI != undefined ) then 
		(
			-- Write RSI
			ioSeekSet( endOffsetAligned );
			info.RSI.Write this;
			local rsiEnd = ioTell();
			info.Header.ResourceItemSize = (rsiEnd - endOffsetAligned);
			endOffsetAligned += info.Header.ResourceItemSize;
		)
		
		-- Write header
		ioSeekSet( info.StartOffset );
		info.Header.Write ctx;
		
		-- Seek to end of data
		ioSeekSet( endOffsetAligned );
		PopBaseOffset();
	)
)
	

