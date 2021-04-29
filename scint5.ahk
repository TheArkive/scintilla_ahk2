; AHK v2
; ====================================================================
; Example
; ====================================================================
g := Gui("+Resize","Scintilla Test")
g.OnEvent("Close",gui_close)
g.OnEvent("Escape",gui_close)
g.OnEvent("Size",gui_size)

ctl := g.AddScintilla("vMyScintilla w500 h500")


ctl.Edge.Mode := 1
ctl.Edge.Color := 0xABCD00
ctl.Edge.Column := 50

ctl.Wrap.Mode := 1

ctl.WhiteSpace.View := 1


g.Show()

gui_size(g, minMax, w, h) {
    ctl := g["MyScintilla"]
    ctl.Move(,,w-(g.MarginX * 2), h-(g.MarginY * 2))
}

gui_close(*) {
    ExitApp
}

F2::{
    Global
    
    m1 := ctl.Margin
    m1.ID := 0
    s := ctl.Style
    s.ID := 33
    s.Back := 0x550000
    m1.Style(0,33)
}
F3::{
    Global
    
    Msgbox ctl.Selection.Replace("___")
}
F4::{
    Global
    
    ctl.ZoomOut()
}

; ====================================================================
; Scintilla Class
; ====================================================================
class Scintilla extends Gui.Custom {
    Static p := A_PtrSize, u := StrLen(Chr(0xFFFF))
    Static DirectFunc := 0
    
    Static charset := {8859_15:0x3E8,ANSI:0x0,ARABIC:0xB2,BALTIC:0xBA,CHINESEBIG5:0x88,CYRILLIC:0x4E3,DEFAULT:0x1
                      ,EASTEUROPE:0xEE,GB2312:0x86,GREEK:0xA1,HANGUL:0x81,HEBREW:0xB1,JOHAB:0x82,MAC:0x4D,OEM:0xFF
                      ,OEM866:0x362,RUSSIAN:0xCC,SHIFTJIS:0x80,SYMBOL:0x2,THAI:0xDE,TURKISH:0xA2,VIETNAMESE:0xA3}
    
    Static cp := Map("UTF-8",65001, "Japanese Shift_JIS",932, "Simplified Chinese GBK",936 ; CodePages
                   , "Korean Unified Hangul Code",949, "Traditional Chinese Big5",950
                   , "Korean Johab",1361)
    
    Static __New() {                                                        ; Need to do it this way.
        Gui.prototype.AddScintilla := ObjBindMethod(this,"AddScintilla")    ; Multiple gui subclass extensions don't play well together.
        
        scint_path := "Scintilla.dll" ; Set this as needed.
        If !(this.hModule := DllCall("LoadLibrary", "Str", scint_path))     ; load dll, make sure it works
            Msgbox "Library not found:`r`n`r`n`tScintilla.dll`r`n`r`n"
                 . "Modify the path to the appropriate location for your script."
        
        For prop in Scintilla.scint_base.prototype.OwnProps() ; attach utility methods to instance
            If !(SubStr(prop,1,2) = "__") And (SubStr(prop,1,1) = "_")
                this.Prototype.%prop% := Scintilla.scint_base.prototype.%prop%
        
        For prop in Scintilla.scint_base.prototype.OwnProps()
            If !(SubStr(prop,1,2) = "__") And (SubStr(prop,1,1) = "_")
                this.Prototype.%prop% := Scintilla.scint_base.prototype.%prop%
    }
    Static AddScintilla(_gui, sOptions) {
        ctl := _gui.Add("Custom","ClassScintilla " sOptions)
        ctl.base := Scintilla.Prototype ; attach methods (but not static ones)
        
        ctl.LastCode := 0       ; like LastError, captures the return codes of messages sent, if any
        ctl._UseDirect := false ; set some defaults...
        ctl._DirectPtr := 0
        ctl._UsePopup := 1
        
        ; =============================================
        ; attach main objects to control Scintilla
        ; =============================================
        ; Annotations
        ; AutoComplete and "Element Colors"
        ctl.Brace := Scintilla.Brace(ctl)
        ; CallTips
        ctl.Caret := Scintilla.Caret(ctl)
        ; Character Representations
        ; Direct Access
        ctl.Edge := Scintilla.Edge(ctl)
        ; EOL Annotations
        ; Folding + SCI_SETVISIBLEPOLICY
        ctl.HotSpot := Scintilla.Hotspot(ctl)
        ; Indicators (underline and such)
        ; KeyBindings
        ; Keyboard Commands
        ctl.LineEnd := Scintilla.LineEnd(ctl)
        ctl.Macro := Scintilla.Macro(ctl)
        ctl.Margin := Scintilla.Margin(ctl)
        ; Markers
        ; Multiple views
        ; OSX Find Indicator
        ; Printing
        ctl.Selection := Scintilla.Selection(ctl)
        ctl.Style := Scintilla.Style(ctl)
        ctl.Styling := Scintilla.Styling(ctl)
        ctl.Tab := Scintilla.Tab(ctl)
        ; User Lists?
        ctl.WhiteSpace := Scintilla.WhiteSpace(ctl)
        ctl.Words := Scintilla.Words(ctl)
        ctl.Wrap := Scintilla.Wrap(ctl)
        
        ; =============================================
        ; custom settings for control here
        ; =============================================
        ctl.BufferedDraw := 0   ; disable buffering for Direct2D
        ctl.SetTechnology := 1  ; use Direct2D
        ; =============================================
        ; these 2 above are highly recommended for performance
        ; =============================================
        ctl.EndAtLastLine := false ; allow scrolling past last line
        
        ctl.Caret.PolicyX(13,50) ; SLOP:=1 | EVEN:=8 | STRICT:=4
        ctl.Caret.PolicyY(13,50) ; smooth L/R scrolling, keeping cursor 50 px from the edge of the window
        
        ctl.Caret.LineVisible := true   ; allow different active line back color
        ctl.Caret.LineBack := 0x151515  ; active line (with caret)
        ; =============================================
        s := ctl.Style ; style 32 is default
        s.Back := 0x080808 ; global background
        s.Fore := 0xAAAAAA ; global text color
        s.Font := "Consolas" ; main text font
        s.Size := 12
        s.ClearAll()         ; apply style 32
        ; =============================================
        s.ID := 33 ; Style 33, use this for number margin
        s.Back := 0x202020
        s.Fore := 0xAAAAAA
        ctl.Margin.ID := 0      ; number margin
        ctl.Margin.Style(0,33)  ; set style .Style(line, style)
        ctl.Margin.Width := 20  ; 20 px number margin
        ; =============================================
        ctl.caret.fore := 0x00FF00 ; change caret color
        ctl.Selection.BackColor := 0x550000
        ; =============================================
        ctl.Tab.Use := false ; use spaces instad of tabs
        ctl.Tab.Width := 4 ; number of spaces for a tab
        
        ctl.Selection.Multi := true
        ctl.Selection.MultiTyping := true ; type during multi-selection
        ctl.Selection.RectModifier := 4 ; alt + drag for rect selection
        ctl.Selection.RectWithMouse := true ; drag + alt also works for rect selection
        ; =============================================
        return ctl
    }
    
