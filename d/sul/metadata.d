module sul.metadata;

import sul.conversion;
import sul.json;

class MetadataValue {



}

class MetadataValueOf(T) : MetadataValue {

	public T value;

	alias value this;

}

struct MetadataStream {



}

// M is an enum with some metadata types
template Metadata(string game, size_t protocol, M) if(is(M == enum)) {

	static const Metadata = cast(JSONObject)UtilsJSON!("metadata", game, protocol);

}

/*

// sel
enum Metadatas {
	
	onFire,
	sneaking,
	...

}

// in an entity
struct Metadata {
	
	private Tuple!(bool, "pocket91", float, "pocket92", float, "minecraft210") onFire;
	private Tuple!(string, "pocket91") oldOne;

}

void trySetMetadata(Metadatas meta, T)(T value) {
	immutable name = meta.to!string;
	static if(is(typeof(mixin("Metadata." ~ name))) {
		// set every member
		@.pocket91 = value; // only if casts
		@.pocket92 = value; // only if casts
		@.minecraft210 = value;	// only if casts
	}
}

void convertMetadata(ref MetadataStream stream, void* metadata) {
	
}

struct Metadata {
	
	onFire = 0

}

*/
