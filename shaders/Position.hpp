#ifndef Position_hpp
#define Position_hpp

struct Position {
	int16_t x;
	int16_t y;
	
	Position(int16_t inputX, int16_t inputY);
	
#ifdef __METAL__
	Position(uint2 inputPosition);
#endif
	
	bool operator==(Position other);
	
	Position offsetBy(int8_t xOffset, int8_t yOffset);
};

#endif /* Position_hpp */
