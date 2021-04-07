//
//  LambdaBuilder.h
//  DataFrame
//
//  Created by RedPanda on 2-Jul-20.
//  Copyright © 2020 strictlyswift. All rights reserved.
//

#ifndef LambdaBuilder_h
#define LambdaBuilder_h

#include <stdio.h>
#include <Python/Python.h>
int initialisePythonLibrary(void* libraryHandle);

long int parseArgsToLongInt(PyObject *args, long int *error);
char* parseArgsToString(PyObject *args, long int *error);
PyObject* parseArgsToObject(PyObject *args, long int *error);
double parseArgsToDouble(PyObject *args, long int *error);
PyObject* parseArgsToObjectPair(PyObject *args, PyObject **objectB, long int *error);
PyObject* parseArgsToObjectTriple(PyObject *args, PyObject **objectB, PyObject **objectC,  long int *error);

PyObject* wrapLongInt(long int value);
PyObject* wrapString(const char* value);
PyObject* wrapObject(PyObject* value);
PyObject* wrapDouble(double value);
PyObject* wrapBool(long int value);

// Shims for useful Python library functions
//PyCFunction copyPyCFnPtr(PyCFunction p);
//PyObject* createModuleFunc(PyMethodDef* methodDef, const char* name);
const char* stringFromPythonObject(PyObject* p);
PyObject * getPyUnicode_FromString (const char *u);
PyObject* createPyCFunction(PyMethodDef* ml, PyObject* data);

PyObject* executePythonCode(const char* code, int start, PyObject* globals, PyObject* locals, int showErrors);
PyObject* getPythonExecutionGlobals();
void setItemInGlobalDictionary(const char* key, PyObject* value);
PyObject*  getItemFromGlobalDictionary(const char* key);

void debug_showAddress(const char* varName, void* value);
PyObject* getAttrString(PyObject* obj, const char* attr);
int setAttrString(PyObject* obj, const char* attr, PyObject* value);
void printErrors();
PyObject* getModule(const char* name);
int runInteractiveOne(FILE* fp, const char* filename);
PyObject* compileString(const char* code, const char* name, int start);
void clearErrors();
PyObject* errorRaised(void);
void executeOnMain(const char* code);

#endif /* LambdaBuilder_h */
