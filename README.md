# scintilla_ahk2
Scintilla class wrapper for AHK v2

## Scintilla.dll
Go to the Scintilla site to get the DLL.  [Here is the download page for SciTE.](https://www.scintilla.org/SciTEDownload.html)

Direct Links:

* [SciTE 64-bit](https://www.scintilla.org/wscite502.zip)
* [SciTE 32-bit](https://www.scintilla.org/wscite32_502.zip)

Pick your desired 32-bit or 64-bit version for download.  Unzip and copy over the `Scintilla.dll` from the unzipped folder into the same folder as the script.  You can of course place the DLL anywhere, but make sure you modify the class lib in `Static __New()` to point to the proper DLL location.

## Status

I finally have the first version of a custom styling routine written enrirely in AHK.  It's a decent start, and performs well (at least for my uses).  I'll improve performance by splitting up the syntax coloring and prioritizing the user view first.

I did try to use the `SC_StyleNeeded` event.  It actually is faster and is also currently implemented, but commented out, so it can be enabled if you want to test it.  It seems to only actually do stying when the user moves the mouse or scrolls.  When pasting large amounts of text this is problematic.  Even if you wait for the syntax coloring to catch up, well, it never happens, unless you move the mouse or scroll.

In general, after I get syntax highlighting performing the way I want, I'll expand it to include word lists, more classes of characters for and punctuation, and so on.

Then I'll move on to call tips and auto-complete.  That's the rough plan for now.

# Documentation

Making the documentation will be a lengthy work in progress...

Here are a few general guidelines:

* All numerical IDs are zero-based.  So position numbers, line numbers, column numbers, margin numbers, style numbers, selection numbers, etc., start at zero.
* I tried to keep all like categories of methods and properties together as they are listed on the Scintilla Documentation site, but this is not always the case.  Generally I'm just trying to keep concepts in logical categories (sub classes).  This is a bit of a process as I discover other functions, some of which serve a better purpose in a different category than originally listed in the Scintilla Docs.
* Not all Scintilla functions will make it into this library.  Basically, functions that appear to duplicate another function's result with little or no benefit won't be added, unless there is a good reason, in which case it may get a different name to more appropriately describe what it is best used for.

# Current Changes

2021/08/06
* updated to Scintilla 5.1.1
* Custom syntax highlighting basic framework is now complete:
  - see StylingRoutine() and DeleteRoutine() methods
  - currently numbers, strings, comments, braces, and punctuation are colored
  - not much customization available yet, unless you edit the class directly
  - I plant to implement a framework that will make defining specific colors for specific groups/types of characters
* cleaned up code
* implemented SCI_GETDIRECTSTATUSFUNCTION in place of SCI_GETDIRECTFUNCTION
* ctl.Status property now pulls the status from what was returned using the new DirectStatusFunction (should be faster when checking status)
* removed old AutoBraceMatching()
* removed Events class, I'm just putting these events in as methods of the class
* performance is quite decent, but needs to be broken up to prioritize user viewed lines first
--------------------
* refined pasting large chunks of text (getting 6s load time on ~2MB of text)
* initial coloring is strings, comments, and braces only (in that order) on the first go
* other syntax elements are colord per-screen when scrolling, or per-line when typing

2021/05/17

* added ctl.Target.\* subclass, aka Searching category (forgot to add this from a week ago)
* added ctl.Target.Text for getting the matched text
* added ctl.Target.Prev(), .Next(), .Flags, .Tag(), .Anchor()
* added ctl.CharIndex for implementing UTF-16 / UTF-32
* added ctl.EscapeChar, .StringChar, .CommentLine, .CommentBlock, properties
* fixed ctl.GetTextRange() to properly handle UTF-8 with wide characters
* fixed ctl.LineText() to make fewer calls to the control to get line text
* improved ctl.GetChar() to handle wide characters
* added ctl.NextCharPos(), .NextChar(), .PrevCharPos(), .PrevChar()
* removed ctl.Margin.DefaultMinWidth / .WidthOffset\
Now calculation of number margin is more dynamic based on font size
* `ctl.Event.MarginWidth()`, with only first two params, can be used to autosize the number margin on-demand
* moved ctl.Style.TextWidth() to ctl.TextWidth()
* added "DefaultOpt" and "DefaultTheme" options for Gui.AddScintilla(), see example
* added ctl.AutoBraceMatch (false by default), uses style 40 and 41 by default (DefaultTheme)
* added ctl.Event.BraceMatch() ... must be used in callback, don't use when `ctl.AutoBraceMatch := true`

2021/05/11

* moved example back to top, now initiating class with "(Scintilla)" for the example (see comments)
* fixed some instances of blank optional parameters not functioning as intended
* added Doc category (Multiple Views)
* officially crossed off "Other Settings" category (it was done a while ago)
* reorded several properties and methods on the main Scintilla class prepping for documentation
* added ctl.AutoSizeNumberMargin (defaults to false)
* added ctl.Events category for packaged functions/methods, intended to assist with common tasks
* added ctl.Events.MarginWidth(margin, size) - for on-demand or usage within user callback (don't use this method directly in callback when `ctl.AutoSizeNumberMargin := true`)
* added ctl.Margin.MinWidth / .DefaultMinWidth / .WidthOffset (mostly used in ctl.Events.MarginWidth())

2021/05/05

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

`scn` Members:

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

obj.Marker.num := 4 ; make future calls to obj.Marker.* apply to marker #4
                    ; NOTE: All methods in the Marker subclass also take a markerNum parameter.
                    ; If you don't specify a markerNum, then the specified .num is used.
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
* Macro Recording (technically done, but not tested, and might need index of SCI_\* constants)
* ~~Markers~~
* ~~Multiple views~~
* OSX Find Indicator
* ~~Other Settings (finish up)~~
* Printing
* User Lists
