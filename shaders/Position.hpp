#ifndef Position_hpp
#define Position_hpp

struct Position {
	int x;
	int y;
	
	Position(int inputX, int inputY);
	
	Position(uint2 inputPosition);
	
	bool operator==(Position other);
	
	Position offsetBy(int xOffset, int yOffset);
};

#endif /* Position_hpp */
