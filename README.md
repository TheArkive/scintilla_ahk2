# scintilla_ahk2
Scintilla class wrapper for AHK v2

[Download page for SciTE](https://www.scintilla.org/SciTEDownload.html)

Pick your desired 32-bit or 64-bit version for download (one of the first two links), and just copy over the DLL into the same folder as the script.  You can of course place the DLL anywhere, but make sure you modify the class lib in `Static __New()` to point to the proper DLL location.