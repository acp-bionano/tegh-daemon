###Contents###
1. [Summary](#summary)
2. [Documentation](#docs)
    - [new Assembly(opts, cb)](#new)
    - [Assembly.components()](#components)
    - [Assembly.beforeDelete()](#beforeDelete)

###1. Summary###{#summary}

Multiple [Parts](http://acp-instiki.herokuapp.com/wiki/show/part.coffee) are represented by an Assembly.

Source: [assembly.coffee](https://github.com/acp-bionano/tegh-daemon/blob/tegh-daemon/lib/components/assembly.coffee)

***

###2. Docs for Class: Assembly###{#docs}

####new Assembly(opts, cb)#####{#new}
* `opts` Object - a container for Part attributes
* `cb` Function

The `opts` argument must consist of at least a `filePath` string pointing to an archive of ".stl" or ".gcode" files. Currently only the Zip archive format is supported.

####Assembly.components()#####{#components}

Returns an array of attributes belonging to all Parts in the Assembly.

####Assembly.beforeDelete()#####{#beforeDelete}

Removes listeners and temporary files and filepaths.

