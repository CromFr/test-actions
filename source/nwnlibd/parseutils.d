/// Internal parsing tools
module nwnlibd.parseutils;

import std.traits;
		import std.conv;

/// Converts a static char array to string.
/// The fixed char array may or may not be null terminated
auto ref string charArrayToString(T)(in T str) if(isSomeChar!(ForeachType!T)){
	import std.string: indexOf;
	auto i = str.indexOf('\0');
	if(i >= 0)
		return str[0 .. i].idup();
	return str[0 .. $].idup();
}

T stringToCharArray(T)(in string str) if(isStaticArray!T && isSomeChar!(ForeachType!T)){
	T ret;

	import std.algorithm: min;
	auto e = min(str.length, T.length);
	ret[0 .. e] = str[0 .. e];

	if(e < T.length)
		ret[e .. $] = 0;

	return ret;
}

// Escapes non printable characters from a string
string toSafeString(T)(in T str){
	import std.ascii;
	import std.format;
	string ret;
	foreach(c ; str){
		if(c.isPrintable)
			ret ~= c;
		else
			ret ~= format!"\\x%02x"(c);
	}
	return ret;
}



/// Formats a binary array to something readable
string dumpByteArray(in ubyte[] byteArray){
	import std.string: rightJustify;
	import std.conv: to;
	string ret;
	foreach(i ; 0..20){
		if(i==0)ret ~= "    / ";
		ret ~= i.to!string.rightJustify(4, '_');
	}
	ret ~= "\n";
	foreach(i ; 0..byteArray.length){
		auto ptr = byteArray.ptr + i;
		if(i%20==0)ret ~= (i/10).to!string.rightJustify(3)~" > ";
		ret ~= (*cast(ubyte*)ptr).to!string.rightJustify(4);
		if(i%20==19)ret ~= "\n";
	}
	ret ~= "\n";
	return ret;
}

/// Read a $(D ubyte[]) by chunks
struct ChunkReader{
	const ubyte[] data;
	size_t read_ptr = 0;

	@property size_t bytesLeft() const {
		return data.length - read_ptr;
	}

	ref T read(T)(){
		read_ptr += T.sizeof;
		return *cast(T*)(data.ptr+read_ptr-T.sizeof);
	}

	const(T[]) readArray(T=ubyte)(size_t length){
		read_ptr += length*T.sizeof;
		return cast(const(T[]))(data[read_ptr-length*T.sizeof .. read_ptr]);
	}

	T readPackedStruct(T)(){
		T ret;
		foreach(MEMBER ; FieldNameTuple!T)
			mixin("ret."~MEMBER~" = read!(typeof(ret."~MEMBER~"));");
		return ret;
	}

	const(T[]) peek(T=ubyte)(size_t length = 1){
		return cast(const(T[]))(data[read_ptr .. read_ptr + length * T.sizeof]);
	}
}


struct ChunkWriter{
	ubyte[] data;

	void put(T...)(in T chunks){
		static foreach(chunk ; chunks){
			static if(isArray!(typeof(chunk)))
				data ~= cast(ubyte[])chunk;
			else
				data ~= (cast(ubyte*)&chunk)[0..chunk.sizeof];
		}
	}
}