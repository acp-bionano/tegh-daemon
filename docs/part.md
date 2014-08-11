###Contents###
1. [Summary](#summary)
2. [Documentation](#docs)
    - [new Part(opts, cb)](#new)
    - [Part.components()](#components)
    - [Part.beforeDelete()](#beforeDelete)
    - [Part.needsSlicing()](#needsSlicing)
    - [Part.loadGCode(slicerOpts, [cb])](#loadGCode)

###1. Summary###{#summary}

A Part represents a single object that will be printed by a Printer. Multiple Parts can be represented by an [assembly](http://acp-instiki.herokuapp.com/wiki/show/assembly.coffee).

Link: [part.coffee](https://github.com/acp-bionano/tegh-daemon/blob/tegh-daemon/lib/components/part.coffee)

***

###2. Docs for Class: Part###{#docs}

####new Part(opts, cb)#####{#new}
* `opts` Object - a container for Part attributes
* `cb` Function

The `opts` argument must consist of at least a `filePath` string pointing to a .gcode or .stl file. Unless otherwise specified by the object, `opts` will be merged with several default attributes:
~~~
    qty: 1
    qtyPrinted: 0
    status: "idle"
    type: "part"
    assemblyId: null
    quality: "normal"
~~~

####Part.components()#####{#components}

Returns an array of Part attributes.

####Part.beforeDelete()#####{#beforeDelete}

Removes listeners and temporary files and filepaths.

####Part.needsSlicing()#####{#needsSlicing}

Returns the file path to the original Part .stl if it exists.

####Part.loadGCode(slicerOpts, [cb])#####{#loadGcode}
* `slicerOpts` Object
* `cb` Function, Optional

Slices a Part which has a `filePath` attribute ending in ".stl". Internally stores the corresponding ".gcode" file. By default, uses the Cura engine to slice unless otherwise specified by `slicerOpts`.

`slicerOpts` has the form:

~~~
printQualities:
      engine: "cura_engine"
      profile: "default"
      params: {layer_height: 5, infill: 20}
~~~