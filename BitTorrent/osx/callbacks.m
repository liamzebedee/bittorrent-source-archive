//
//  callbacks.m
//  BitTorrent
//
//  Created by Dr. Burris T. Ewell on Tue Apr 30 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Python/Python.h>
#import "BTCallbacks.h"
#import "pystructs.h"

static PyObject *chooseFile(bt_ProxyObject *self, PyObject *args)
{
    NSAutoreleasePool *pool =[[NSAutoreleasePool alloc] init];
    char *def = "";
    long size;
    char *saveas = NULL;
    int dir;
    PyObject *res;
    NSString *str;

    if (!PyArg_ParseTuple(args, "slsi", &def, &size, &saveas, &dir))
	return NULL;
    
    Py_BEGIN_ALLOW_THREADS
    str = [self->dlController chooseFile:[NSString stringWithCString:def] size:size isDirectory:dir];
    Py_END_ALLOW_THREADS
    if(str) {
	res = PyString_FromString([str cString]);
    }
    else {
	Py_INCREF(Py_None);
	res = Py_None;
    }
    [pool release];
    return res;
}

static PyObject *display(bt_ProxyObject *self, PyObject *args, PyObject *keywds)
{
    float fractionDone = 0.0;
    float timeEst = 0.0;
    float upRate = 0.0;
    float downRate = 0.0;
    char *activity = "";
    NSAutoreleasePool *pool =[[NSAutoreleasePool alloc] init];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
	
    static char *kwlist[] = {"fractionDone", "timeEst", "upRate", "downRate", "activity", NULL};

     if (!PyArg_ParseTupleAndKeywords(args, keywds, "|ffffs", kwlist, 
					&fractionDone, &timeEst, &upRate, &downRate, &activity))
        return NULL;
	
    Py_BEGIN_ALLOW_THREADS
    [dict setObject:[NSNumber numberWithFloat:fractionDone] forKey:@"fractionDone"];
    [dict setObject:[NSNumber numberWithFloat:timeEst] forKey:@"timeEst"];
    [dict setObject:[NSNumber numberWithFloat:upRate] forKey:@"upRate"];
    [dict setObject:[NSNumber numberWithFloat:downRate] forKey:@"downRate"];
    [dict setObject:[NSString stringWithCString:activity] forKey:@"activity"];
    [self->dlController display:dict];
    [pool release];
    Py_END_ALLOW_THREADS
        
    Py_INCREF(Py_None);
    return Py_None;
}

static PyObject *finished(bt_ProxyObject *self, PyObject *args)
{
    NSAutoreleasePool *pool =[[NSAutoreleasePool alloc] init];

    Py_BEGIN_ALLOW_THREADS
    [self->dlController finished];
    Py_END_ALLOW_THREADS
    [pool release];
    Py_INCREF(Py_None);
    return Py_None;
}

static PyObject *nerror(bt_ProxyObject *self, PyObject *args)
{
    char *errmsg = NULL;
    char *BTerr = NULL;
    NSString *str;
    NSAutoreleasePool *pool =[[NSAutoreleasePool alloc] init];

    if(!PyArg_ParseTuple(args, "s", &BTerr, &errmsg))
	return NULL;
    if(errmsg)
	str = [NSString stringWithCString:errmsg];
    else
	str = [NSString stringWithCString:BTerr];

    Py_BEGIN_ALLOW_THREADS
    [self->dlController error:str];
    Py_END_ALLOW_THREADS
    [pool release];
    Py_INCREF(Py_None);
    return Py_None;
}


// first up is a PythonType to hold the proxy to the DL window

staticforward PyTypeObject bt_ProxyType;

static void bt_proxy_dealloc(bt_ProxyObject* self)
{
    [self->dlController release];
    PyObject_Del(self);
}

static struct PyMethodDef reg_methods[] = {
	{"display",	(PyCFunction)display, METH_VARARGS|METH_KEYWORDS},
	{"chooseFile",	(PyCFunction)chooseFile, METH_VARARGS},
	{"finished",	(PyCFunction)finished, METH_VARARGS},
	{"nerror",	(PyCFunction)nerror, METH_VARARGS},
	{NULL,		NULL}		/* sentinel */
};

static PyObject *proxy_getattr(PyObject *prox, char *name)
{
	return Py_FindMethod(reg_methods, prox, name);
}

static PyTypeObject bt_ProxyType = {
    PyObject_HEAD_INIT(NULL)
    0,
    "BT Proxy",
    sizeof(bt_ProxyObject),
    0,
    (destructor)bt_proxy_dealloc, /*tp_dealloc*/
    0,          /*tp_print*/
    proxy_getattr,          /*tp_getattr*/
    0,          /*tp_setattr*/
    0,          /*tp_compare*/
    0,          /*tp_repr*/
    0,          /*tp_as_number*/
    0,          /*tp_as_sequence*/
    0,          /*tp_as_mapping*/
    0,          /*tp_hash */
};

// given two ports, create a new proxy object
bt_ProxyObject *bt_getProxy(NSPort *receivePort, NSPort *sendPort)
{
    bt_ProxyObject *proxy;
    id foo;
    
    proxy = PyObject_New(bt_ProxyObject, &bt_ProxyType);
    foo = (id)[[NSConnection connectionWithReceivePort:receivePort
					sendPort:sendPort]
			    rootProxy];
    [foo setProtocolForProxy:@protocol(BTCallbacks)];
    [foo retain];
    proxy->dlController = foo;
    return (bt_ProxyObject *)proxy;
}
