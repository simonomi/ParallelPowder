#ifndef Position_hpp
#define Position_hpp

// TODO: use u16s instead of ints? or i16s?
struct Position {
	int x;
	int y;
	
	Position(int inputX, int inputY);
	
#ifdef __METAL__
	Position(uint2 inputPosition);
#endif
	
	bool operator==(Position other);
	
	Position offsetBy(int8_t xOffset, int8_t yOffset);
};

#endif /* Position_hpp */
