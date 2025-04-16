#include "raylib.h"
#include <math.h>
#include <emscripten/emscripten.h>
#include <emscripten/html5.h>

float t = 0.0;

void main_loop(void) {
	t += GetFrameTime();
	if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
		emscripten_request_fullscreen("#canvas", 1);
	}
    BeginDrawing();
		ClearBackground(BLACK);
		DrawText(
			"bootycheeks",
			sin(t)*100+100,
			sin(t)*100+100, 100, DARKGRAY);
		DrawFPS(10, 10);
    EndDrawing();
}

int main(void) {
    InitWindow(800, 450, "Raylib Emscripten Example");
    SetTargetFPS(120);

    // Set up the main loop with Emscripten
    emscripten_set_main_loop(main_loop, 0, 1);

    // Note: CloseWindow() won't be reached due to the infinite loop
    // You can call it via emscripten_force_exit() if needed
    return 0;
}
