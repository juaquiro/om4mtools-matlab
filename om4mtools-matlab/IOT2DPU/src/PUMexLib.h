/* 
 * PUMex.h
 *
 * Copyright 2016 IOT.
 */

#ifndef PUMEXLIB_H
#define PUMEXLIB_H

#ifdef _WIN32
#ifdef EXPORT_FCNS
#define EXPORTED_FUNCTION __declspec(dllexport)
#else
#define EXPORTED_FUNCTION __declspec(dllimport)
#endif
#else
#define EXPORTED_FUNCTION
#endif

#include <mex.h> 

EXPORTED_FUNCTION void PUFlynMdMex(mxArray *pw, mxArray *mask, mxArray *pcorr, mxArray *u, int thresh_flag, int fatten);

#endif
