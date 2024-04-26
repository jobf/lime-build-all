Builds all projects in a folder recursively to html5 and generates index pages for easy navigation.

By default it will ignore applications which are already built. This behaviour can be set with a command line argument.

## Example use


```
haxe --run BuildAll.hx ~/code/peote-playground ~/code/peote-playground-html
```

or to (re)build everything


```
haxe --run BuildAll.hx ~/code/peote-playground ~/code/peote-playground-html rebuild
```

You can get some extra debug info with e.g.


```
haxe --debug --run BuildAll.hx ~/code/peote-playground ~/code/peote-playground-html
```