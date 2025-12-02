#ifndef Offset_hpp
#define Offset_hpp

enum struct Offset: uint8_t {
	upLeft, up, upRight,
	left, right,
	downLeft, down, downRight
};

int16_t xOffsetFor(Offset offset);
int16_t yOffsetFor(Offset offset);

#endif /* Offset_hpp */