    ; =========================================================================================
    ; I might not bother with these (for a while, or at all):
    ; =========================================================================================
    ; SCI_ADDTEXT -> redundant
    ; SCI_ADDSTYLEDTEXT -> i might...
    ; SCI_CHARPOSITIONFROMPOINT
    ; SCI_CHARPOSITIONFROMPOINTCLOSE
    ; SCI_GETLINESELSTARTPOSITION -> using multi-select
    ; SCI_GETLINESELENDPOSITION -> using multi-select
    ; SCI_GETSELTEXT -> i'll use text ranges instead from multi-select
    ; SCI_GETSELECTIONSTART / SCI_GETSELECTIONEND -> using multi-select
    ; SCI_SETSELECTIONSTART / SCI_SETSELECTIONEND -> using multi-select
    ; SCI_GETSTYLEDTEXT -> i might...
    ; SCI_GETANCHOR / SCI_SETANCHOR -> using multi-select
    ; SCI_HIDESELECTION
    ; SCI_MOVECARETINSIDEVIEW
    ; SCI_SETSEL -> using multi-select
    ; SCI_TEXTWIDTH
    ; SCI_TEXTHEIGHT
    ; SCI_POSITIONBEFORE
    ; SCI_POSITIONAFTER
    ; =========================================================================================
    ; =========================================================================================
    Accessibility { ; int 0 = disabled, 1 = enabled
        get => this._sms(0xA8F)         ; SCI_GETACCESSIBILITY
        set => this._sms(0xA8E, value)  ; SCI_SETACCESSIBILITY
    }
    BiDirectional { ; int 0 = disabled, 1 = Left-to-Right, 2 = Right-to-Left
        get => this._sms(0xA94)         ; SCI_GETBIDIRECTIONAL
        set => this._sms(0xA95, value)  ; SCI_SETBIDIRECTIONAL
    }
    BufferedDraw { ; boolean (true = default)
        get => this._sms(0x7F2)         ; SCI_GETBUFFEREDDRAW
        set => this._sms(0x7F3, value)  ; SCI_SETBUFFEREDDRAW
    }
    CodePage { ; default = 65001
        get => this._sms(0x859)         ; SCI_GETCODEPAGE
        set => this._sms(0x7F5, value)  ; SCI_SETCODEPAGE
    }
    Column(pos:="") {
        pos := pos?pos:this.CurPos      ; defaults to getting column at current caret pos
        return this._sms(0x851, pos)    ; SCI_GETCOLUMN
    }
    CurLine {
        get => this.LineFromPos(this.CurPos)
    }
    CurPos {
        get => this._sms(0x7D8)         ; SCI_GETCURRENTPOS
        set => this._sms(0x7E9, value)  ; SCI_GOTOPOS (selects destroyed, cursor scrolled)
    }
    Cursor { ; int -1 = normal mouse cursor, 7 = wait mouse cursor (1-7 can be used?)
        get => this._sms(0x953)         ; SCI_GETCURSOR
        set => this._sms(0x952, value)  ; SCI_SETCURSOR
    }
    DeleteRange(start, end) {
        return this._sms(0xA55, start, end) ; SCI_DELETERANGE
    }
    EndAtLastLine { ; boolean -> true = don't scroll past last line (default), false = you can
        get => this._sms(0x8E6)         ; SCI_GETENDATLASTLINE
        set => this._sms(0x8E5, value)  ; SCI_SETENDATLASTLINE
    }
    FindColumn(line, pos) {
        return this._sms(0x998, line, pos)  ; SCI_FINDCOLUMN
    }
    FontQuality { ; int 0 = Default, 1 = non-anti-aliased, 2 = anti-aliased, 3 = LCD optimized
        get => this._sms(0xA34)         ; SCI_GETFONTQUALITY
        set => this._sms(0xA33, value)  ; SCI_SETFONTQUALITY
    }
    Focused {                           ; boolean
        get => this._sms(0x94D)         ; SCI_GETFOCUS
    }
    GetChar(pos:="") {
        pos := pos?pos:this.CurPos
        return this._sms(0x7D7, pos)    ; SCI_GETCHARAT
    }
    GetTextRange(start, end) {
        tr := Scintilla.TextRange()
        tr.cpMin := start
        tr.cpMax := end
        this._sms(0x872, 0, tr.ptr) ; SCI_GETTEXTRANGE
        return StrGet(tr.buf, "UTF-8")
    }
    GetStyle(pos:="") {
        pos := pos?pos:this.CurPos
        return this._sms(0x7DA, pos)    ; SCI_GETSTYLEAT
    }
    IME_Interaction {                   ; 0 = windowed, 1 = inline
        get => this._sms(0xA76)         ; SCI_GETIMEINTERACTION
        set => this._sms(0xA77, value)  ; SCI_SETIMEINTERACTION
    }
    AppendText(pos:="", text:="") {     ; caret is moved, screen not scrolled
        pos := pos?pos:this.CurPos
        return this._PutStr(0x8EA, pos, text) ; SCI_APPENDTEXT
    }
    InsertText(pos:=-1, text:="") {     ; caret is moved, screen not scrolled
        return this._PutStr(0x7D3, pos, text) ; SCI_INSERTTEXT
    }
    Length {                            ; document length (bytes)
        get => this._sms(0x7D6)         ; SCI_GETLENGTH
    }
    LineEndPos(line:="") {              ; see .PosFromLine() to get the start of a line
        line := line?line:this.CurLine
        return this._sms(0x858, line)   ; SCI_GETLINEENDPOSITION
    }
    LineLength(line:="") {
        line := line?line:this.CurLine
        return this._sms(0x92E, line)   ; SCI_LINELENGTH
    }
    Lines {                             ; number of lines in document
        get => this._sms(0x86A)         ; SCI_GETLINECOUNT
    }
    LineFromPos(pos) {
        return this._sms(0x876, pos)    ; SCI_LINEFROMPOSITION
    }
    LinesJoin() { ; determined by target?
        ; SCI_LINESJOIN
    }
    LinesSplit(pixels) { ; determined by target?
        ; SCI_LINESSPLIT
    }
    LinesOnScreen {
        get => this._sms(0x942)         ; SCI_LINESONSCREEN
    }
    LineText(line:="") {
        line := line?line:this.CurLine
        start := this.PosFromLine(line)
        end := this.LineEndPos(line)
        return this.GetTextRange(start, end)
    }
    Modified {
        get => this._sms(0x86F)         ; SCI_GETMODIFY
    }
    MouseDownCaptures {                 ; boolean - enable/disable
        get => this._sms(0x951)         ; SCI_GETMOUSEDOWNCAPTURES
        set => this._sms(0x950)         ; SCI_SETMOUSEDOWNCAPTURES
    }
    MouseWheelCaptures {                ; boolean - enable/disable
        get => this._sms(0xA89)         ; SCI_GETMOUSEWHEELCAPTURES
        set => this._sms(0xA88, value)  ; SCI_SETMOUSEWHEELCAPTURES
    }
    OverType {                          ; bool - enable/disable overtype
        get => this._sms(0x88B)         ; SCI_GETOVERTYPE
        set => this._sms(0x88A, value)  ; SCI_SETOVERTYPE
    }
    PhaseDraw { ; int 1 = two_phases (default), 2 = multiple_phases
        get => this._sms(0x8EB)         ; SCI_GETTWOPHASEDRAW
        set => this._sms(0x8EC, value)  ; SCI_SETTWOPHASEDRAW
    }
    PointFromPos(pos:="") {
        pos := pos?pos:this.CurPos
        x := this._sms(0x874,,pos)      ; SCI_POINTXFROMPOSITION
        y := this._sms(0x875,,pos)      ; SCI_POINTYFROMPOSITION
        return {x:x, y:y}
    }
    PosFromLine(line:="") {             ; see .LineEndPos() to get end pos of line
        line := line?line:this.CurLine
        return this._sms(0x877, line)   ; SCI_POSITIONFROMLINE
    }
    PosFromPoint(x, y) {
        return this._sms(0x7E7, x, y)   ; SCI_POSITIONFROMPOINTCLOSE
    }
    PosFromPointAny(x, y) {
        return this._sms(0x7E6, x, y)   ; SCI_POSITIONFROMPOINT
    }
    ReadOnly {                          ; boolean
        get => this._sms(0x85C)         ; SCI_GETREADONLY
        set => this._sms(0x87B, value)  ; SCI_SETREADONLY
    }
    ScrollH { ; boolean / show hide Horizontal scroll bar
        get => this._sms(0x853)         ; SCI_GETHSCROLLBAR
        set => this._sms(0x852, value)  ; SCI_SETHSCROLLBAR
    }
    ScrollV { ; boolean / show hide vertical scroll bar
        get => this._sms(0x8E9)         ; SCI_GETVSCROLLBAR
        set => this._sms(0x8E8, value)  ; SCI_GETVSCROLLBAR
    }
    ScrollWidth {                       ; in pixels, default = 2000?
        get => this._sms(0x8E3)         ; SCI_GETSCROLLWIDTH
        set => this._sms(0x8E2, value)  ; SCI_SETSCROLLWIDTH
    }
    ScrollWidthTracking { ; boolean - in case non-wrap text extends beyond 2000 chars (default = false)
        get => this._sms(0x9D5)         ; SCI_GETSCROLLWIDTHTRACKING
        set => this._sms(0x9D4, value)  ; SCI_SETSCROLLWIDTHTRACKING
    }
    SetTechnology { ; int 0 = GDI (default), 1 = DirectWrite (Direct2D), 2 = DirectWriteRetain
        get => this._sms(0xA47)         ; SCI_GETTECHNOLOGY
        set => this._sms(0xA46, value)  ; SCI_SETTECHNOLOGY
    }
    Status {                            ; 0=NONE, 1=GenericFail, 2=MemoryExhausted, 1001=InvalidRegex
        get => this._sms(0x94F)         ; SCI_GETSTATUS
        set => this._sms(0x94E, value)  ; SCI_SETSTATUS ; manually set status = 0 to clear
    }
    SupportsFeature(n) {                ; SCI_SUPPORTSFEATURE
        return this._sms(0xABE, n)      ; 0 = LINE_DRAWS_FINAL, 1 = PIXEL_DIVISIONS, 2 = FRACTIONAL_STROKE_WIDTH
    }                                   ; 3 = TRANSLUCENT_STROKE, 4 = PIXEL_MODIFICATION
    UsePopup { ; int 0 = off, 1 = default, 2 = only on text area
        get => this._UsePopup
        set => this._sms(0x943, value)  ; SCI_USEPOPUP
    }
    
    
    ; =========================================================================================
    ; =========================================================================================
    
