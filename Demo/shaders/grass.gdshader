shader_type canvas_item;

uniform float y_start:hint_range(0.0, 1.0, 0.01);
uniform float speed:hint_range(0.1, 5.0, 0.1) = 1.0;
uniform float range:hint_range(0.1, 5.0, 0.1) = 1.0;

void vertex(){
	if((1.0-y_start)>UV.y){
		VERTEX.x += sin(TIME*speed)*(1.0-UV.y)*range;
	}
}