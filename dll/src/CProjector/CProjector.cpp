// CProjector.cpp : Defines the exported functions for the DLL.
#include "pch.h" // use pch.h in Visual Studio 2019
#include <utility>
#include <limits.h>
#include <windows.h>
#include <iostream>
using namespace std;

#define EXPORT_FCNS
#include "shrhelp.h"
#include "CProjector.h"

#ifdef __cplusplus
extern "C" {
#endif

	// DLL internal state variables:
	static int horizontal[5];
	static int vertical[5];
	static int screenPosLeft[5];
	static int screenPosTop[5];
	static int NumDisp = 0;
	static int Disp;
	static int NumIm;
	static HWND window;
	static HDC hdc;
	static HDC* src;


	BOOL CALLBACK MonitorEnumProc(HMONITOR hMonitor,
		HDC      hdcMonitor,
		LPRECT   lprcMonitor,
		LPARAM   dwData)
	{
		MONITORINFO info;
		info.cbSize = sizeof(info);
		if (GetMonitorInfo(hMonitor, &info))
		{
			horizontal[NumDisp] = abs(info.rcMonitor.left - info.rcMonitor.right);
			vertical[NumDisp] = abs(info.rcMonitor.top - info.rcMonitor.bottom);
			screenPosLeft[NumDisp] = info.rcMonitor.left;
			screenPosTop[NumDisp] = info.rcMonitor.top;

			NumDisp++;
		}
		return TRUE;  // continue enumerating
	}


	// Inicializr pantalla y resolucion
	EXPORTED_FUNCTION void init(int D)
	{
		EnumDisplayMonitors(NULL, NULL, MonitorEnumProc, 0);

		/*cout << "NumDisp: " << NumDisp << endl;
		for (int i = 0; i < NumDisp; i++) {
			cout << "x: " << horizontal[i] << ", y: " << vertical[i] << endl;
			cout << "left: " << screenPosLeft[i] << ", top: " << screenPosTop[i] << endl;
		}*/

		window = GetActiveWindow();
		hdc = GetDC(window);
		if (D < (NumDisp + 1)) {
			Disp = D;
		}
		else {
			Disp = NumDisp;
		}
	}

	// Devuelve el numero de la pantalla
	EXPORTED_FUNCTION int retScrNum()
	{
		return NumDisp;
	}

	// Devuelve el valor de la resolucion
	EXPORTED_FUNCTION void retResolution(int* y, int* x, int* z)
	{
		*y = vertical[Disp - 1];
		*x = horizontal[Disp - 1];
		*z = 3;
		return;
	}

	// Reserva memoria para NumImag
	EXPORTED_FUNCTION void ImageMemo(int NumImag)
	{
		src = (HDC*)calloc(NumImag, sizeof(HDC));
		NumIm = NumImag;
	}

	// Carga las imagenes
	EXPORTED_FUNCTION void LoadGList(int Num, int* r, int* g, int* b)
	{
		//Rellenar la matriz
		COLORREF* arr = (COLORREF*)calloc(horizontal[Disp - 1] * vertical[Disp - 1], sizeof(COLORREF));
		for (int j = 0; j < horizontal[Disp - 1] * vertical[Disp - 1]; j++) {
			arr[j] = RGB(b[j], g[j], r[j]); // orden BGR
		}
		// Creating temp bitmap
		HBITMAP map = CreateBitmap(horizontal[Disp - 1], // width
			vertical[Disp - 1], // height
			1, // Color Planes, unfortanutelly don't know what is it actually. Let it be 1
			8 * 4, // Size of memory for one pixel in bits (in win32 4 bytes = 4*8 bits)
			(void*)arr); // pointer to array
// Temp HDC to copy picture
		src[Num - 1] = CreateCompatibleDC(hdc); // hdc - Device context for window, I've got earlier with GetDC(hWnd) or GetDC(NULL);
		SelectObject(src[Num - 1], map); // Inserting picture into our temp HDC
	}

	// Pinta la imagen de referencia n
	EXPORTED_FUNCTION void display(int n)
	{
		// Copy image from temp HDC to window
		BitBlt(hdc, // Destination
			screenPosLeft[Disp - 1],  // x and
			screenPosTop[Disp - 1],  // y - upper-left corner of place, where we'd like to copy
			horizontal[Disp - 1], // width of the region
			horizontal[Disp - 1], // height
			src[n - 1], // source
			0,   // x and
			0,   // y of upper left corner  of part of the source, from where we'd like to copy
			SRCCOPY); // Defined DWORD to juct copy pixels. Watch more on msdn;
	}

	// Pinta la ventana de un color
	EXPORTED_FUNCTION void displayRGB(int r, int g, int b)
	{
		//Rellenar la matriz
		COLORREF* ar = (COLORREF*)calloc(horizontal[Disp - 1] * vertical[Disp - 1], sizeof(COLORREF));
		for (int j = 0; j < horizontal[Disp - 1] * vertical[Disp - 1]; j++) {
			ar[j] = RGB(b, g, r); // orden BGR
		}
		// Creating temp bitmap
		HBITMAP map = CreateBitmap(horizontal[Disp - 1], // width
			vertical[Disp - 1], // height
			1, // Color Planes, unfortanutelly don't know what is it actually. Let it be 1
			8 * 4, // Size of memory for one pixel in bits (in win32 4 bytes = 4*8 bits)
			(void*)ar); // pointer to array
// Temp HDC to copy picture
		HDC srcRGB = CreateCompatibleDC(hdc); // hdc - Device context for window, I've got earlier with GetDC(hWnd) or GetDC(NULL);
		SelectObject(srcRGB, map); // Inserting picture into our temp HDC

		// Copy image from temp HDC to window
		BitBlt(hdc, // Destination
			screenPosLeft[Disp - 1],  // x and
			screenPosTop[Disp - 1],  // y - upper-left corner of place, where we'd like to copy
			horizontal[Disp - 1], // width of the region
			horizontal[Disp - 1], // height
			srcRGB, // source
			0,   // x and
			0,   // y of upper left corner  of part of the source, from where we'd like to copy
			SRCCOPY); // Defined DWORD to juct copy pixels. Watch more on msdn;
	}

	// Elimina la pantalla
	EXPORTED_FUNCTION void dele()
	{

		for (int j = 0; j < NumIm; j++) {
			DeleteDC(src[j - 1]); // Deleting temp HDC
		}
	}

	// Pinta test
	EXPORTED_FUNCTION void plot()
	{
		int yres = vertical[Disp - 1];
		int xres = horizontal[Disp - 1];
		bool exit = false;

		//*****BLANCO************************************
		COLORREF* arr = (COLORREF*)calloc(xres * yres, sizeof(COLORREF));
		for (int j = 0; j < xres * yres; j++) {
			if ((j % horizontal[Disp - 1]) < (horizontal[Disp - 1] / 2)) {
				arr[j] = RGB(255, 255, 255); // orden BGR
			}
			else {
				arr[j] = RGB(0, 0, 0); // orden BGR
			}
		}
		// Creating temp bitmap
		HBITMAP map = CreateBitmap(xres, // width
			yres, // height
			1, // Color Planes, unfortanutelly don't know what is it actually. Let it be 1
			8 * 4, // Size of memory for one pixel in bits (in win32 4 bytes = 4*8 bits)
			(void*)arr); // pointer to array
// Temp HDC to copy picture
		HDC src = CreateCompatibleDC(hdc); // hdc - Device context for window, I've got earlier with GetDC(hWnd) or GetDC(NULL);
		SelectObject(src, map); // Inserting picture into our temp HDC

		//*****DISPAY************************************
		//while (exit == false) {
			// Copy image from temp HDC to window
		BitBlt(hdc, // Destination
			screenPosLeft[Disp - 1],  // x and
			screenPosTop[Disp - 1],  // y - upper-left corner of place, where we'd like to copy
			xres, // width of the region
			yres, // height
			src, // source
			0,   // x and
			0,   // y of upper left corner  of part of the source, from where we'd like to copy
			SRCCOPY); // Defined DWORD to juct copy pixels. Watch more on msdn;
		//Sleep(17);

	/*	if (GetAsyncKeyState(VK_ESCAPE))
		{
			exit = true;
		}
	}*/

	//DeleteDC(src); // Deleting temp HDC
	}

#ifdef __cplusplus
}
#endif