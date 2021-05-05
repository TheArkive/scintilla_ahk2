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

## Basic Properties and Methods
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>

## Brace sub-class
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>

## Caret sub-class
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>

## Edge sub-class
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>

## Hotspot sub-class
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>

## LineEndings sub-class
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>

## Macro sub-class
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>

## Margin sub-class
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>

## Selection sub-class
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>

## Style sub-class
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>

## Styling sub-class
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>

## Tab sub-class
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>

## WhiteSpace sub-class
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>

## Words sub-class
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>

## Wrap sub-class
<details>
<summary style="font-size:9">Click here to toggle</summary>

... in progress ...

</details>