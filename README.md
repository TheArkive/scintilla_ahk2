# scintilla_ahk2
Scintilla class wrapper for AHK v2

## Scintilla.dll
Go to the Scintilla site to get the DLL.  [Here is the download page for SciTE.](https://www.scintilla.org/SciTEDownload.html)

Direct Links:

* [SciTE 64-bit](https://www.scintilla.org/wscite502.zip)
* [SciTE 32-bit](https://www.scintilla.org/wscite32_502.zip)

Pick your desired 32-bit or 64-bit version for download.  Unzip and copy over the `Scintilla.dll` from the unzipped folder into the same folder as the script.  You can of course place the DLL anywhere, but make sure you modify the class lib in `Static __New()` to point to the proper DLL location.

# Documentation

Making the documentation will be a lengthy work in progress...

Here are a few general guidelines:

* All numerical IDs are zero-based.  So position numbers, line numbers, column numbers, margin numbers, style numbers, selection numbers, etc., start at zero.
* I tried to keep all like categories of methods and properties together as they are listed on the Scintilla Documentation site, but this is not always the case.  Generally I'm just trying to keep concepts in logical categories (sub classes).  This is a bit of a process as I discover other functions, some of which serve a better purpose in a different category than originally listed in the Scintilla Docs.
* Not all Scintilla functions will make it into this library.  Basically, functions that appear to duplicate another function's result with little or no benefit won't be added, unless there is a good reason, in which case it may get a different name to more appropriately describe what it is best used for.

# Current Changes

Lots of additions
* added .wm_messages() callback per control created (attached to the Gui control obj)
* added SCNotification struct as a sub-class
* added callback property to Gui control object ... `callback(ctl, scn)`
* added several static objs for listing constants
* updated and tested offsets for SCNotification struct (13/22 offsets verified for x86 and x64)
* added a few more SCI_\* funcs
* moved some Scintilla control customizations out of main class into a func in the example
* Added .Lookup() and .GetFlags() static methods for easier interal workings

WM_NOTIFY callback

```
g := Gui()
ctl := g.AddScintilla(...)
ctl.callabck := my_func

my_func(ctl, scn) {
    ...
}
```

`ctl` is the Gui Control object, the Scintilla control.
`scn` is the SCNotification struct as a sub-class.

Members:

hwnd\
id\
wmmsg\
wmmsg_txt <-- added text name of wm_notify msg\
pos\
ch\
mod\
modType
text\
length\
linesAdded
message\
wParam\
lParam\
line\
foldLevelNow\
foldLevelPrev\
margin\
listType\
x\
y\
annotationLinesAdded\
updated\
listCompletionMethod\
characterSource

## Margins, Styles, EOL Annotations

For margins and styles, set the active "ID" like so:

```
obj.Style.ID := 34 ; make future calls to obj.Style.* apply to style #34

obj.Margin.ID := 2 ; make future calls to obj.Margin.* apply to margin #2

obj.EOLAnn.Line := 3 ; make future calls to obj.EOLAnn.* apply to line #3
```

I will probably continue to treat these types of functions this way for simplicity and consistency.  I find it to be working quite well in my tests, and I find it somewhat improves the readability of the code as well.

## To-Do List

I plan to still add the following categories / subclasses listed below.  A crossed out item indicates that category of functions has been added.


* Annotations
* AutoComplete and "Element Colors"
* CallTips
* Character Representations
* ~~Direct Access~~
* ~~EOL Annotations~~
* Folding + SCI_SETVISIBLEPOLICY
* IME and UTF-16
* Indicators (underline and such)
* KeyBindings
* Keyboard Commands
* Macro Recording
* Markers
* Multiple views
* OSX Find Indicator
* Other Settings (finish up)
* Printing
* User Lists
