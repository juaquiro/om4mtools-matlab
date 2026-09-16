/* PUFlynMdMex.c
*
* Mexfile implementing the FlynMd PU method of 2DPU
* Copyright 2016 IOT.
*
*/

#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <mex.h>  
/*#include "windows.h"*/

#define EXPORT_FCNS
#include "PUMexLib.h"

#include <stdio.h>
#include <math.h>
#include "histo.h"
#include "maskfat.h"
#include "pi.h"
#include "util.h"
#include "extract.h"
#include "getqual.h"
#include "flynn.h"
#define BORDER  (0x20)


/* Mex Input Arguments */
#define	PHASE_IN	prhs[0] //phase
#define	MASK_IN		prhs[1] //mask
#define	QUAL_IN		prhs[2] //quality
#define	THR_FLAG	prhs[3] //threshold flag
#define	FATTEN_W    prhs[4] //fatten width

/* Mex Output Arguments */
#define	UNW_OUT	plhs[0]



//segun esta hecho PUFlynMdMex se puede compilar a un mex file (proyecto PUFlynMdMex) o como una DLL (ver proyecto PUMexLib)
//mxArray *phase_M, wrapped phase angle(phasor) 0-2pi
//mxArray *mask_M, ROI 0-255
//mxArray *qual_M, phase's quality or correlation abs(phasor) 0-1, this quality map shoud be input normalized, se 2DPU for several options in case there is no quality map from correlation
//mxArray *unw_M, unwrapped phase
EXPORTED_FUNCTION void PUFlynMdMex(
	const mxArray *phase_M, // wrapped phase angle(phasor) 0-2pi
	const mxArray *mask_M,  //ROI 0-255
	const mxArray *qual_M, //phase's quality or correlation abs(phasor) 0-1, this quality map shoud be input normalized, se 2DPU for several options in case there is no quality map from correlation
	mxArray *unw_M,  // unwrapped phase
	int thresh_flag, int fatten) //quality threshold and px width to fatten zero quality points
{
	float *phase; //input phase [0-2pi]
	float *qual;  //input quality data [0-1]
	double *d;  //temp pointer to MATLAB data
	double one_over_twopi = 1.0/TWOPI;
	int xsize, ysize;
	unsigned char  *bitflags;  /* array */
	short          *hjump;     /* array */
	short          *vjump;     /* array */
	int            *value;     /* array */
	int n, i, j;

	//**get size
	//from MATLAB data comes columnwise, so  mxGetM becomes NCols and mxGetN becomes NRows
	xsize = (int)mxGetM(phase_M); 
	ysize = (int)mxGetN(phase_M);

	//**reseve memory
	//floats to stores 
	AllocateFloat(&phase, xsize*ysize, "phase data");
	AllocateFloat(&qual, xsize*ysize, "quality map");

	AllocateByte(&bitflags, (xsize+1)*(ysize+1), "bitflags array");

	//**copy input MATLAB double data in local float data
	//read phase and normalize
	d=mxGetPr(phase_M); 
	for(n=0; n<xsize*ysize;n++) phase[n]=(float)d[n]*one_over_twopi;

	//read qual data
	d=mxGetPr(qual_M); 
	for(n=0; n<xsize*ysize; n++) 
		qual[n]=(float)d[n];

	//read bitflags and set points outsize xsize, ysize to BORDER
	d=mxGetPr(mask_M); 
	for(n=0; n<xsize*ysize;n++) bitflags[n]=(unsigned char)d[n];
	for (n=0; n<xsize*ysize; n++) bitflags[n] = (!bitflags[n]) ? BORDER : 0;

	//**condition data
	//fatten mask by one pixel
	FattenMask(bitflags, BORDER, 1, xsize, ysize);

	//threshold qual map and fatten zero qual pixels
	if (thresh_flag) {
		HistoAndThresh(qual, xsize, ysize, 0.0, 0, 0.0,
			bitflags, BORDER);
		if (fatten > 0)
			FattenQual(qual, fatten, xsize, ysize);
	}

	//embed bitflags array in larger array for use by Flynn's routines */
	for (j=ysize - 1; j>=0; j--) {
		for (i=xsize - 1; i>=0; i--) {
			bitflags[j*(xsize+1) + i] = bitflags[j*xsize + i];
		}
	}
	for (j=0; j<=ysize; j++) bitflags[j*(xsize + 1) + xsize] = 0;
	for (i=0; i<=xsize; i++) bitflags[ysize*(xsize + 1) + i] = 0;

	//**Unwrapp
	AllocateShort(&hjump, (xsize+1)*(ysize+1), "hjump array");
	AllocateShort(&vjump, (xsize+1)*(ysize+1), "vjump array");
	AllocateInt(&value, (xsize+1)*(ysize+1), "value array");

	FlynnMinDisc(phase, value, bitflags, qual, vjump, hjump,
		xsize, ysize);

	//**save result and scale back to 2*pi
	d=mxGetPr(unw_M); 
	for(n=0; n<xsize*ysize;n++) d[n]=(double)phase[n]*TWOPI;	

	//**free pointers
	free(phase);
	free(bitflags);
	free(qual);
	free(hjump);
	free(vjump);
	free(value);
}


void mexFunction( int nlhs, mxArray *plhs[], 
	int nrhs, const mxArray *prhs[] )

{ 
	int n, m;
	int *thresh_flag, *fatten;

	/* Check for proper number of arguments */    
	if (nrhs != 5) { 
		mexErrMsgIdAndTxt("MATLAB:PUFlynMdMex:minrhs",
			"five input arguments required.");
	} else if (nlhs > 1) {
		mexErrMsgIdAndTxt("MATLAB:PUFlynMdMex:maxrhs",
			"Too many output arguments.");
	} 

	/* get imput size */
	m = mxGetM(PHASE_IN); 
	n = mxGetN(PHASE_IN);


	/* Create a matrix for the return argument */ 
	UNW_OUT = mxCreateDoubleMatrix(m, n, mxREAL); 

	thresh_flag = (int *)mxGetData(THR_FLAG); 
    fatten = (int *)mxGetData(FATTEN_W);

	//Do Unwrapp
	PUFlynMdMex(PHASE_IN, MASK_IN, QUAL_IN,  UNW_OUT, *thresh_flag, *fatten);

	return;
}