    ClearAll() {
        return this._sms(0x7D4)         ; SCI_CLEARALL
    }
    Focus() { ; GrabFocus(0x960) ... or ... SetFocus(0x94C, bool)
        this._sms(0x960)                ; SCI_GRABFOCUS
    }
    SelectAll() {
        return this._sms(0x7DD)         ; SCI_SELECTALL
    }
    Zoom { ; int points (some measure of "zoom factor" for ZoomIN/OUT commands, default = 0
        get => this._sms(0x946)         ; SCI_GETZOOM
        set => this._sms(0x945, value)  ; SCI_SETZOOM
    }
    ZoomIN() {
        return this._sms(0x91D)         ; SCI_ZOOMIN
    }
    ZoomOUT() {
        return this._sms(0x91E)         ; SCI_ZOOMOUT
    }
    ; =========================================================================================
    ; =========================================================================================
    Undo() {
        return this._sms(0x880) ; SCI_UNDO
    }
    CanUndo {
        get => this._sms(0x87E) ; SCI_CANUNDO
    }
    Redo() {
        return this._sms(0x7DB) ; SCI_REDO
    }
    CanRedo {
        get => this._sms(0x7E0) ; SCI_CANREDO
    }
    UndoEmpty() {
        return this._sms(0x87F) ; SCI_EMPTYUNDOBUFFER
    }
    UndoActive {                        ; bool - enable/disable undo collection
        get => this._sms(0x7E3)         ; SCI_GETUNDOCOLLECTION
        set => this._sms(0x7DC, value)  ; SCI_SETUNDOCOLLECTION
    }
    BeginUndo() {
        return this._sms(0x81E) ; SCI_BEGINUNDOACTION
    }
    EndUndo() {
        return this._sms(0x81F) ; SCI_ENDUNDOACTION
    }
    AddUndo(token, flags) {                     ; token is sent in SCN_MODIFIED notification
        return this._sms(0xA00, token, flags)   ; SCI_ADDUNDOACTION
    }
    ; =========================================================================================
    ; =========================================================================================
    
    DirectFunc {
        get => Scintilla.DirectFunc
    }
    DirectPtr {
        get => this._DirectPtr
    }
    UseDirect {
        get => this._UseDirect
        set {
            If (!Scintilla.DirectFunc And value=true) ; store in Scintilla class, once per module instance
                Scintilla.DirectFunc := SendMessage(0x888, 0, 0, this.hwnd) ; SCI_GETDIRECTFUNCTION
            
            If (!this.DirectPtr And value=true) ; store in ctl, call once per control
                this._DirectPtr  := SendMessage(0x889, 0, 0, this.hwnd) ; SCI_GETDIRECTFUNCTION
            
            this._UseDirect := value
        }
    }
    
    ; =========================================================================================
    ; =========================================================================================
    
    class Brace extends Scintilla.scint_base {
        BadLight(in_pos) {
            return this._sms(0x930, in_pos) ; SCI_BRACEBADLIGHT
        }
        BadLightIndicator(on_off, indicator_int) {
            return this._sms(0x9C3, on_off, indicator_int) ; SCI_BRACEBADLIGHTINDICATOR
        }
        Highlight(pos_A, pos_B) {
            return this._sms(0x92F, pos_A, pos_B) ; SCI_BRACEHIGHLIGHT
        }
        HighlightIndicator(on_off, indicator_int) {
            return this._sms(0x9C2, on_off, indicator_int) ; SCI_BRACEHIGHLIGHTINDICATOR
        }
        Match(in_pos, maxReStyle:=0) { ; int position (of brace to be matched) ; maxReStyle must be zero
            return this._sms(0x931, in_pos, maxReStyle) ; SCI_BRACEMATCH
        }
        MatchNext(in_pos, start_pos) {
            return this._sms(0x941, in_pos, start_pos) ; SCI_BRACEMATCHNEXT
        }
    }
    
    class Caret extends Scintilla.scint_base {
        Blink {                             ; int milliseconds
            get => this._sms(0x81B)         ; SCI_GETCARETPERIOD
            set => this._sms(0x81C, value)  ; SCI_SETCARETPERIOD
        }
        ChooseX() {                 ; remembers X pos of cursor for vertical navigation
            return this._sms(0x95F) ; SCI_CHOOSECARETX ; uses CURRENT pos as new X value
        }
        Focus() {                   ; moves to caret, and loses selection
            return this._sms(0x961) ; SCI_MOVECARETINSIDEVIEW
        }
        Fore {                                              ; color
            get => this._RGB_BGR(this._sms(0x85A))          ; SCI_GETCARETFORE
            set => this._sms(0x815, this._RGB_BGR(value))   ; SCI_SETCARETFORE
        }
        GoToLine(line) {
            return this._sms(0x7E8, line)   ; SCI_GOTOLINE
        }
        GoToPos(pos:="") {                  ; caret new pos is scrolled into view
            pos := pos?pos:this.Current     ; use current caret pos by default, and destroys selection
            return this._sms(0x7E9, pos)    ; SCI_GOTOPOS
        }
        LineBack {                                          ; color
            get => this._RGB_BGR(this._sms(0x831))          ; SCI_GETCARETLINEBACK
            set => this._sms(0x832, this._RGB_BGR(value))   ; SCI_SETCARETLINEBACK
        }
        LineBackAlpha {                     ; 0-255
            get => this._sms(0x9A7)         ; SCI_GETCARETLINEBACKALPHA
            set => this._sms(0x9A6, value)  ; SCI_SETCARETLINEBACKALPHA
        }
        LineFrame {                         ; int width in pixels (0 = disabled)
            get => this._sms(0xA90)         ; SCI_GETCARETLINEFRAME
            set => this._sms(0xA91, value)  ; SCI_SETCARETLINEFRAME
        }
        LineVisible {                       ; boolean -> true/false caret line is/is not visible
            get => this._sms(0x82F)         ; SCI_GETCARETLINEVISIBLE
            set => this._sms(0x830, value)  ; SCI_SETCARETLINEVISIBLE
        }
        LineVisibleAlways {     ; boolean
            get => this._sms(0xA5E)         ; SCI_GETCARETLINEVISIBLEALWAYS
            set => this._sms(0xA5F, value)  ; SCI_GETCARETLINEVISIBLEALWAYS
        }
        Multi { ; boolean - default = true
            get => this._sms(0xA31)         ; SCI_GETADDITIONALCARETSVISIBLE
            set => this._sms(0xA30, value)  ; SCI_SETADDITIONALCARETSVISIBLE
        }
        MultiFore {                                         ; get/set Mult-sel fore color
            get => this._RGB_BGR(this._sms(0xA2D))          ; SCI_GETADDITIONALCARETFORE
            set => this._sms(0xA2C, this._RGB_BGR(value))   ; SCI_SETADDITIONALCARETFORE
        }
        MultiBlink {                        ; boolean - default = true
            get => this._sms(0xA08)         ; SCI_GETADDITIONALCARETSBLINK
            set => this._sms(0xA07, value)  ; SCI_SETADDITIONALCARETSBLINK
        }
        PolicyX(policy:=0, pixels:=0) {             ; 1 = SLOP, 4 = STRICT, 8 = EVEN, 16 = JUMPS
            return this._sms(0x962, policy, pixels) ; SCI_SETXCARETPOLICY
        }
        PolicyY(policy:=0, pixels:=0) {             ; 1 = SLOP, 4 = STRICT, 8 = EVEN, 16 = JUMPS
            return this._sms(0x963, policy, pixels) ; SCI_SETYCARETPOLICY
        }
        SetPos(pos:="") {                   ; caret new pos is NOT scrolled into view
            pos := pos?pos:this.Current     ; use current caret pos by default, and just disable selection
            return this._sms(0x9FC, pos)    ; SCI_SETEMPTYSELECTION
        }
        Sticky {                            ; int 0, 1, 2 (default = 0 (off))
            get => this._sms(0x999)         ; SCI_GETCARETSTICKY
            set => this._sms(0x99A, value)  ; SCI_SETCARETSTICKY
        }
        StickyToggle() {
            return this._sms(0x99B) ; SCI_TOGGLECARETSTICKY
        }
        Style {                             ; int 0 = invisible / overstrike bar, 1 = line, 2 = Block, 16 = overstrike block, 256 = block after
            get => this._sms(0x9D1)         ; SCI_GETCARETSTYLE
            set => this._sms(0x9D0, value)  ; SCI_SETCARETSTYLE
        }
        Width {                             ; int pixels (1 = default)
            get => this._sms(0x88D)         ; SCI_GETCARETWIDTH
            set => this._sms(0x88C, value)  ; SCI_SETCARETWIDTH
        }
    }
    
    class Edge extends Scintilla.scint_base {
        Add(column, color) {
            return this._sms(0xA86, column, color) ; SCI_MULTIEDGEADDLINE
        }
        Clear() {
            this._sms(0xA87)    ; SCI_MULTIEDGECLEARALL
        }
        Column {                            ; int column number
            get => this._sms(0x938)         ; SCI_GETEDGECOLUMN
            set => this._sms(0x939, value)  ; SCI_SETEDGECOLUMN
        }
        Color {                                             ; color
            get => this._RGB_BGR(this._sms(0x93C))          ; SCI_GETEDGECOLOUR
            set => this._sms(0x93D, this._RGB_BGR(value))   ; SCI_SETEDGECOLOUR
        }
        GetNext(start_pos:=0) {                 ; returns int/column of next added edge
            return this._sms(0xABD, start_pos)  ; SCI_GETMULTIEDGECOLUMN
        }
        Mode {                              ; int 0 = NONE, 1 = LINE, 2 = BACKGROUND, 3 = MULTI LINE
            get => this._sms(0x93A)         ; SCI_GETEDGEMODE
            set => this._sms(0x93B, value)  ; SCI_SETEDGEMODE
        }
    }
    
    class Hotspot extends Scintilla.scint_base {
        _BackColor := 0xFFFFFF
        _BackEnabled := true
        _ForeColor := 0x000000
        _ForeEnabled := true
        
        Back(bool, color) {
            this._BackEnabled := bool,    this._BackColor := color
            return this._sms(0x96B, bool, this._RGB_BGR(color)) ; SCI_SETHOTSPOTACTIVEBACK
        }
        BackEnabled {
            get => this._BackEnabled                                                                ; boolean
            set => this._sms(0x96B, (this._BackEnabled := value), this._RGB_BGR(this.BackColor))    ; SCI_SETHOTSPOTACTIVEBACK
        }
        BackColor {         ; color
            get => this.BackColor
            set => this._sms(0x96B, this._BackEnabled, this._RGB_BGR(this._BackColor := value)) ; SCI_SETHOTSPOTACTIVEBACK
        }
        Fore(bool, color) {
            this._ForeEnabled := bool,    this._ForeColor := color
            return this._sms(0x96A, bool, this._RGB_BGR(color)) ; SCI_SETHOTSPOTACTIVEFORE
        }
        ForeEnabled {       ; boolean
            get => this.ForeEnabled
            set => this._sms(0x96A, (this._ForeEnabled := value), this._RGB_BGR(this._ForeColor)) ; SCI_SETHOTSPOTACTIVEFORE
        }
        ForeColor {         ; color
            get => this.ForeColor
            set => this._sms(0x96A, this._ForeEnabled, this._RGB_BGR(this._ForeColor := value)) ; SCI_SETHOTSPOTACTIVEFORE
        }
        SingleLine {                        ; boolean
            get => this._sms(0x9C1)         ; SCI_GETHOTSPOTSINGLELINE
            set => this._sms(0x975, value)  ; SCI_SETHOTSPOTSINGLELINE
        }
        Underline {                         ; boolean
            get => this._sms(0x9C0)         ; SCI_GETHOTSPOTACTIVEUNDERLINE
            set => this._sms(0x96C, value)  ; SCI_SETHOTSPOTACTIVEUNDERLINE
        }
    }
    
    class LineEnd extends Scintilla.scint_base {
        Convert(mode) {                     ; mode -> 0 = CRLF, 1 = CR, 2 = LF
            return this._sms(0x7ED, mode)   ; SCI_CONVERTEOLS
        }
        Mode {                              ; int 0 = CRLF, 1 = CR, 2 = LF
            get => this._sms(0x7EE)         ; SCI_GETEOLMODE
            set => this._sms(0x7EF, value)  ; SCI_SETEOLMODE
        }
        View {                              ; boolean - true = show line endings, false = hide line endings
            get => this._sms(0x933)         ; SCI_GETVIEWEOL
            set => this._sms(0x934, value)  ; SCI_SETVIEWEOL
        }
        TypesActive {                       ; int - result is (TypesSupported & TypesAllowed)
            get => this._sms(0xA62)         ; SCI_GETLINEENDTYPESACTIVE
        }
        TypesAllowed {                      ; int 0 = DEFAULT, 1 = UNICODE (works with lexer)
            get => this._sms(0xA61)         ; SCI_GETLINEENDTYPESALLOWED
            set => this._sms(0xA60, value)  ; SCI_SETLINEENDTYPESALLOWED
        }
        TypesSupported {                    ; int 0 = DEFAULT, 1 = UNICODE (read only)
            get => this._sms(0xFB2)         ; SCI_GETLINEENDTYPESSUPPORTED
        }
    }
    
    class Macro extends Scintilla.scint_base {
        Start() {
            return this._sms(0xBB9)         ; SCI_STARTRECORD
        }
        Stop() {
            return this._sms(0xBBA)         ; SCI_STOPRECORD
        }
    }
    
    class Margin extends Scintilla.scint_base {
        ID := 0
        _FoldColorEnabled := false
        _FoldColor := 0
        _FoldHiColorEnabled := false
        _FoldHiColor := 0
        
        Back {                                                          ; color
            get => this._RGB_BGR(this._sms(0x8CB, this.ID))            ; SCI_GETMARGINBACKN
            set => this._sms(0x8CA, this.ID, this._RGB_BGR(value))     ; SCI_SETMARGINBACKN
        }
        Count {                             ; int (default = 5)
            get => this._sms(0x8CD)         ; SCI_GETMARGINS
            set => this._sms(0x8CC, value)  ; SCI_SETMARGINS
        }
        Cursor {                                        ; int -1 = normal, 2 = arrow, 4 = wait, 7 = ReverseArrow
            get => this._sms(0x8C9, this.ID)            ; SCI_GETMARGINCURSORN
            set => this._sms(0x8C8, this.ID, value)     ; SCI_SETMARGINCURSORN
        }
        Fold(bool, color) {
            this._FoldColorEnabled := bool,   this._FoldColor := color
            return this._sms(0x8F2, bool, this._RGB_BGR(color)) ; SCI_SETFOLDMARGINCOLOUR
        }
        FoldColor {         ; color
            get => this._FoldColor
            set => this._sms(0x8F2, this._FoldColorEnabled, this._RGB_BGR(this._FoldColor := value)) ; SCI_SETFOLDMARGINCOLOUR
        }
        FoldColorEnabled {  ; boolean
            get => this._FoldColorEnabled
            set => this._sms(0x8F2, (this._FoldColorEnabled := value), this._RGB_BGR(this._FoldColor)) ; SCI_SETFOLDMARGINCOLOUR
        }
        FoldHi(bool, color) {
            this._FoldHiColorEnabled := bool,   this._FoldHiColor := color
            return this._sms(0x8F3, bool, this._RGB_BGR(color)) ; SCI_SETFOLDMARGINHICOLOUR
        }
        FoldHiColor {       ; color
            get => this._FoldHiColor
            set => this._sms(0x8F3, this._FoldHiColorEnabled, this._RGB_BGR(this._FoldHiColor := value)) ; SCI_SETFOLDMARGINHICOLOUR
        }
        FoldHiColorEnabled { ; boolean
            get => this._FoldHiColorEnabled
            set => this._sms(0x8F3, (this._FoldHiColorEnabled := value), this._RGB_BGR(this._FoldHiColor)) ; SCI_SETFOLDMARGINHICOLOUR
        }
        Left {                                  ; int pixels (margin left... on the margin)
            get => this._sms(0x86C)             ; SCI_GETMARGINLEFT
            set => this._sms(0x86B, 0, value)   ; SCI_SETMARGINLEFT
        }
        Mask {                                      ; int mask (32-bit) - default = SCI_SETMARGINMASKN(1, ~SC_MASK_FOLDERS:=0xFE000000)
            get => this._sms(0x8C5, this.ID)        ; SCI_GETMARGINMASKN
            set => this._sms(0x8C4, this.ID, value) ; SCI_SETMARGINMASKN
        }
        Right {                                 ; int pixels (margin right... on the margin)
            get => this._sms(0x86E)             ; SCI_GETMARGINRIGHT
            set => this._sms(0x86D, 0, value)   ; SCI_SETMARGINRIGHT
        }
        Sensitive {                                 ; boolean
            get => this._sms(0x8C7, this.ID)        ; SCI_GETMARGINSENSITIVEN
            set => this._sms(0x8C6, this.ID, value) ; SCI_SETMARGINSENSITIVEN
        }
        Style(line, style:="") {                        ; n = line, in/out = int
            If (style="")
                return this._sms(0x9E5, line)           ; SCI_MARGINGETSTYLE
            Else
                return this._sms(0x9E4, line, style)    ; SCI_MARGINSETSTYLE
        }
        Text(line, text:=" ") {                         ; n = line, in/out = string
            If (text=" ")
                return this._GetStr(0x9E3, line)        ; SCI_MARGINGETTEXT
            Else
                return this._PutStr(0x9E2, line, text)  ; SCI_MARGINSETTEXT
        }
        Type {              ; int 0 = symbol, 1 = numbers, 2/3 = back/fore, 4/5 = text/rText, 6 = color
            get => this._sms(0x8C1, this.ID)        ; SCI_GETMARGINTYPEN
            set => this._sms(0x8C0, this.ID, value) ; SCI_SETMARGINTYPEN
        }
        Width {             ; int pixels
            get => this._sms(0x8C3, this.ID)        ; SCI_GETMARGINWIDTHN
            set => this._sms(0x8C2, this.ID, value) ; SCI_SETMARGINWIDTHN
        }
    }
    
    class Selection extends Scintilla.scint_base {  ; GET/SET ADDITIONALSELECTIONTYPING
        _BackColor := 0xFFFFFF
        _BackEnabled := true
        _ForeColor := 0x000000
        _ForeEnabled := true
        _MultiBack := 0x000000
        _MultiFore := 0x000000
        
        Add(anchor, caret) {                        ; adds selection with Multi-select enabled
            return this._sms(0xA0D, anchor, caret)  ; SCI_ADDSELECTION
        }
        AddEach() {
            return this._sms(0xA81) ; SCI_MULTIPLESELECTADDEACH
        }
        AddNext() {
            return this._sms(0xA80) ; SCI_MULTIPLESELECTADDNEXT
        }
        Alpha {                             ; 0-255
            get => this._sms(0x9AD)         ; SCI_GETSELALPHA
            set => this._sms(0x9AE, value)  ; SCI_SETSELALPHA
        }
        AnchorPos(pos:="", sel:=0) {                ; sel is 0-based
            If (pos="")
                return this._sms(0xA13, sel)        ; SCI_GETSELECTIONNANCHOR (where selection started, could be on the right)
            Else
                return this._sms(0xA12, sel, pos)   ; SCI_SETSELECTIONNANCHOR (modifies selection)
        }
        AnchorVS(pos:="", sel:=0) {                 ; sel is 0-based
            If (pos="")
                return this._sms(0xA17, sel)        ; SCI_GETSELECTIONNANCHORVIRTUALSPACE
            Else
                return this._sms(0xA16, sel, pos)   ; SCI_SETSELECTIONNANCHORVIRTUALSPACE
        }
        Back(bool, color) {
            this._BackEnabled := bool,    this._BackColor := color
            return this._sms(0x814, bool, this._RGB_BGR(color)) ; SCI_SETSELBACK
        }
        BackEnabled {       ; boolean
            get => this._BackEnabled
            set => this._sms(0x814, (this._BackEnabled := value), this._RGB_BGR(this._BackColor)) ; SCI_SETSELBACK
        }
        BackColor {         ; color
            get => this._BackColor
            set => this._sms(0x814, this._BackEnabled, this._RGB_BGR(this._BackColor := value)) ; SCI_SETSELBACK
        }
        CaretPos(pos:="", sel:=0) {                 
            If (pos="")                             
                return this._sms(0xA11, sel)        ; SCI_GETSELECTIONNCARET (caret is were selection ends, may be on left)
            Else
                return this._sms(0xA10, sel, pos)   ; SCI_SETSELECTIONNCARET (move carat, modifies selection)
        }
        CaretVS(pos:="", sel:=0) {                  ; sel is 0-based
            If (pos="")
                return this._sms(0xA15, sel)        ; SCI_GETSELECTIONNCARETVIRTUALSPACE
            Else
                return this._sms(0xA14, sel, pos)   ; SCI_SETSELECTIONNCARETVIRTUALSPACE
        }
        Clear() {
            return this._sms(0xA0B) ; SCI_CLEARSELECTIONS
        }
        Count {                     ; int -> number of selections
            get => this._sms(0xA0A) ; SCI_GETSELECTIONS
        }
        Drop(sel_num) {
            return this._sms(0xA6F, sel_num) ; SCI_DROPSELECTIONN
        }
        End(pos:="", sel:=0) {                    ; end of selection is always on the right
            If (pos="")
                return this._sms(0xA1B, sel)      ; SCI_GETSELECTIONNEND
            Else
                return this._sms(0xA1A, sel, pos) ; SCI_SETSELECTIONNEND
        }
        EndVS(sel:=0) {
            return this._sms(0xAA7, sel)  ; SCI_GETSELECTIONNENDVIRTUALSPACE
        }
        EOLFilled {                         ; boolean
            get => this._sms(0x9AF)         ; SCI_GETSELEOLFILLED
            set => this._sms(0x9B0, value)  ; SCI_SETSELEOLFILLED
        }
        Fore(bool, color) {
            this._ForeEnabled := bool,    this._ForeColor := color
            return this._sms(0x813, bool, this._RGB_BGR(color)) ; SCI_SETSELFORE
        }
        ForeEnabled {       ; boolean
            get => this._ForeEnabled
            set => this._sms(0x813, (this._ForeEnabled := value), this._RGB_BGR(this._ForeColor)) ; SCI_SETSELFORE
        }
        ForeColor {         ; color
            get => this._ForeColor
            set => this._sms(0x813, this._ForeEnabled, this._RGB_BGR(this._ForeColor := value)) ; SCI_SETSELFORE
        }
        Get(sel_num:=0) {
            tr := Scintilla.TextRange()
            tr.cpMin := ctl.Selection.Start(,sel_num)
            tr.cpMax := ctl.Selection.End(,sel_num)
            this._sms(0x872, 0, tr.ptr) ; SCI_GETTEXTRANGE
            return StrGet(tr.buf, "UTF-8")
        }
        GetAll() {      ; For multi-select, gets selection in order, with CRLF breaks between selections.
            _str := ""  ; For rectangle select, ALWAYS gets top line first.
            
            If (this.IsRect) And (this.RectAnchor > this.RectCaret) {
                Loop (i := this.Count)
                    _str .= ((A_Index=1)?"":"`r`n") this.Get(i-1-(A_Index-1))
            } Else {
                Loop this.Count
                    _str .= ((A_Index=1)?"":"`r`n") this.Get(A_Index-1)
            }
            return _str
        }
        IsEmpty {                   ; bool -> return 1 if all selections empty, else 0
            get => this._sms(0xA5A) ; SCI_GETSELECTIONEMPTY
        }
        IsExtend {
            get => this._sms(0xA92)         ; SCI_GETMOVEEXTENDSSELECTION
        }
        IsRect {                            ; bool -> is or is not rectangle
            get => this._sms(0x944)         ; SCI_SELECTIONISRECTANGLE
        }
        Main {                              ; int set selection number as main
            get => this._sms(0xA0F)         ; SCI_GETMAINSELECTION
            set => this._sms(0xA0E, value)  ; SCI_SETMAINSELECTION
        }
        Mode {                              ; 0=STREAM, 1=RECT, 2=LINES, 3=THIN
            get => this._sms(0x977)         ; SCI_GETSELECTIONMODE
            set => this._sms(0x976, value)  ; SCI_SETSELECTIONMODE
        }
        Multi {                             ; boolean - enable/disable multi-select
            get => this._sms(0xA04)         ; SCI_GETMULTIPLESELECTION
            set => this._sms(0xA03, value)  ; SCI_SETMULTIPLESELECTION
        }
        MultiAlpha {                        ; 0-255
            get => this._sms(0xA2B)         ; SCI_GETADDITIONALSELALPHA
            set => this._sms(0xA2A, value)  ; SCI_SETADDITIONALSELALPHA
        }
        MultiBack {         ; color
            get => this._MultiBack
            set {
                this._MultiBack := value
                this._sms(0xA29, this._RGB_BGR(value))  ; SCI_SETADDITIONALSELBACK
            }
        }
        MultiFore {
            get => this._MultiFore
            set {
                this._MultiFore := value
                this._sms(0xA28, this._RGB_BGR(value))  ; SCI_SETADDITIONALSELFORE
            }
        }
        MultiPaste {                        ; int 0 = PASTE ONCE, 1 = PASTE EACH    
            get => this._sms(0xA37)         ; SCI_GETMULTIPASTE
            set => this._sms(0xA36, value)  ; SCI_SETMULTIPASTE
        }
        MultiTyping {
            get => this._sms(0xA06)         ; SCI_GETADDITIONALSELECTIONTYPING
            set => this._sms(0xA05, value)  ; SCI_SETADDITIONALSELECTIONTYPING
        }
        RectAnchor {                        ; get/set RectAnchor position
            get => this._sms(0xA1F)         ; SCI_GETRECTANGULARSELECTIONANCHOR
            set => this._sms(0xA1E, value)  ; SCI_SETRECTANGULARSELECTIONANCHOR
        }
        RectAnchorVS {                      ; get/set RectAnchor virtual space
            get => this._sms(0xA23)         ; SCI_GETRECTANGULARSELECTIONANCHORVIRTUALSPACE
            set => this._sms(0xA22, value)  ; SCI_SETRECTANGULARSELECTIONANCHORVIRTUALSPACE
        }
        RectCaret {                         ; get/set RectCaret position
            get => this._sms(0xA1D)         ; SCI_GETRECTANGULARSELECTIONCARET
            set => this._sms(0xA1C, value)  ; SCI_SETRECTANGULARSELECTIONCARET
        }
        RectCaretVS {                       ; get/set RectCaret virtual space
            get => this._sms(0xA21)         ; SCI_GETRECTANGULARSELECTIONCARETVIRTUALSPACE
            set => this._sms(0xA20, value)  ; SCI_SETRECTANGULARSELECTIONCARETVIRTUALSPACE
        }
        RectModifier {                      ; int 0 = NONE, 2 = CTRL, 4 = ALT, 8 = SUPER (WinKey)
            get => this._sms(0xA27)         ; SCI_GETRECTANGULARSELECTIONMODIFIER
            set => this._sms(0xA26, value)  ; SCI_SETRECTANGULARSELECTIONMODIFIER
        }
        RectWithMouse {                     ; use rect modifier key while selecting with mouse (default = false)
            get => this._sms(0xA6D)         ; SCI_GETMOUSESELECTIONRECTANGULARSWITCH
            set => this._sms(0xA6C, value)  ; SCI_SETMOUSESELECTIONRECTANGULARSWITCH
        }
        Replace(text:="") {                 ; replaces all selections with specified text
            Loop this.Count {
                this.Main := A_Index - 1
                this._PutStr(0x87A,,text)   ; SCI_REPLACESEL
            }
        }
        Rotate() {                  ; makes "next" seletion the "main" selection
            return this._sms(0xA2E) ; SCI_ROTATESELECTION
        }
        Set(anchor, caret) {                        ; selection set in specified range as only selection
            return this._sms(0xA0C, anchor, caret)  ; SCI_SETSELECTION
        }
        Start(pos:="", sel:=0) {                    ; start of selection is ALWAYS on the left
            If (pos="")
                return this._sms(0xA19, sel)        ; SCI_GETSELECTIONNSTART
            Else
                return this._sms(0xA18, sel, pos)   ; SCI_SETSELECTIONNSTART
        }
        StartVS(sel:=0) {                   ; sel is 0-based
            return this._sms(0xAA6, sel)    ; SCI_GETSELECTIONNSTARTVIRTUALSPACE
        }
        SwapMainAnchorCaret() {
            return this._sms(0xA2F) ; SCI_SWAPMAINANCHORCARET
        }
        VirtualSpaceOpt {                   ; int 0 = NONE (default), 1 = RectSelect, 2 = UserAccessible, 4 = NoWrapLineStart
            get => this._sms(0xA25)         ; SCI_GETVIRTUALSPACEOPTIONS
            set => this._sms(0xA24, value)  ; SCI_SETVIRTUALSPACEOPTIONS
        }
    }
    
    class Style extends Scintilla.scint_base {
        ID := 32
        Back {              ; color
            get => this._RGB_BGR(this._sms(0x9B2, this.ID))         ; SCI_STYLEGETBACK
            set => this._sms(0x804, this.ID, this._RGB_BGR(value))  ; SCI_STYLESETBACK
        }
        Bold {              ; boolean
            get => this._sms(0x9B3, this.ID)            ; SCI_STYLEGETBOLD
            set => this._sms(0x805, this.ID, value)     ; SCI_STYLESETBOLD
        }
        Case {                                      ; int 0 = mixed (default), 1 = upper, 2 = lower, 3 = camel (title case?)
            get => this._sms(0x9B9, this.ID)        ; SCI_STYLEGETCASE
            set => this._sms(0x80C, this.ID, value) ; SCI_STYLESETCASE
        }
        Changeable {                                ; boolean (experimental)
            get => this._sms(0x9BC, this.ID)        ; SCI_STYLEGETCHANGEABLE
            set => this._sms(0x833, this.ID, value) ; SCI_STYLESETCHANGEABLE
        }
        ClearAll() {
            return this._sms(0x802) ; SCI_STYLECLEARALL
        }
        EOLFilled {                             ; boolean
            get => this._sms(0x9B7, this.ID)    ; SCI_STYLEGETEOLFILLED
            set {
                cs := "8859_15`r`nANSI`r`nArabic`r`nBaltic`r`nChineseBig5`r`nCyrillic`r`nDefault`r`nEastEurope`r`nGB2312`r`nGreek`r`nHangul`r`n"
                    . "Hebrew`r`nJohab`r`nMAC`r`nOEM`r`nOEM866`r`nRussian`r`nShiftJIS`r`nSymbol`r`nThai`r`nTurkish`r`nVietnamese"
                If !Scintilla.charset.Has(value) And !IsInteger(value) {
                    Msgbox("Selecting a charset requires one of the following values:`r`n`r`n" cs)
                    return
                }
                (Scintilla.charset.Has(value)) ? (value := Scintilla.charset.%value%) : "" ; convert str to integer
                this._sms(0x809, this.ID, value)    ; SCI_STYLESETEOLFILLED
            }
        }
        Font {              ; string
            get => this._GetStr(0x9B6, this.ID)         ; SCI_STYLEGETFONT
            set => this._PutStr(0x808, this.ID, value)  ; SCI_STYLESETFONT
        }
        Fore {              ; color
            get => this._RGB_BGR(this._sms(0x9B1, this.ID))         ; SCI_STYLEGETFORE
            set => this._sms(0x803, this.ID, this._RGB_BGR(value))  ; SCI_STYLESETFORE
        }
        Hotspot {           ; boolean
            get => this._sms(0x9BC, this.ID)        ; SCI_STYLEGETCHANGEABLE
            set => this._sms(0x833, this.ID, value) ; SCI_STYLESETCHANGEABLE
        }
        Italic {            ; boolean
            get => this._sms(0x9BD, this.ID)        ; SCI_STYLEGETHOTSPOT
            set => this._sms(0x969, this.ID, value) ; SCI_STYLESETHOTSPOT
        }
        ResetDefault() {
            return this._sms(0x80A) ; SCI_STYLERESETDEFAULT
        }
        Size {              ; float 0.00
            get => (this._sms(0x80E, this.ID) / 100)        ; SCI_STYLEGETSIZEFRACTIONAL
            set => this._sms(0x80D, this.ID, value * 100)   ; SCI_STYLESETSIZEFRACTIONAL
        }
        Underline {         ; boolean
            get => this._sms(0x9B8, this.ID)            ; SCI_STYLEGETUNDERLINE
            set => this._sms(0x80B, this.ID, value)     ; SCI_STYLESETUNDERLINE
        }
        Visible {           ; boolean
            get => this._sms(0x9BB, this.ID)        ; SCI_STYLEGETVISIBLE
            set => this._sms(0x81A, this.ID, value) ; SCI_STYLESETVISIBLE
        }
        Weight {                            ; 400 = normal, 600 = semi-bold, 700 = bold (value = 1-999)
            get => this._sms(0x810)         ; SCI_STYLEGETWEIGHT
            set => this._sms(0x80F, value)  ; SCI_STYLESETWEIGHT
        }
    }
    
    class Styling extends Scintilla.scint_base {
        Clear() {                   ; clears styles AND folds
            return this._sms(0x7D5) ; SCI_CLEARDOCUMENTSTYLE
        }
        Idle {  ; int 0 = NONE, 1 = TOVISIBLE, 2 = AFTERVISIBLE, 3 = ALL
            get => this._sms(0xA85)         ; SCI_GETIDLESTYLING
            set => this._sms(0xA84, value)  ; SCI_SETIDLESTYLING
        }
        Last {
            get => this._sms(0x7EC) ; SCI_GETENDSTYLED
        }
        LineState(line, state:="") { ; int - user defined integer?
            If (state="")
                return this._sms(0x82D, line)           ; SCI_GETLINESTATE
            Else
                return this._sms(0x82C, line, state)    ; SCI_SETLINESTATE
        }
        MaxLineState { ; returns last line with a "state" set
            get => this._sms(0x82E) ; SCI_GETMAXLINESTATE
        }
        Set(length, style) {
            return this._sms(0x7F1, length, style)  ; SCI_SETSTYLING
        }
        SetEx(length, style_bytes_ptr) {
            return this._sms(0x819, length, style_bytes_ptr) ; SCI_SETSTYLINGEX
        }
        Start(pos) {
            return this._sms(0x7F0, pos) ; SCI_STARTSTYLING
        }
    }
    
    class Tab extends Scintilla.scint_base {
        Add(line, pixels) { ; int line / pixels
            return this._sms(0xA74, line, pixels) ; SCI_ADDTABSTOP
        }
        Clear(line) {   ; int line number
            return this._sms(0xA73, line) ; SCI_CLEARTABSTOPS
        }
        HighlightGuide { ; int: column position where highlight indentation guide for matched braces is
            get => this._sms(0x857)         ; SCI_GETHIGHLIGHTGUIDE
            set => this._sms(0x856, value)  ; SCI_SETHIGHLIGHTGUIDE
        }
        Indents {       ; boolean - TAB indent without adding space/tab
            get => this._sms(0x8D5)         ; SCI_GETTABINDENTS
            set => this._sms(0x8D4, value)  ; SCI_SETTABINDENTS
        }
        IndentGuides {  ; int 0 = NONE, 1 = REAL, 2 = LOOKFORWARD, 3 = LOOKBOTH
            get => this._sms(0x855)         ; SCI_GETINDENTATIONGUIDES
            set => this._sms(0x854, value)  ; SCI_SETINDENTATIONGUIDES
        }
        IndentPosition(line) {
            return this._sms(0x850, line)   ; SCI_GETLINEINDENTPOSITION
        }
        LineIndentation(line, spaces:="") { ; n = line, value = num_of_spaces/columns
            If (spaces="")
                return this._sms(0x84F, line)           ; SCI_GETLINEINDENTATION
            Else
                return this._sms(0x84E, line, spaces)    ; SCI_SETLINEINDENTATION
        }
        MinimumWidth {  ; int pixels
            get => this._sms(0xAA5)         ; SCI_GETTABMINIMUMWIDTH
            set => this._sms(0xAA4, value)  ; SCI_SETTABMINIMUMWIDTH
        }
        Next(line, pixels_pos) {
            return this._sms(0xA75, line, pixels_pos)   ; SCI_GETNEXTTABSTOP
        }
        Unindents {     ; boolean - BACKSPACE unindents without removing spaces/tabs
            get => this._sms(0x8D7)         ; SCI_GETBACKSPACEUNINDENTS
            set => this._sms(0x8D6, value)  ; SCI_SETBACKSPACEUNINDENTS
        }
        Use { ; bool /// false means use all spaces
            get => this._sms(0x84D)         ; SCI_GETUSETABS
            set => this._sms(0x84C, value)  ; SCI_SETUSETABS
        }
        
        ; ==============================================
        ; oddly similar me thinks...
        ; ==============================================
        Indent {        ; int num_of_spaces
            get => this._sms(0x84B)         ; SCI_GETINDENT
            set => this._sms(0x84A, value)  ; SCI_SETINDENT
        }
        Width {         ; int num_of_spaces
            get => this._sms(0x849)         ; SCI_GETTABWIDTH
            set => this._sms(0x7F4, value)  ; SCI_SETTABWIDTH
        }
        ; ==============================================
    }
    
    class WhiteSpace extends Scintilla.scint_base {
        _BackColor := 0xFFFFFF
        _BackEnabled := true
        _ForeColor := 0x000000
        _ForeEnabled := true
        
        Back(bool, color) {
            this._BackEnabled := bool,    this._BackColor := color
            return this._sms(0x825, bool, this._RGB_BGR(color)) ; SCI_SETWHITESPACEBACK
        }
        BackEnabled {       ; boolean
            get => this._BackEnabled
            set => this._sms(0x825, (this._BackEnabled := value), this._RGB_BGR(this._BackColor)) ; SCI_SETWHITESPACEBACK
        }
        BackColor {         ; color
            get => this._BackColor
            set => this._sms(0x825, this._BackEnabled, this._RGB_BGR(this._BackColor := value)) ; SCI_SETWHITESPACEBACK
        }
        ExtraAscent { ; int (bool?)
            get => this._sms(0x9DE)         ; SCI_GETEXTRAASCENT
            set => this._sms(0x9DD, value)  ; SCI_SETEXTRAASCENT
        }
        ExtraDecent { ; int (bool?)
            get => this._sms(0x9E0)         ; SCI_GETEXTRADESCENT
            set => this._sms(0x9DF, value)  ; SCI_SETEXTRADESCENT
        }
        Fore(bool, color) {
            this._ForeEnabled := bool,    this._ForeColor := color
            return this._sms(0x824, bool, this._RGB_BGR(color)) ; SCI_SETWHITESPACEFORE
        }
        ForeEnabled {       ; boolean
            get => this._ForeEnabled
            set => this._sms(0x824, (this._ForeEnabled := value), this._RGB_BGR(this._ForeColor)) ; SCI_SETWHITESPACEFORE
        }
        ForeColor {         ; color
            get => this._ForeColor
            set => this._sms(0x824, this._ForeEnabled, this._RGB_BGR(this._ForeColor := value)) ; SCI_SETWHITESPACEFORE
        }
        Size { ; int pixels?
            get => this._sms(0x827)         ; SCI_GETWHITESPACESIZE
            set => this._sms(0x826, value)  ; SCI_SETWHITESPACESIZE
        }
        TabDrawMode { ; int 0 = arrow, 1 = strike (line)
            get => this._sms(0xA8A)         ; SCI_GETTABDRAWMODE
            set => this._sms(0xA8B, value)  ; SCI_SETTABDRAWMODE
        }
        View { ; int 0 = Invisible, 1 = VisibleAlways, 2 = VisibleAfterIndent, 3 = VisibleOnlyIndent
            get => this._sms(0x7E4)         ; SCI_GETVIEWWS
            set => this._sms(0x7E5, value)  ; SCI_SETVIEWWS
        }
    }
    
    class Words extends Scintilla.scint_base {
        CharCatOpt { ; int - see SCI_WORD* and SCI_DELWORD* constants
            get => this._sms(0xAA1)         ; SCI_GETCHARACTERCATEGORYOPTIMIZATION
            set => this._sms(0xAA0, value)  ; SCI_SETCHARACTERCATEGORYOPTIMIZATION
        }
        Default() { ; resets chars for words, whiteSpace, and punctuation
            return this._sms(0x98C) ; SCI_SETCHARSDEFAULT
        }
        EndPos(start_pos, OnlyWordChars:=true) { ; get "end of word" pos from specified pos
            return this._sms(0x8DB, start_pos, OnlyWordChars) ; SCI_WORDENDPOSITION
        }
        IsRangeWord(start_pos, end_pos) {
            return this._sms(0xA83, start_pos, end_pos) ; SCI_ISRANGEWORD
        }
        PunctuationChars { ; set/get punct chars
            get => this._GetStr(0xA59,,true)    ; SCI_GETPUNCTUATIONCHARS
            set => this._PutStr(0xA58,,value)   ; SCI_SETPUNCTUATIONCHARS
        }
        StartPos(start_pos, OnlyWordChars:=true) { ; get "start of word" pos from specified pos
            return this._sms(0x8DA, start_pos, OnlyWordChars)   ; SCI_WORDSTARTPOSITION
        }
        WhiteSpaceChars { ; set/get white space chars
            get => this._GetStr(0xA57,,true)    ; SCI_GETWHITESPACECHARS
            set => this._PutStr(0x98B,,value)   ; SCI_SETWHITESPACECHARS
        }
        WordChars { ; set/get word chars
            get => this._GetStr(0xA56,,true)    ; SCI_GETWORDCHARS
            set => this._PutStr(0x81D,,value)   ; SCI_SETWORDCHARS
        }
    }
    
    class Wrap extends Scintilla.scint_base {
        Count(line) { ; returns # of lines taken up by display for specified line
            return this._sms(0x8BB, line)   ; SCI_WRAPCOUNT
        }
        IndentMode { ; int 0, 1, 2, 3
            get => this._sms(0x9A9)         ; SCI_GETWRAPINDENTMODE
            set => this._sms(0x9A8, value)  ; SCI_SETWRAPINDENTMODE
        }
        LayoutCache { ; int 0 = NONE, 1 = current line, 2 = visible lines + caret line, 3 = whole document
            get => this._sms(0x8E1)         ; SCI_GETLAYOUTCACHE
            set => this._sms(0x8E0, value)  ; SCI_SETLAYOUTCACHE
        }
        Location { ; int 0 = draw near border, 1 = end of subline, 2 = beginning of subline
            get => this._sms(0x99F)         ; SCI_GETWRAPVISUALFLAGSLOCATION
            set => this._sms(0x99E, value)  ; SCI_SETWRAPVISUALFLAGSLOCATION
        }
        Mode { ; int 0 = NONE, 1 = WORD, 2 = CHAR, 3 = WHITE SPACE (combo)
            get => this._sms(0x8DD)         ; SCI_GETWRAPMODE
            set => this._sms(0x8DC, value)  ; SCI_SETWRAPMODE
        }
        PositionCache { ; int -> size of cache for short runs (default = 1024)
            get => this._sms(0x9D3)         ; SCI_GETPOSITIONCACHE
            set => this._sms(0x9D2, value)  ; SCI_SETPOSITIONCACHE
        }
        Visual { ; int 0 = NONE, 1 = end of line, 2 = beginning of line, 4 = in number margin (combo)
            get => this._sms(0x99D)         ; SCI_GETWRAPVISUALFLAGS
            set => this._sms(0x99C, value)  ; SCI_SETWRAPVISUALFLAGS
        }
    }
    
    class scint_base {
        LastCode := 0
        __New(_super, ctl) { ; 1st param in subclass is parent class
            this.ctl := ctl
        }
        
        _GetStr(msg, wParam:=0, reverse:=false) {
            buf := BufferAlloc(this._sms(msg, wParam) + 1, 0), out_str := ""
            this._sms(msg, wParam, buf.ptr)
            
            If (reverse)
                Loop (offset := buf.Size - 1)
                    If (_asc := NumGet(buf,offset - (A_Index-1),"UChar"))
                        out_str .= Chr(_asc)
            
            return (reverse) ? out_str : StrGet(buf, "UTF-8")
        }
        _PutStr(msg, wParam:=0, str:="") {
            buf := BufferAlloc(StrLen(str)+1,0)
            StrPut(str,buf,"UTF-8")
            return this._sms(msg, wParam, buf.ptr)
        }
        
        _RGB_BGR(_in) {
            return Format("0x{:06X}",(_in & 0xFF) << 16 | (_in & 0xFF00) | (_in >> 16))
        }
        
        _sms(msg, wParam:=0, lParam:=0) {
            obj := (this.__Class = "Scintilla") ? this : this.ctl
            If (obj.UseDirect)
                r := DllCall(obj.DirectFunc, "UInt", obj.DirectPtr, "UInt", msg, "Int", wParam, "Int", lParam)
            Else
                r := SendMessage(msg, wParam, lParam, obj.hwnd)
            return (obj.LastCode := r) ; every sub-class will have this element
        }
        
        
        
        _GetRect(_ptr, offset:=0) {
            a := []
            Loop 4
                a.Push(NumGet(_ptr, offset + ((A_Index-1) * 4), "UInt"))
            return a
        }
        _SetRect(value, _ptr, offset:=0) {
            If (Type(value) != "Array") Or (value.Length != 4)
                throw Error("Inalid input for this property.",,"The input for this property must be a linear array with 4 values:`r`n`r`n[1, 2, 3, 4]")
            
            Loop 4
                NumPut("UInt", value[A_Index], _ptr, offset + ((A_Index-1) * 4))
        }
    }
    
    class CharRange {
        __New(_super) {
            this.struct := BufferAlloc(8,0)
        }
        cpMin {
            get => NumGet(this.struct, 0, "UInt")
            set => NumPut("UInt", value, this.struct)
        }
        cpMax {
            get => NumGet(this.struct, 4, "UInt")
            set => NumPut("UInt", value, this.struct, 4)
        }
        ptr {
            get => this.struct.ptr
        }
    }
    
    class TextRange {
        __New(_super) {
            this.struct := BufferAlloc((A_PtrSize=4)?12:16, 0)
        }
        _SetBuffer() {
            If (this.cpMax) {
                If (this.cpMax < this.cpMin)
                    throw Error("Invalid range.",,"`r`ncpMin: " this.cpMin "`r`ncpMax: " this.cpMax)
                
                this.buf := BufferAlloc(this.cpMax - this.cpMin + 1, 0)
                this.lpText := this.buf.ptr
            }
        }
        cpMin {
            get => NumGet(this.struct, 0, "UInt")
            set {
                NumPut("UInt", value, this.struct)
                this._SetBuffer()
            }
        }
        cpMax {
            get => NumGet(this.struct, 4, "UInt")
            set {
                NumPut("UInt", value, this.struct, 4)
                this._SetBuffer()
            }
        }
        lpText {
            get => NumGet(this.struct, 8, "UPtr")
            set => NumPut("UPtr", value, this.struct, 8)
        }
        ptr {
            get => this.struct.ptr
        }
    }
}