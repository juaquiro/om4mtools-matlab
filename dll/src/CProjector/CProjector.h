// CProyector.h - Contains declarations of math functions

#ifndef CProjector_h
#define CProjector_h
#include "shrhelp.h"
#include <limits.h>
#include <windows.h>

#ifdef __cplusplus
extern "C" {
#endif

	BOOL CALLBACK MonitorEnumProc(HMONITOR, HDC, LPRECT, LPARAM);

	// Inicializr pantalla y resolucion
	EXPORTED_FUNCTION void init(int);

	// Devuelve el numero de la pantalla
	EXPORTED_FUNCTION int retScrNum();

	// Devuelve el valor de la resolucion
	EXPORTED_FUNCTION void retResolution(int*, int*, int*);

	// Reserva memoria para NumImag
	EXPORTED_FUNCTION void ImageMemo(int);

	// Carga las imagenes
	EXPORTED_FUNCTION void LoadGList(int, int*, int*, int*);

	// Pinta la imagen de referencia n
	EXPORTED_FUNCTION void display(int);

	// Pinta la ventana de un color
	EXPORTED_FUNCTION void displayRGB(int, int, int);

	// Elimina la pantalla
	EXPORTED_FUNCTION void dele();

	// Pinta
	EXPORTED_FUNCTION void plot();

#ifdef __cplusplus
}
#endif

#endif
