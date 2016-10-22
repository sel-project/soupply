module sul.types.specialint;

struct Special(T) if() {

	enum stringof = "special" ~ T.stringof;

}
