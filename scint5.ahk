; AHK v2
; ====================================================================
; Example
; ====================================================================
(Scintilla) ; Init class, or simply #INCLUDE the extension-lib at the top.

g := Gui("+Resize +E0x2000000 0x2000000","Scintilla Test")
g.OnEvent("Close",gui_close)
g.OnEvent("Escape",gui_close)
g.OnEvent("Size",gui_size)


ctl := g.AddScintilla("vMyScintilla w500 h500 DefaultOpt DefaultTheme")

; ======================================================================
; items that should be set by the user
; ======================================================================
ctl.Brace.Chars := "[]{}()" ; modify braces list that will be tracked
ctl.SyntaxPunctChars := "?:*+-&^|!~/\.,=<>"
ctl.AutoSizeNumberMargin := true

ctl.Target.Flags := Scintilla.sc_search.RegXP | Scintilla.sc_search.POSIX

; ctl.Edge.Mode := 1 ; vertical lines - handy!
; ctl.Edge.Color := 0xABCD00
; ctl.Edge.Column := 50
; ctl.WhiteSpace.View := 1

ctl.callback := ctl_callback
ctl.CustomSyntaxHighlighting := true
; ctl.Styling.Idle := 3 ; do NOT set this when using my syntax highlight.  My syntax highlighting works differently.

; ======================================================================
; show GUI
; ======================================================================
g.Show()

gui_size(g, minMax, w, h) {
    ctl := g["MyScintilla"]
    ctl.Move(,,w-(g.MarginX * 2), h-(g.MarginY * 2))
}

gui_close(*) {
    ExitApp
}

F2::{
    global ctl
    s := ctl.Styling
    ; msgbox ctl.CurPos " / '" ctl.GetChar(ctl.CurPos) "'"
    ; ctl.FirstVisibleLine := 10
    msgbox ctl.DocLine(ctl.FirstVisibleLine) " / " ctl.LinesOnScreen ; display first line / lines on screen
    ; ctl.cancel := 1
    
    txt := ""
    Loop ctl.DocMap.Length
        txt .= (txt?"`r`n":"") "line: " A_Index " / " ctl.DocMap[A_Index]
    A_Clipboard := txt
    msgbox "check it"
}

ctl_callback(ctl, scn) { ; callback for wm_notify messages
    ; do user stuff
}


; ====================================================================
; Scintilla Class
; ====================================================================
class Scintilla extends Gui.Custom {
    Static p := A_PtrSize, u := StrLen(Chr(0xFFFF))
    Static DirectFunc := 0, DirectStatusFunc := 0
    
    Static wm_notify := {AutoCCancelled:0x7E9
                       , AutoCCharDeleted:0x7EA
                       , AutoCCompleted:0x7EE
                       , AutoCSelection:0x7E6
                       , AutoCSelectionChange:0x7F0
                       , CallTipClick:0x7E5
                       , CharAdded:0x7D1
                       , DoubleClick:0x7D6
                       , DwellEnd:0x7E1
                       , DwellStart:0x7E0
                       , FocusIn:0x7EC
                       , FocusOut:0x7ED
                       , HotSpotClick:0x7E3
                       , HotSpotDoubleClick:0x7E4
                       , HotSpotReleaseClick:0x7EB
                       , IndicatorClick:0x7E7
                       , IndicatorRelease:0x7E8
                       , Key:0x7D5
                       , MacroRecord:0x7D9
                       , MarginClick:0x7DA
                       , MarginRightClick:0x7EF
                       , Modified:0x7D8
                       , ModifyAtTempTRO:0x7D4
                       , NeedShown:0x7DB
                       , Painted:0x7DD
                       , SavePointLeft:0x7D3
                       , SavePointReached:0x7D2
                       , StyleNeeded:0x7D0
                       , UpdateUI:0x7D7
                       , UriDropped:0x7DF            ; Change:0x300
                       , UserListSelection:0x7DE     ; KillFocus:0x100
                       , Zoom:0x7E2}                 ; SetFocus:0x200
    
    Static scn_id := this.p         ; NMHDR #2              ; ptr               ; SCNotification offsets
         , scn_wmmsg := this.p * 2  ; NMHDR #3              ; uint              verified:  13/22 members (not counting NMHDR)
         , scn_pos := (this.p=4)                ? 12 : 24   ; int Sci_Position  <-- verified offset
         , scn_ch := (this.p=4)                 ? 16 : 32   ; int               <-- verified offset
         , scn_mod := (this.p=4)                ? 20 : 36   ; int               <-- verified offset
         , scn_modType := (this.p=4)            ? 24 : 40   ; int               <-- verified offset
         , scn_text := (this.p=4)               ? 28 : 48   ; ptr               <-- verified offset
         , scn_length := (this.p=4)             ? 32 : 56   ; int Sci_Position  <-- verified offset
         , scn_linesAdded := (this.p=4)         ? 36 : 64   ; int Sci_Position  <-- verified offset
         , scn_message := (this.p=4)            ? 40 : 72   ; int
         , scn_wParam := (this.p=4)             ? 44 : 80   ; ptr
         , scn_lParam := (this.p=4)             ? 48 : 88   ; sptr (signed)
         , scn_line := (this.p=4)               ? 52 : 96   ; int Sci_Position  <-- verified offset
         , scn_foldLevelNow := (this.p=4)       ? 56 : 104  ; int                   need folding to verify
         , scn_foldLevelPrev := (this.p=4)      ? 60 : 108  ; int                   need folding to verify
         , scn_margin := (this.p=4)             ? 64 : 112  ; int               <-- verified offset
         , scn_listType := (this.p=4)           ? 68 : 116  ; int                   need user list or auto-complete to verify
         , scn_x := (this.p=4)                  ? 72 : 120  ; int               <-- verified offset
         , scn_y := (this.p=4)                  ? 76 : 124  ; int               <-- verified offset
         , scn_token := (this.p=4)              ? 80 : 128  ; int               <-- verified offset
         , scn_annotationLinesAdded:=(this.p=4) ? 84 : 136  ; int Sci_Position      need to use annotations to verify
         , scn_updated := (this.p=4)            ? 88 : 144  ; int               <-- verified offset
         , scn_listCompletionMethod:=(this.p=4) ? 92 : 148  ; int                   need user list or auto-complete to verify
         , scn_characterSource := (this.p=4)    ? 96 : 152  ; int                   need IME input to verify this
    
    Static sc_eol := {Hidden:0
                    , Standard:0x1
                    , Boxed:0x2
                    , Stadium:0x100         ; ( ... )
                    , FlatCircle:0x101      ; | ... )
                    , AngleCircle:0x102     ; < ... )
                    , CircleFlat:0x110      ; ( ... |
                    , Flats:0x111           ; | ... |
                    , AngleFlat:0x112       ; < ... |
                    , CircleAngle:0x120     ; ( ... >
                    , FlatAngle:0x121       ; | ... >
                    , Angles:0x122}         ; < ... >
    
    Static sc_mod := {Ctrl:2, Alt:4, Shift:1, Meta:16, Super:8}
    
    Static sc_updated := {Content:0x1, Selection:2, VScroll:4, HScroll:8}
    
    Static sc_marker := {Circle:0x0
                       , RoundRect:0x1
                       , Arrow:0x2
                       , SmallRect:0x3
                       , ShortArrow:0x4
                       , Empty:0x5
                       , ArrowDown:0x6
                       , Minus:0x7
                       , Plus:0x8
                       , Vline:0x9
                       , LCorner:0xA
                       , TCorner:0xB
                       , BoxPlus:0xC
                       , BoxPlusConnected:0xD
                       , BoxMinus:0xE
                       , BoxMinusConnected:0xF
                       , LCornerCurve:0x10
                       , TCornerCurve:0x11
                       , CirclePlus:0x12
                       , CirclePlusconnected:0x13
                       , CircleMinus:0x14
                       , CircleMinusconnected:0x15
                       , Background:0x16
                       , DotDotDot:0x17
                       , Arrows:0x18
                       , Pixmap:0x19
                       , FullRect:0x1A
                       , LeftRect:0x1B
                       , Available:0x1C
                       , Underline:0x1D
                       , RgbaImage:0x1E
                       , Bookmark:0x1F
                       , VerticalBookmark:0x20
                       , Character:0x2710}
    
    Static sc_MarkerNum := {FolderEnd:0x19
                          , FolderOpenMid:0x1A
                          , FolderMidTail:0x1B
                          , FolderTail:0x1C
                          , FolderSub:0x1D
                          , Folder:0x1E
                          , FolderOpen:0x1F}
    
    Static sc_modType := {None:0                    ; SCN members affected below...
                        , InsertText:0x1            ; pos, length, text, linesAdded
                        , DeleteText:0x2            ; pos, length, text, linesAdded
                        , ChangeStyle:0x4           ; pos, length
                        , ChangeFold:0x8            ; line, foldLevelNow, foldLevelPrev
                        , User:0x10                 ; 
                        , Undo:0x20                 ; 
                        , Redo:0x40                 ; 
                        , MultiStepUndoRedo:0x80    ; 
                        , LastStepInUndoRedo:0x100  ; 
                        , ChangeMarker:0x200        ; line
                        , BeforeInsert:0x400        ; pos, if user, text in bytes, length in bytes
                        , BeforeDelete:0x800        ; position, length
                        , ChangeIndicator:0x4000    ; position, length
                        , ChangeLineState:0x8000    ; line
                        , ChangeTabStops:0x200000   ; line
                        , LexerState:0x80000        ; position, length
                        , ChangeMargin:0x10000      ; line
                        , ChangeAnnotation:0x20000  ; line
                        , InsertCheck:0x100000      ; position, length, text
                        , MultiLineUndoRedo:0x1000  ; 
                        , StartAction:0x2000        ; 
                        , Container:0x40000}        ; token
                        ; , EventMaskAll:0x1FFFFF}    ; 
    
    Static sc_search := {None:0x0               ; Default, case-insensitive match.
                       , WholeWord:0x2          ; Matches whole word, see Words.WordChars
                       , MatchCase:0x4
                       , WordStart:0x100000     ; Matches beginning of word, see Words.WordChars
                       , RegXP:0x200000         ; Enables a RegEx search.
                       , POSIX:0x400000         ; Allows () instead of \(\), but referring to tags still requires \1 instead of $1.
                                                ;   Don't use with CXX11.
                       , CXX11RegEx:0x800000}   ; Need to test to see if this will be simple enough to use in AHK.
                                                ;   This should be the closest to AHK RegEx.  Requires RegXP to also be set.
    
    Static charset := {8859_15:0x3E8,ANSI:0x0,ARABIC:0xB2,BALTIC:0xBA,CHINESEBIG5:0x88,CYRILLIC:0x4E3,DEFAULT:0x1
                      ,EASTEUROPE:0xEE,GB2312:0x86,GREEK:0xA1,HANGUL:0x81,HEBREW:0xB1,JOHAB:0x82,MAC:0x4D,OEM:0xFF
                      ,OEM866:0x362,RUSSIAN:0xCC,SHIFTJIS:0x80,SYMBOL:0x2,THAI:0xDE,TURKISH:0xA2,VIETNAMESE:0xA3}
    
    Static cp := Map("UTF-8",65001, "Japanese Shift_JIS",932, "Simplified Chinese GBK",936 ; CodePages
                   , "Korean Unified Hangul Code",949, "Traditional Chinese Big5",950
                   , "Korean Johab",1361)
    
    Static __New() {                                                        ; Need to do it this way.
        Gui.Prototype.AddScintilla := ObjBindMethod(this,"AddScintilla")    ; Multiple gui subclass extensions don't play well together.
        
        scint_path := A_ScriptDir "\Scintilla.dll" ; Set this as needed.
        If !(this.hModule := DllCall("LoadLibrary", "Str", scint_path)) {    ; load dll, make sure it works
            MsgBox "Scintilla DLL not found.`n`nModify the path to the appropriate location for your script."
            ExitApp
        }
        
        For prop in Scintilla.scint_base.prototype.OwnProps() ; attach utility methods to prototype
            If !(SubStr(prop,1,2) = "__") And (SubStr(prop,1,1) = "_")
                this.Prototype.%prop% := Scintilla.scint_base.prototype.%prop%
        
        ; For prop in Scintilla.scint_base.prototype.OwnProps() ; how did i dupe this???
            ; If !(SubStr(prop,1,2) = "__") And (SubStr(prop,1,1) = "_")
                ; this.Prototype.%prop% := Scintilla.scint_base.prototype.%prop%
    }
    Static AddScintilla(_gui, sOptions) {
        DefaultOpt := false
        DefaultTheme := false
        
        opt_arr := StrSplit(sOptions," ")
        sOptions := ""
        For i, str in opt_arr {
            If RegExMatch(str, "DefaultOpts?")
                DefaultOpt := true
            Else If (str = "DefaultTheme")
                DefaultTheme := true
            Else
                sOptions .= (sOptions?" ":"") str
        }
        
        ctl := _gui.Add("Custom","ClassScintilla " sOptions)
        ctl.base := Scintilla.Prototype ; attach methods (but not static ones)
        
        ctl.msg_cb := ObjBindMethod(ctl, "wm_messages") ; Register wm_notify messages
        OnMessage(0x4E, ctl.msg_cb)
        
        ctl.callback := ""      ; setting some main properties
        ctl.state := ""         ; used to determine input "mode", ie. string, comment, etc.
        ctl._StatusD := 0
        ctl._UsePopup := true
        ctl._UseDirect := false ; set some defaults...
        ctl._DirectPtr := 0
        ctl.LastCode := 0       ; like LastError, captures the return codes of messages sent, if any
        
        ctl._AutoSizeNumberMargin := false
        ctl._AutoBraceMatch := false
        ctl._AutoPunctColor := false
        ctl._CharIndex := 0 ; 0 = NONE (ie. UTF-8) / 1 = UTF-32 / 2 = UTF-16
        ctl.SyntaxCommentLine := ";"
        ctl.SyntaxCommentBlock := "/* */"
        ctl.SyntaxStringChar := Chr(34)
        ctl.SyntaxEscapeChar := Chr(96)
        ctl.SyntaxPunctChars := "?:*+-&^|!~/\.,="
        ctl.SyntaxString1 := Chr(34)
        ctl.SyntaxString2 := "'"
        
        ; ==============================================
        ; Custom Syntax Highlighting properties
        ; ==============================================
        
        ctl.StopStyling := false
        ctl.CustomSyntaxHighlighting := false
        ctl.DocMap := [false] ; init as blank document with one unstyled line
        ctl.LinesBeforeInsert := 1
        ctl.LineBeforeInsert := 0
        
        ; =============================================
        ; attach main objects to Scintilla control
        ; =============================================
        ; Annotations
        ; AutoComplete and "Element Colors"
        ctl.Brace := Scintilla.Brace(ctl)
        ; CallTips
        ctl.Caret := Scintilla.Caret(ctl)
        ; Character Representations
        ctl.Doc := Scintilla.Doc(ctl)           ; Multiple views
        ctl.Edge := Scintilla.Edge(ctl)         ; Long lines
        ctl.EOLAnn := Scintilla.EOLAnn(ctl)     ; End of Line Annotations
        ; ctl.Event := Scintilla.Event(ctl)       ; Custom easy methods for common actions
        ; Folding + SCI_SETVISIBLEPOLICY
        ctl.HotSpot := Scintilla.Hotspot(ctl)
        ; Indicators (underline and such)
        ; KeyBindings
        ; Keyboard Commands
        ctl.LineEnding := Scintilla.LineEnding(ctl)
        ctl.Macro := Scintilla.Macro(ctl) ; planning to add obj to index all recordable msg numbers
        ctl.Margin := Scintilla.Margin(ctl)
        ctl.Marker := Scintilla.Marker(ctl)
        ; OSX Find Indicator
        ; Printing
        ctl.Selection := Scintilla.Selection(ctl)
        ctl.Style := Scintilla.Style(ctl)
        ctl.Styling := Scintilla.Styling(ctl)
        ctl.Tab := Scintilla.Tab(ctl)
        ctl.Target := Scintilla.Target(ctl)
        ; User Lists?
        ctl.WhiteSpace := Scintilla.WhiteSpace(ctl)
        ctl.Word := Scintilla.Word(ctl)
        ctl.Wrap := Scintilla.Wrap(ctl)
        
        ; =============================================
        ; custom settings for control here
        ; these 2 settings are recommended for modern systems
        ; =============================================
        ctl.BufferedDraw := 0   ; disable buffering for Direct2D
        ctl.SetTechnology := 2  ; use Direct2D
        
        If DefaultOpt
            ctl.DefaultOpt()
        If DefaultTheme
            ctl.DefaultTheme()
        
        return ctl
    }
    Static Lookup(member, in_value) {
        For prop, value in this.%member%.OwnProps()
            If (value = in_value)
                return prop
        return ""
    }
    Static GetFlags(member, in_value, all:=false) {
        out_str := ""
        For prop, value in Scintilla.%member%.OwnProps()
            If (value & in_value)
                out_str .= (out_str?" ":"") prop
        return out_str
    }
    Static RGB(R, G, B) {
        return Format("0x{:06X}",(R << 16) | (G << 8) | B)
    }
    
    wm_messages(wParam, lParam, msg, hwnd) {
        Static modType := Scintilla.sc_modType
        
        scn := Scintilla.SCNotification(lParam)
        _scn := {hwnd:scn.hwnd
               , id:scn.id
               , wmmsg:scn.wmmsg
               , pos:scn.pos
               , ch:scn.ch
               , mod:scn.mod
               , modType:scn.modType
               , text:scn.text
               , length:scn.length
               , linesAdded:scn.linesAdded
               , message:scn.message
               , wParam:scn.wParam
               , lParam:scn.lParam
               , line:scn.line
               , foldLevelNow:scn.foldLevelNow
               , foldLevelPrev:scn.foldLevelPrev
               , margin:scn.margin
               , listType:scn.listType
               , x:scn.x
               , y:scn.y
               , token:scn.token
               , annotationLinesAdded:scn.annotationLinesAdded
               , updated:scn.updated
               , listCompletionMethod:scn.listCompletionMethod
               , characterSource:scn.characterSource}
        
        event := scn.wmmsg_txt := Scintilla.Lookup("wm_notify", (msg_num := scn.wmmsg))
        _scn.wmmsg_txt := event
        
        If (event = "UpdateUI" && (scn.updated=4 || scn.updated=8))
            dbg("top line: " ctl.FirstVisibleDocLine)
        
        ; =========================================================================
        ; Easy events: Comment any of these out if you want to fine-tune function
        ; or performance in the user callback manually.
        ; =========================================================================
        
        If (this.AutoSizeNumberMargin)
            this.MarginWidth(0, 33, scn) ; number margin 0, with default style 33
        
        If (this.CustomSyntaxHighlighting) {
            If (scn.modType & modType.BeforeInsert) {
                this.LinesBeforeInsert := this.Lines
                this.LineBeforeInsert := this.CurLine
            }
            
            If (scn.modType & modType.InsertText) || (event = "UpdateUI" && (scn.updated=4 || scn.updated=8)) {
                
                this._BraceInit := this.BraceInit.Bind(this,_scn)
                If (event = "Modified") && (scn.linesAdded)
                    this.BraceInit(scn)
                
                this._StylingRoutine := this.StylingRoutine.Bind(this,_scn)
                If (event = "UpdateUI" && (scn.updated=4 || scn.updated=8))
                    SetTimer this._StylingRoutine, 0
                
                Loop scn.linesAdded {
                    If (ctl.CurLine > ctl.LinesBeforeInsert)
                        ctl.DocMap.Push(false) ; add lines at the end of the doc
                    Else
                        ctl.DocMap.InsertAt(ctl.LineFromPos(scn.pos)+1,false) ; add lines in the middle of the doc
                }
                
                SetTimer this._StylingRoutine, -20
            }
            
            Else If (scn.modType & modType.BeforeDelete)
                this.DeleteRoutine(ctl, _scn)
        }
        
        ; If (scn.wmmsg_txt = "StyleNeeded") ; works but.... meh
            ; this.StylingRoutine2(_scn)
        
        ; =========================================================================
        ; User callback
        ; =========================================================================
        
        If (this.callback)
            f := this.callback(_scn)
    }
    
    MarginWidth(margin:=0, style:=33, scn:="") {
        Static modType := Scintilla.sc_modType
        
        If !scn || !((scn.wmmsg_txt = "Modified")
          && (scn.modType & modType.DeleteText || scn.modType & modType.InsertText))
            return
        
        this.Style.ID := style
        this.Margin.ID := margin
        min_width := this.Margin.MinWidth
        width := this.TextWidth(this.Lines) + this.TextWidth("0")
        
        this.Margin.Width := (width >= min_width) ? width : min_width
    }
    
    BraceInit(scn) {
                Static ctl := this
        Static s := ctl.Styling
             , q := Chr(34)
        
        bChars := RTrim(RegExReplace(ctl.Brace.Chars,"","\"),"\")       ; prep strings for regex
        cChar  := RTrim(RegExReplace(ctl.SyntaxCommentLine,"","\"),"\")
        
        start_line := ctl.LineFromPos(startPos := scn.pos)
        startPos := ctl.PosFromLine(start_line)
        _txt := ctl.GetTextRange(startPos,startPos+scn.length-1)
        
        rgMatch := "mS)(\" q "[^\" q "]+\" q "|[\" q "]+|\" q "|[" cChar "]+ ?.*$|[" bChars "])"
        oy := StrSplit(_txt,"`n","`r")
        
        For i, _txt in oy {
            _line := start_line + (i-1)
            startPos := ctl.PosFromLine(_line)
            
            off1 := 1
            While (off1 := RegExMatch(_txt, rgMatch, &m, off1)) { ; scn.text
                curP := ctl.PosRelative(startPos,off1-1) ; scn.pos
                spec_len := ctl.PosRelative(startPos,m.Len[1]) - startPos
                
                If RegExMatch(m[1],"S)^[" bChars "]") {
                    If (ctl.GetStyle(curP) != 40)
                        s.Start(curP), s.Set(1,41) ; unmatched brace
                    
                    If ((bPos := ctl.Brace.Match(curP)) > -1) && (ctl.GetStyle(bPos) = 41)
                        s.Start(bPos), s.Set(1,40), s.Start(curP), s.Set(1,40)   ; matching braces
                    
                } Else If RegExMatch(m[1],"S)^\" q "[^" q "]*\" q) {
                    s.Start(curP), s.Set(spec_len,43)
                
                } Else If RegExMatch(m[1],"mS)^[\" cChar "]+ ?.*$") { ; comments
                    s.Start(curP), s.Set(spec_len,44) ; dbg("comment: curP: " curP " / str: " m[1] " / len: " m.Len[1])
                    
                }
                
                off1 += m.Len[1]
            }
        }
    }
    
    DeleteRoutine(ctl, scn) {
        Static s := ctl.Styling
             , q := Chr(34)
        
        If (scn.length = ctl.length)
            return
        
        startPos1 := scn.pos
        start_line := ctl.LineFromPos(scn.pos)
        startPos := ctl.PosFromLine(start_line)
        diff := scn.pos - startPos
        newLen := scn.length + diff
        _txt := ctl.GetTextRange(startPos, startPos + newLen)
        
        bChars := RTrim(RegExReplace(ctl.Brace.Chars,"","\"),"\")       ; prep strings for regex
        oy := StrSplit(_txt,"`n","`r")
        
        For i, _txt in oy {
            _line := start_line + (i-1)
            startPos := ctl.PosFromLine(_line)
            
            off1 := (i=1) ? diff+1 : 1
            kill_brace := []
            While (off1 := RegExMatch(_txt,"[" bChars "]",,off1)) { ; Loop through and catalog braces.
                curP := ctl.PosRelative(startPos,off1-1)            ; This seems to be necessary in order to
                If (brMatch := ctl.Brace.Match(curP))               ; properly handle total custom highlighting.
                    kill_brace.Push({a:curP, b:brMatch})
                off1++
            }
            
            For i, obj in kill_brace ; highlight in one go
                s.Start(obj.a), s.Set(1,41), s.Start(obj.b), s.Set(1,41)
        }
    }

    StylingRoutine(scn) {
        Static ctl := this
        Static s := ctl.Styling
             , q := Chr(34)
        
        bChars := RTrim(RegExReplace(ctl.Brace.Chars,"","\"),"\")       ; prep strings for regex
        pChars := RTrim(RegExReplace(ctl.SyntaxPunctChars,"","\"),"\")  ; scn props: text, length, linesAdded, pos
        cChar  := RTrim(RegExReplace(ctl.SyntaxCommentLine,"","\"),"\")
        cBlock := StrSplit(RegExReplace(ctl.SyntaxCommentBlock,"","\")," ")
        
        start_line := ctl.LineFromPos(startPos := scn.pos)
        ctl.DocMap[start_line+1] := false
        
        ; dbg("first visible line: " ctl.FirstVisibleDocLine " / curLine: " ctl.CurLine " / line before insert: " ctl.LineBeforeInsert)
        
        If (scn.linesAdded>0) || (scn.updated=4 || scn.updated=8) {
            If (Abs(ctl.LineBeforeInsert - ctl.CurLine) > ctl.LinesOnScreen) || (scn.updated=4 || scn.updated=8) {
                dbg("scrolling...")
                
                start_line := ctl.FirstVisibleDocLine
                end_line := start_line + ctl.LinesOnScreen
                
                dbg("start_line: " start_line " / end_line: " end_line)
                
                _txt := "", i := start_line
                While (i <= end_line) {
                    _txt .= ctl.LineText(i)
                    i++
                }
            } Else {
                _txt := scn.text
            }
        } Else {
            startPos := ctl.PosFromLine(start_line)
            _txt := ctl.LineText(start_line)
        }
        
        rgMatch := "mS)([" bChars "]|[" pChars "]|0x[0-9a-fA-F]+|(?<!\w)[0-9]+|\" q "[^\" q "]+\" q "|[\" q "]+|\" q "|[" cChar "]+ ?.*$|[ \t\r\n]+)"
        oy := StrSplit(_txt,"`n","`r")
        
        For i, _txt in oy {
            If (ctl.StopStyling)
                Break
            
            _line := start_line + (i-1)
            startPos := ctl.PosFromLine(_line)
            
            off1 := 1
            While (off1 := RegExMatch(_txt, rgMatch, &m, off1)) { ; scn.text
                curP := ctl.PosRelative(startPos,off1-1) ; scn.pos
                spec_len := ctl.PosRelative(startPos,m.Len[1]) - startPos
                
                If RegExMatch(m[1],"S)^[" bChars "]") {
                    If (ctl.GetStyle(curP) != 40)
                        s.Start(curP), s.Set(1,41) ; unmatched brace
                    
                    If ((bPos := ctl.Brace.Match(curP)) > -1) && (ctl.GetStyle(bPos) = 41)
                        s.Start(bPos), s.Set(1,40), s.Start(curP), s.Set(1,40)   ; matching braces
                    
                } Else If RegExMatch(m[1],"S)^[" pChars "]") { ; syntax punctuation (operators, separators, etc)
                    s.Start(curP), s.Set(1,42)
                
                } Else If RegExMatch(m[1],"S)^0x[0-9a-fA-F]+") {
                    s.Start(curP), s.Set(m.Len[1],45)
                
                } Else if RegExMatch(m[1],"S)^(?<!\w)[0-9]+") {
                    s.Start(curP), s.Set(m.Len[1],45)
                
                } Else If (m[1] = q) {
                    s.Start(curP), s.Set(1,43)
                    
                } Else If RegExMatch(m[1],"S)^\" q "[^" q "]*\" q) {
                    s.Start(curP), s.Set(spec_len,43)
                
                } Else If RegExMatch(m[1],"mS)^[\" cChar "]+ ?.*$") { ; comments
                    s.Start(curP), s.Set(spec_len,44) ; dbg("comment: curP: " curP " / str: " m[1] " / len: " m.Len[1])
                
                } Else If RegExMatch(m[1],"S)(?:^[ \t\r\n]+)") {
                    s.Start(curP), s.Set(m.Len[1],32)
                }
                
                off1 += m.Len[1]
            }
            
            ctl.DocMap[_line+1] := true
        }
        
        ; 34 ; brace highlight
        ; 35 ; brace bad highlight
        
        ; 40 ; matched brace color
        ; 41 ; unmatched brace color
        ; 42 ; punct color
        ; 43 ; string color
        ; 44 ; comment
        ; 45 ; numbers
    }

    StylingRoutine2(scn) { ; SC_StyleNeeded event only ; disable StylingRoutine() and DeleteRoutine() if using this
        Static ctl := this ; this is temporary
        Static s := ctl.Styling
             , q := Chr(34)
        
        startPos := ctl.Styling.Last
        
        ; dbg("styling last: " ctl.Styling.Last)
        
        _line := ctl.LineFromPos(startPos)
        startPos := ctl.PosFromLine(_line)
        _txt := ctl.LineText(_line)
        
        bChars := RTrim(RegExReplace(ctl.Brace.Chars,"","\"),"\")       ; prep strings for regex
        pChars := RTrim(RegExReplace(ctl.SyntaxPunctChars,"","\"),"\")  ; scn props: text, length, linesAdded, pos
        cChar  := RTrim(RegExReplace(ctl.SyntaxCommentLine,"","\"),"\")
        cBlock := StrSplit(RegExReplace(ctl.SyntaxCommentBlock,"","\")," ")
        
        rgMatch := "mS)([" bChars "]|[" pChars "]|0x[0-9a-fA-F]+|(?<!\w)[0-9]+|\" q "[^" q "]+\" q "|[\" q "]+|\" q "|[" cChar "]+ ?.*$|[ \t\r\n]+)"
        
        off1 := 1
        While (off1 := RegExMatch(_txt, rgMatch, &m, off1)) { ; scn.text
            ; dbg("off1: " off1)
            curP := ctl.PosRelative(startPos,off1-1) ; scn.pos
            spec_len := ctl.PosRelative(startPos,m.Len[1]) - startPos
            
            If RegExMatch(m[1],"S)^[" bChars "]") {
                ; dbg("brace: curP: " curP " / str: " m[1] " / len: " m.Len[1])
                
                If (ctl.GetStyle(curP) != 40)
                    s.Start(curP), s.Set(1,41) ; unmatched brace
                
                If ((bPos := ctl.Brace.Match(curP)) > -1) && (ctl.GetStyle(bPos) = 41) {
                    ; dbg("brace2: curP: " curP " / str: " m[1] " / len: " m.Len[1] " / bPos: " bPos)
                    s.Start(bPos), s.Set(1,40), s.Start(curP), s.Set(1,40)   ; matching braces
                }
                
            } Else If RegExMatch(m[1],"S)^[" pChars "]") { ; syntax punctuation (operators, separators, etc)
                s.Start(curP), s.Set(1,42)
            
            } Else If RegExMatch(m[1],"S)^0x[0-9a-fA-F]+") {
                s.Start(curP), s.Set(m.Len[1],45)
            
            } Else if RegExMatch(m[1],"S)^(?<!\w)[0-9]+") {
                s.Start(curP), s.Set(m.Len[1],45)
            
            } Else If (m[1] = q) {
                s.Start(curP), s.Set(1,43)
                
            } Else If RegExMatch(m[1],"S)^\" q "[^" q "]*\" q) {
                s.Start(curP), s.Set(spec_len,43)
            
            } Else If RegExMatch(m[1],"mS)^[\" cChar "]+ ?.*$") { ; comments
                s.Start(curP), s.Set(spec_len,44) ; dbg("comment: curP: " curP " / str: " m[1] " / len: " m.Len[1])
            
            } Else If RegExMatch(m[1],"S)(?:^[ \t\r\n]+)") {
                s.Start(curP), s.Set(m.Len[1],32)
                
            }
            
            off1 += m.Len[1]
        }
        
        ; 34 ; brace highlight
        ; 35 ; brace bad highlight
        
        ; 40 ; matched brace color
        ; 41 ; unmatched brace color
        ; 42 ; punct color
        ; 43 ; string color
        ; 44 ; comment
        ; 45 ; numbers
    }
    
    DefaultOpt() {
        this.UseDirect := true
        
        this.Wrap.Mode := 1
        this.EndAtLastLine := false ; allow scrolling past last line
        this.Caret.PolicyX(13,50) ; SLOP:=1 | EVEN:=8 | STRICT:=4
        this.Caret.LineVisible := true   ; allow different active line back color
        
        this.Margin.ID := 0      ; number margin
        this.Margin.Style(0,33)  ; set style .Style(line, style)
        this.Margin.Width := 20  ; 20 px number margin
        
        this.Margin.ID := 1
        this.Margin.Sensitive := true
        
        this.Tab.Use := false ; use spaces instad of tabs
        this.Tab.Width := 4 ; number of spaces for a tab
        
        this.Selection.Multi := true ; allow multli-select, hold CTRL to add selection on left-click
        this.Selection.MultiTyping := true ; type during multi-selection
        this.Selection.RectModifier := 4 ; alt + drag for rect selection
        this.Selection.RectWithMouse := true ; drag + alt also works for rect selection
        
        ; this.Styling.Idle := 3 ; All (style before and after visible text)
    }

    DefaultTheme() {
        this.Caret.LineBack := 0x151515  ; active line (with caret)
        
        s := this.Style ; style 32 is default, isolate style obj (to be lazy!)
        s.Back := 0x080808 ; global background
        s.Fore := 0xAAAAAA ; global text color
        s.Font := "Consolas" ; main text font
        s.Size := 12
        s.ClearAll()         ; apply style 32
        
        s.ID := 33 ; Style 33, use this for number margin
        s.Back := 0x202020 ; 0x202020
        s.Fore := 0xAAAAAA
        
        this.Caret.Fore := 0x00FF00 ; change caret color
        this.Selection.BackColor := 0x550000 ; current line background color
        
        s.ID := 34 ; brace highlight
        s.Fore := 0x00FF00
        
        s.ID := 35 ; brace bad highlight
        s.Fore := 0xFF0000
        
        s.ID := 40 ; matched brace color
        s.Fore := 0x8080FF
        
        s.ID := 41 ; unmatched brace color
        s.Fore := 0xFF0000
        
        s.ID := 42 ; punct color
        s.Fore := 0xFF8040
        
        s.ID := 43 ; string color
        s.Fore := 0x555555
        
        s.ID := 44 ; comment
        s.Fore := 0x008800
    
        s.ID := 45 ; numbers
        s.Fore := 0xFFFF00
    }
    
    ; =========================================================================================
    ; I might not bother with these (for a while, or at all):
    ; =========================================================================================
    ; SCI_ADDTEXT -> redundant, AppendText offers more control and makes more sense.
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
    ; SCI_TEXTHEIGHT
    ; SCI_POSITIONBEFORE
    ; SCI_POSITIONAFTER
    ; SCI_FINDTEXT      ctl.Target.* search functions work well enough
    ; SCI_SEARCHANCHOR
    ; SCI_SEARCHNEXT
    ; SCI_SEARCHPREV
    ; SCI_GETELEMENTBASECOLOUR(int = elemnt number) - gets "default color" for specified element
    
    ; =========================================================================================
    ; Scintilla Control Content methods and properties
    ; =========================================================================================
    
    AppendText(pos:="", text:="") {     ; caret is moved, screen not scrolled
        pos := (pos!="")?pos:this.CurPos
        return this._PutStr(0x8EA, pos, text) ; SCI_APPENDTEXT
    }
    Characters(start, end) { ; number of actual chars between "start" and "end" byte pos / see PosRelative() method
        return this._sms(0xA49, start, end) ; SCI_COUNTCHARACTERS
    }
    CharIndex {
        get => this._sms(0xA96)
        set {
            If (value != this._CharIndex) {
                this._sms(0xA98, this._CharIndex)               ; SCI_RELEASELINECHARACTERINDEX
                this._sms(0xA97, (this._CharIndex := value))    ; SCI_ALLOCATELINECHARACTERINDEX
            }
        }
    }
    CodeUnits(start, end) {
        return this._sms(0xA9B, start, end) ; SCI_COUNTCODEUNITS
    }
    Column(pos:="") {
        pos := (pos!="")?pos:this.CurPos ; defaults to getting column at current caret pos
        return this._sms(0x851, pos)     ; SCI_GETCOLUMN
    }
    CurLine { ; returns BYTE pos at the beginning of current line
        get => this.LineFromPos(this.CurPos)
    }
    CurPos { ; returns current BYTE pos, not CHAR pos
        get => this._sms(0x7D8)         ; SCI_GETCURRENTPOS
        set => this._sms(0x7E9, value)  ; SCI_GOTOPOS (selects destroyed, cursor scrolled)
    }
    DeleteRange(start, end) {
        return this._sms(0xA55, start, end) ; SCI_DELETERANGE
    }
    DocLine(visible) {
        return this._sms(0x8AD, visible) ; SCI_DOCLINEFROMVISIBLE
    }
    FindColumn(line, pos) {
        return this._sms(0x998, line, pos)  ; SCI_FINDCOLUMN
    }
    FirstVisibleDocLine {
        get => this.DocLine(this.FirstVisibleLine)
    }
    FirstVisibleLine {
        get => this._sms(0x868) ; SCI_GETFIRSTVISIBLELINE
        set => this._sms(0xA35, value) ; SCI_SETFIRSTVISIBLELINE
    }
    GetChar(pos:="") {
        pos := (pos!="")?pos:this.CurPos
        return (pos<this.Length) ? this.GetTextRange(pos, this.NextCharPos(pos)) : ""
        
        ; return this._sms(0x7D7, pos)    ; SCI_GETCHARAT
    }
    GetTextRange(start, end) {
        tr := Scintilla.TextRange()
        tr.cpMin := start
        tr.cpMax := end
        this._sms(0x872, 0, tr.ptr)     ; SCI_GETTEXTRANGE
        return StrGet(tr.buf, "UTF-8")
    }
    GetStyle(pos:="") {
        pos := (pos!="")?pos:this.CurPos
        return this._sms(0x7DA, pos)    ; SCI_GETSTYLEAT
    }
    InsertText(pos:=-1, text:="") {             ; caret is moved, screen not scrolled
        return this._PutStr(0x7D3, pos, text)   ; SCI_INSERTTEXT
    }
    Length {                            ; document length (bytes)
        get => this._sms(0x7D6)         ; SCI_GETLENGTH
    }
    LineEndPos(line:="") {              ; see .PosFromLine() to get the start of a line
        line := (line!="")?line:this.CurLine
        return this._sms(0x858, line)   ; SCI_GETLINEENDPOSITION
    }
    LineLength(line:="") {
        line := (line!="")?line:this.CurLine
        return this._sms(0x92E, line)   ; SCI_LINELENGTH
    }
    Lines {                             ; number of lines in document
        get => this._sms(0x86A)         ; SCI_GETLINECOUNT
    }
    LineFromPos(pos) {
        return this._sms(0x876, pos)    ; SCI_LINEFROMPOSITION
    }
    LinesOnScreen {
        get => this._sms(0x942)         ; SCI_LINESONSCREEN
    }
    LineText(line:="") {
        line := (line!="")?line:this.CurLine
        len := this._sms(0x869, line) + 2   ; SCI_GETLINE
        buf := Buffer(len, 0)
        this._sms(0x869, line, buf.ptr)     ; SCI_GETLINE
        return StrGet(buf, "UTF-8")
    }
    NextChar(pos, offset:=1) {
        p1 := this.NextCharPos(pos, offset)
        return p1?this.GetChar(p1):""
    }
    NextCharPos(pos, offset:=1) {
        return this._sms(0xA6E, pos, offset) ; SCI_POSITIONRELATIVE
    }
    PointFromPos(pos:="") {
        pos := (pos!="")?pos:this.CurPos
        x := this._sms(0x874,,pos)      ; SCI_POINTXFROMPOSITION
        y := this._sms(0x875,,pos)      ; SCI_POINTYFROMPOSITION
        return {x:x, y:y}
    }
    PosFromLine(line:="") {             ; see .LineEndPos() to get end pos of line
        line := (line!="")?line:this.CurLine
        return this._sms(0x877, line)   ; SCI_POSITIONFROMLINE
    }
    PosFromPoint(x, y) {
        return this._sms(0x7E7, x, y)   ; SCI_POSITIONFROMPOINTCLOSE
    }
    PosFromPointAny(x, y) {
        return this._sms(0x7E6, x, y)   ; SCI_POSITIONFROMPOINT
    }
    PosRelative(pos, length) { ; returns byte pos in doc / length can be negative / See Characters() method
        return this._sms(0xA6E, pos, length) ; SCI_POSITIONRELATIVE
    }
    PrevChar(pos, offset:=-1) {
        p1 := this.NextCharPos(pos, offset)
        return p1?this.GetChar(p1):""
        
        ; return this.GetChar(this.PrevCharPos(pos))
    }
    PrevCharPos(pos, offset:=-1) {
        return this._sms(0xA6E, pos, offset) ; SCI_POSITIONRELATIVE
    }
    ReadOnly {                          ; boolean
        get => this._sms(0x85C)         ; SCI_GETREADONLY
        set => this._sms(0x87B, value)  ; SCI_SETREADONLY
    }
    Text {                              ; gets/sets entire document text
        get => this._GetStr(0x886, this.Length + 1)
        set => this._PutStr(0x885, 0, value)
    }
    TextWidth(txt, style:="") { ; returns pixel width of txt drawn with given style
        style := (style!="")?style:this.Style.ID
        return this._PutStr(0x8E4, style, txt)    ; SCI_TEXTWIDTH
    }
    
    ; =========================================================================================
    ; Scintilla Control Actions
    ; =========================================================================================
    
    Clear() {
        return this._sms(0x884) ; SCI_CLEAR
    }
    ClearAll() {
        return this._sms(0x7D4)         ; SCI_CLEARALL
    }
    Copy() {
        return this._sms(0x882) ; SCI_COPY
    }
    CopyLine() {                ; Same as Copy() when selection is active.
        return this._sms(0x9D7) ; SCI_COPYALLOWLINE
    }
    CopyRange(start, end) {
        return this._sms(0x973, start, end) ; SCI_COPYRANGE
    }
    Cut() {
        return this._sms(0x881) ; SCI_CUT
    }
    Focus() {                           ; GrabFocus(0x960) ... or ... SetFocus(0x94C, bool)
        this._sms(0x960)                ; SCI_GRABFOCUS
    }
    LinesJoin() {                       ; target is assumed to be user selection
        return this._sms(0x8F0)         ; SCI_LINESJOIN
    }
    LinesSplit(pixels) {                ; target is assumed to be user selection
        return this._sms(0x8F1, pixels) ; SCI_LINESSPLIT
    }
    Paste() {
        return this._sms(0x883) ; SCI_PASTE
    }
    SelectAll() {
        return this._sms(0x7DD)         ; SCI_SELECTALL
    }
    VisibleFromDocLine(_in) {
        return this._sms(0x8AC,_in)     ; SCI_VISIBLEFROMDOCLINE
    }
    Zoom {                              ; int points (some measure of "zoom factor" for ZoomIN/OUT commands, default = 0
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
    ; Scintilla Control Undo/Redo
    ; =========================================================================================
    
    AddUndo(token, flags:=1) {                  ; token is sent in SCN_MODIFIED notification
        return this._sms(0xA00, token, flags)   ; SCI_ADDUNDOACTION
    }                                           ; flags: 1=COALESCE, 0=NONE
    
    CanUndo {
        get => this._sms(0x87E) ; SCI_CANUNDO
    }
    CanRedo {
        get => this._sms(0x7E0) ; SCI_CANREDO
    }
    
    BeginUndo() {
        return this._sms(0x81E) ; SCI_BEGINUNDOACTION
    }
    EndUndo() {
        return this._sms(0x81F) ; SCI_ENDUNDOACTION
    }
    Redo() {
        return this._sms(0x7DB) ; SCI_REDO
    }
    Undo() {
        return this._sms(0x880) ; SCI_UNDO
    }
    UndoActive {                        ; bool - enable/disable undo collection
        get => this._sms(0x7E3)         ; SCI_GETUNDOCOLLECTION
        set => this._sms(0x7DC, value)  ; SCI_SETUNDOCOLLECTION
    }
    UndoEmpty() {
        return this._sms(0x87F) ; SCI_EMPTYUNDOBUFFER
    }
    
    ; =========================================================================================
    ; Scintilla Control Status
    ; =========================================================================================
    
    CanPaste {
        get => this._sms(0x87D) ; SCI_CANPASTE
    }
    Focused {                           ; boolean
        get => this._sms(0x94D)         ; SCI_GETFOCUS
    }
    Modified {
        get => this._sms(0x86F)         ; SCI_GETMODIFY
    }
    ; Status {                            ; 0=NONE, 1=GenericFail, 2=MemoryExhausted, 1001=InvalidRegex
        ; get => this._sms(0x94F)         ; SCI_GETSTATUS ; Generally meaning the "error status"
        ; set => this._sms(0x94E, value)  ; SCI_SETSTATUS ; manually set status = 0 to clear
    ; }
    Status {
        get => this._StatusD
    }
    
    ; =========================================================================================
    ; Scintilla Control Settings
    ; =========================================================================================
    
    Accessibility {                     ; int 0 = disabled, 1 = enabled
        get => this._sms(0xA8F)         ; SCI_GETACCESSIBILITY
        set => this._sms(0xA8E, value)  ; SCI_SETACCESSIBILITY
    }
    AutoBraceMatch {                    ; boolean - true/false (default = false)
        get => this._AutoBraceMatch
        set => this._AutoBraceMatch := value
    }
    AutoPunctColor {
        get => this._AutoPunctColor
        set => this._AutoPunctColor := value
    }
    AutoSizeNumberMargin {              ; boolean - true/false (default = false)
        get => this._AutoSizeNumberMargin
        set => this._AutoSizeNumberMargin := value
    }
    BiDirectional {                     ; int 0 = disabled, 1 = Left-to-Right, 2 = Right-to-Left
        get => this._sms(0xA94)         ; SCI_GETBIDIRECTIONAL
        set => this._sms(0xA95, value)  ; SCI_SETBIDIRECTIONAL
    }
    BufferedDraw {                      ; boolean (true = default)
        get => this._sms(0x7F2)         ; SCI_GETBUFFEREDDRAW
        set => this._sms(0x7F3, value)  ; SCI_SETBUFFEREDDRAW
    }
    CodePage {                          ; default = 65001
        get => this._sms(0x859)         ; SCI_GETCODEPAGE
        set => this._sms(0x7F5, value)  ; SCI_SETCODEPAGE
    }
    CommandEvents {                     ; boolean
        get => this._sms(0xA9E)         ; SCI_GETCOMMANDEVENTS
        set => this._sms(0xA9D, value)  ; SCI_SETCOMMANDEVENTS
    }
    Cursor {                            ; int -1 = normal mouse cursor, 7 = wait mouse cursor (1-7 can be used?)
        get => this._sms(0x953)         ; SCI_GETCURSOR
        set => this._sms(0x952, value)  ; SCI_SETCURSOR
    }
    EndAtLastLine {                     ; boolean -> true = don't scroll past last line (default), false = you can
        get => this._sms(0x8E6)         ; SCI_GETENDATLASTLINE
        set => this._sms(0x8E5, value)  ; SCI_SETENDATLASTLINE
    }
    EventMask {                         ; int event mask - scn.modType (modificationType)
        get => this._sms(0x94A)         ; SCI_GETMODEVENTMASK
        set => this._sms(0x937, value)  ; SCI_SETMODEVENTMASK
    }
    FontQuality {                       ; int 0 = Default, 1 = non-anti-aliased, 2 = anti-aliased, 3 = LCD optimized
        get => this._sms(0xA34)         ; SCI_GETFONTQUALITY
        set => this._sms(0xA33, value)  ; SCI_SETFONTQUALITY
    }
    FontLocale {
        get => this._sms(0xAC9)         ; SCI_GETFONTLOCALE
        set => this._sms(0xAC8)         ; SCI_SETFONTLOCALE
    }
    Identifier {                        ; int ID for the control in SCNotifications
        get => this._sms(0xA3F)         ; SCI_GETIDENTIFIER
        set => this._sms(0xA3E, value)  ; SCI_SETIDENTIFIER
    }
    ImeInteraction {                    ; 0 = windowed, 1 = inline
        get => this._sms(0xA76)         ; SCI_GETIMEINTERACTION
        set => this._sms(0xA77, value)  ; SCI_SETIMEINTERACTION
    }
    MouseDownCaptures {                 ; boolean - enable/disable
        get => this._sms(0x951)         ; SCI_GETMOUSEDOWNCAPTURES
        set => this._sms(0x950)         ; SCI_SETMOUSEDOWNCAPTURES
    }
    MouseDwellTime {                    ; int milliseconds / default = 0
        get => this._sms(0x8D9)         ; SCI_GETMOUSEDWELLTIME
        set => this._sms(0x8D8, value)  ; SCI_SETMOUSEDWELLTIME
    }
    MouseWheelCaptures {                ; boolean - enable/disable
        get => this._sms(0xA89)         ; SCI_GETMOUSEWHEELCAPTURES
        set => this._sms(0xA88, value)  ; SCI_SETMOUSEWHEELCAPTURES
    }
    OverType {                          ; bool - enable/disable overtype
        get => this._sms(0x88B)         ; SCI_GETOVERTYPE
        set => this._sms(0x88A, value)  ; SCI_SETOVERTYPE
    }
    PasteConvertEndings {       ; Converts pasted endings to those defined by Scintilla.LineEndings.Mode
        get => this._sms(0x9A4) ; SCI_GETPASTECONVERTENDINGS
        set => this._sms(0x9A3) ; SCI_SETPASTECONVERTENDINGS
    }
    PhaseDraw {                         ; int 1 = two_phases (default), 2 = multiple_phases
        get => this._sms(0x8EB)         ; SCI_GETTWOPHASEDRAW
        set => this._sms(0x8EC, value)  ; SCI_SETTWOPHASEDRAW
    }
    ScrollWidthTracking {               ; boolean - in case non-wrap text extends beyond 2000 chars (default = false)
        get => this._sms(0x9D5)         ; SCI_GETSCROLLWIDTHTRACKING
        set => this._sms(0x9D4, value)  ; SCI_SETSCROLLWIDTHTRACKING
    }
    SetTechnology {                     ; int 0 = GDI (default), 1 = DirectWrite (Direct2D), 2 = DirectWriteRetain
        get => this._sms(0xA47)         ; SCI_GETTECHNOLOGY
        set => this._sms(0xA46, value)  ; SCI_SETTECHNOLOGY
    }
    ScrollH {                           ; boolean / show hide Horizontal scroll bar
        get => this._sms(0x853)         ; SCI_GETHSCROLLBAR
        set => this._sms(0x852, value)  ; SCI_SETHSCROLLBAR
    }
    ScrollV {                           ; boolean / show hide vertical scroll bar
        get => this._sms(0x8E9)         ; SCI_GETVSCROLLBAR
        set => this._sms(0x8E8, value)  ; SCI_GETVSCROLLBAR
    }
    ScrollWidth {                       ; in pixels, default = 2000?
        get => this._sms(0x8E3)         ; SCI_GETSCROLLWIDTH
        set => this._sms(0x8E2, value)  ; SCI_SETSCROLLWIDTH
    }
    SupportsFeature(n) {                ; SCI_SUPPORTSFEATURE
        return this._sms(0xABE, n)      ; 0 = LINE_DRAWS_FINAL, 1 = PIXEL_DIVISIONS, 2 = FRACTIONAL_STROKE_WIDTH
    }                                   ; 3 = TRANSLUCENT_STROKE, 4 = PIXEL_MODIFICATION
    UsePopup { ; int 0 = off, 1 = default, 2 = only on text area
        get => this._UsePopup
        set => this._sms(0x943, (this._UsePopup := value))  ; SCI_USEPOPUP
    }
    
    ; =========================================================================================
    ; Scintilla internals, suggested not to use directly, unless you want advanced contlrol
    ; =========================================================================================
    
    DirectFunc { ; used internally
        get => Scintilla.DirectFunc
    }
    DirectPtr { ; used internally
        get => this._DirectPtr
    }
    DirectStatusFunc { ; used internally
        get => Scintilla.DirectStatusFunc
    }
    
    ; =========================================================================================
    ; Scintilla Control manual direct access
    ; =========================================================================================
    
    CharacterPointer {
        get => this._sms(0x9D8)         ; SCI_GETCHARACTERPOINTER
    }
    GapPosition {
        get => this._sms(0xA54)         ; SCI_GETGAPPOSITION
    }
    RangePointer(start, length) {
        return this._sms(0xA53, start, length) ; SCI_GETRANGEPOINTER
    }
    UseDirect {
        get => this._UseDirect
        set {
            If (!Scintilla.DirectFunc And value=true) ; store in Scintilla class, once per module instance
                Scintilla.DirectFunc := SendMessage(0x888, 0, 0, this.hwnd) ; SCI_GETDIRECTFUNCTION
            
            If (!Scintilla.DirectStatusFunc And value=true)
                Scintilla.DirectStatusFunc := SendMessage(0xAD4, 0, 0, this.hwnd) ; SCI_GETDIRECTSTATUSFUNCTION
            
            If (!this.DirectPtr And value=true) ; store in ctl, call once per control
                this._DirectPtr  := SendMessage(0x889, 0, 0, this.hwnd) ; SCI_GETDIRECTPOINTER
            
            this._UseDirect := value
        }
    }
    
    ; =========================================================================================
    ; Subclasses
    ; =========================================================================================
    
    class Brace extends Scintilla.scint_base {
        Chars := "[]{}()<>"
        
        BadLight(in_pos:=-1) {              ; ctl.Brace.BadLight() <-- with no value, will clear badlight
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
        Match(in_pos) { ; int position (of brace to be matched) ; maxReStyle, 2nd param, must be zero
            return this._sms(0x931, in_pos) ; SCI_BRACEMATCH
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
        GoToPos(pos:="") {                          ; caret new pos is scrolled into view
            pos := (pos!="")?pos:this.ctl.CurPos    ; use current caret pos by default, and destroys selection
            return this._sms(0x7E9, pos)            ; SCI_GOTOPOS
        }
        LineBack { ; SC_ELEMENT_CARET_LINE_BACK = 0x32 (50)
            get => this._sms(0x32)                          ; SCI_GETELEMENTCOLOUR
            set => this._sms(0x32, this._RGB_BGR(value))    ; SCI_GETELEMENTCOLOUR
        }
        ; LineBack {                                          ; color
            ; get => this._RGB_BGR(this._sms(0x831))          ; SCI_GETCARETLINEBACK
            ; set => this._sms(0x832, this._RGB_BGR(value))   ; SCI_SETCARETLINEBACK
        ; }
        ; LineBackAlpha {                     ; 0-255
            ; get => this._sms(0x9A7)         ; SCI_GETCARETLINEBACKALPHA
            ; set => this._sms(0x9A6, value)  ; SCI_SETCARETLINEBACKALPHA
        ; }
        LineFrame {                         ; int width in pixels (0 = disabled)
            get => this._sms(0xA90)         ; SCI_GETCARETLINEFRAME
            set => this._sms(0xA91, value)  ; SCI_SETCARETLINEFRAME
        }
        LineLayer {
            get => this._sms(0xACC)         ; SCI_GETCARETLINELAYER
            set => this._sms(0xACD)         ; SCI_SETCARETLINELAYER
        }
        ; LineVisible {                       ; boolean -> true/false caret line is/is not visible
            ; get => this._sms(0x82F)         ; SCI_GETCARETLINEVISIBLE
            ; set => this._sms(0x830, value)  ; SCI_SETCARETLINEVISIBLE
        ; }
        LineVisibleAlways {                 ; boolean
            get => this._sms(0xA5E)         ; SCI_GETCARETLINEVISIBLEALWAYS
            set => this._sms(0xA5F, value)  ; SCI_GETCARETLINEVISIBLEALWAYS
        }
        Multi {                             ; boolean - default = true
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
        SetPos(pos:="") {                           ; caret new pos is NOT scrolled into view
            pos := (pos!="")?pos:this.ctl.CurPos    ; use current caret pos by default, and just disable selection
            return this._sms(0x9FC, pos)            ; SCI_SETEMPTYSELECTION
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
    
    class Doc extends Scintilla.scint_base {
        AddRef(doc_ptr) {
            return this._sms(0x948, 0, doc_ptr)     ; SCI_ADDREFDOCUMENT
        }
        Create(size, options:=0) {  ; options - 0 = standard / 1 = no styles / 0x100 = allow larger than 2GB
            return this._sms(0x947, size, options)  ; SCI_CREATEDOCUMENT
        }
        Options {
            get => this._sms(0x94B)             ; SCI_GETDOCUMENTOPTIONS
        }
        Ptr {
            get => this._sms(0x935)             ; SCI_GETDOCPOINTER
            set => this._sms(0x936, 0, value)   ; SCI_SETDOCPOINTER
        }
        Release(doc_ptr) {
            return this._sms(0x949, 0, doc_ptr) ; SCI_RELEASEDOCUMENT
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
    
    class EOLAnn extends Scintilla.scint_base {
        Line := 0
        
        ClearAll() {
            return this._sms(0xAB8)                         ; SCI_EOLANNOTATIONCLEARALL
        }
        Style {                                             ; int
            get => this._sms(0xAB7, this.Line)              ; SCI_EOLANNOTATIONGETSTYLE
            set => this._sms(0xAB6, this.Line, value)       ; SCI_EOLANNOTATIONSETSTYLE
        }
        StyleOffset {
            get => this._sms(0xABC)                         ; SCI_EOLANNOTATIONGETSTYLEOFFSET
            set => this._sms(0xABB, value)                  ; SCI_EOLANNOTATIONSETSTYLEOFFSET
        }
        Text {                                              ; string
            get => this._GetStr(0xAB5, this.Line)           ; SCI_EOLANNOTATIONGETTEXT
            set => this._PutStr(0xAB4, this.Line, value)    ; SCI_EOLANNOTATIONSETTEXT
        }
        Visible {                                           ; flag value, see Static sc_eol above
            get => this._sms(0xABA)                         ; SCI_EOLANNOTATIONGETVISIBLE
            set => this._sms(0xAB9, value)                  ; SCI_EOLANNOTATIONSETVISIBLE
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
            get => (0xFF000000 & this._BackColor) ? Format("0x{:08X}", this._BackColor) : Format("0x{:06X}", this._BackColor)
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
            get => (0xFF000000 & this._ForeColor) ? Format("0x{:08X}", this._ForeColor) : Format("0x{:06X}", this._ForeColor)
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
    
    class LineEnding extends Scintilla.scint_base {
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
        _MinWidth := Map()
        _FoldColorEnabled := false
        _FoldColor := 0
        _FoldHiColorEnabled := false
        _FoldHiColor := 0
        
        Back {                                                      ; color
            get => this._RGB_BGR(this._sms(0x8CB, this.ID))         ; SCI_GETMARGINBACKN
            set => this._sms(0x8CA, this.ID, this._RGB_BGR(value))  ; SCI_SETMARGINBACKN
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
            get => (0xFF000000 & this._FoldColor) ? Format("0x{:08X}", this._FoldColor) : Format("0x{:06X}", this._FoldColor)
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
            get => (0xFF000000 & this._FoldHiColor) ? Format("0x{:08X}", this._FoldHiColor) : Format("0x{:06X}", this._FoldHiColor)
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
        MinWidth {
            get => (this._MinWidth.Has(String(this.ID))) ? this._MinWidth[String(this.ID)] : this.ctl.TextWidth("00")+2
            set => this._MinWidth[String(this.ID)] := value
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
        Type {                                      ; int 0 = symbol, 1 = numbers, 2/3 = back/fore, 4/5 = text/rText, 6 = color
            get => this._sms(0x8C1, this.ID)        ; SCI_GETMARGINTYPEN
            set => this._sms(0x8C0, this.ID, value) ; SCI_SETMARGINTYPEN
        }
        Width {                                     ; int pixels
            get => this._sms(0x8C3, this.ID)        ; SCI_GETMARGINWIDTHN
            set => this._sms(0x8C2, this.ID, value) ; SCI_SETMARGINWIDTHN
        }
    }
    
    class Marker extends Scintilla.scint_base {
        num := 0
        _width := 0
        _height := 0
        _scale := 100
        _ForeColor := -1
        _BackColor := -1
        _BackSelectedColor := -1
        _StrokeWidth := 100
        _HighlightEnabled := false
        _Alpha := 255
        
        Add(line, markerNum:="") {                                              ; returns marker handle
            return this._sms(0x7FB, line, (markerNum!="")?markerNum:this.num)   ; SCI_MARKERADD
        }
        AddSet(line, markerMask) {
            return this._sms(0x9A2, line, markerMask)       ; SCI_MARKERADDSET
        }
        Alpha {
            get => this._Alpha
            set => this._sms(0x9AC, (this._Alpha := value))  ; SCI_MARKERSETALPHA
        }
        Back {
            get => (0xFF000000 & this._BackColor) ? Format("0x{:08X}", this._BackColor) : Format("0x{:06X}", this._BackColor)
            set {
                If (0xFF000000 & value)
                    this._sms(0x8F7, this.num, this._RGB_BGR(this._ForeColor := value)) ; SCI_MARKERSETBACKTRANSLUCENT
                Else
                    this._sms(0x7FA, this.num, this._RGB_BGR(this._ForeColor := value)) ; SCI_MARKERSETBACK
            }
        }
        BackSelected {
            get => (0xFF000000 & this._BackSelectedColor) ? Format("0x{:08X}", this._BackSelectedColor) : Format("0x{:06X}", this._BackSelectedColor)
            set {
                If (0xFF000000 & value)
                    this._sms(0x8F8, this.num, this._RGB_BGR(this._ForeColor := value)) ; SCI_MARKERSETBACKSELECTEDTRANSLUCENT
                Else
                    this._sms(0x8F4, this.num, this._RGB_BGR(this._ForeColor := value)) ; SCI_MARKERSETBACKSELECTED
            }
        }
        Delete(line, markerNum:="") {
            return this._sms(0x7FC, line, (markerNum!="")?markerNum:this.num)   ; SCI_MARKERDELETE
        }
        DeleteAll(markerNum:="") {
            return this._sms(0x7FD, (markerNum!="")?markerNum:this.num) ; SCI_MARKERDELETEALL
        }
        DeleteHandle(hMarker) {
            return this._sms(0x7E2, hMarker)    ; SCI_MARKERDELETEHANDLE
        }
        Fore {
            get => (0xFF000000 & this._ForeColor) ? Format("0x{:08X}", this._ForeColor) : Format("0x{:06X}", this._ForeColor)
            set {
                If (0xFF000000 & value)
                    this._sms(0x8F6, this.num, this._RGB_BGR(this._ForeColor := value)) ; SCI_MARKERSETFORETRANSLUCENT
                Else
                    this._sms(0x7F9, this.num, this._RGB_BGR(this._ForeColor := value)) ; SCI_MARKERSETFORE
            }
        }
        Get(line) {
            return this._sms(0x7FE, line)   ; SCI_MARKERGET
        }
        Handle(line, which) {
            return this._sms(0xAAC, line, which)   ; SCI_MARKERHANDLEFROMLINE
        }
        Highlight {
            get => this._HighlightEnabled
            set => this._sms(0x8F5, (this._HighlightEnabled := value))  ; SCI_MARKERENABLEHIGHLIGHT
        }
        Layer {
            get => this._sms(0xAAE)         ; SCI_MARKERGETLAYER
            set => this._sms(0xAAF, value)  ; SCI_MARKERSETLAYER
        }
        Line(hMarker) {
            return this._sms(0x7E1, hMarker)    ; SCI_MARKERLINEFROMHANDLE
        }
        Next(line, markerMask) {                        ; returns line number
            return this._sms(0x7FF, line, markerMask)   ; SCI_MARKERNEXT
        }
        Number(line, which) {
            return this._sms(0xAAD, line, which)    ; SCI_MARKERNUMBERFROMLINE
        }
        PixMap {
            set => this._sms(0x801, this.num, (Type(value)="Buffer")?value.ptr:value) ; SCI_MARKERDEFINEPIXMAP
        }
        Prev(line, markerMask) {                        ; returns line number
            return this._sms(0x800, line, markerMask)   ; SCI_MARKERPREVIOUS
        }
        StrokeWidth {
            get => this._StrokeWidth
            set => this._sms(0x8F9, (this._StrokeWidth := value))   ; SCI_MARKERSETSTROKEWIDTH
        }
        Type {
            get => this._sms(0x9E1, this.num)           ; SCI_MARKERSYMBOLDEFINED
            set => this._sms(0x7F8, this.num, value)    ; SCI_MARKERDEFINE
        }
        ; ========================================================================
        ; RGBA properties
        ; ========================================================================
        Height {
            get => this._height
            set => this._sms(0xA41, this.num, (this._height := value))  ; SCI_RGBAIMAGESETHEIGHT
        }
        Scale {
            get => this._scale
            set => this._sms(0xA5B, this.num, (this._scale := value))   ; SCI_RGBAIMAGESETSCALE
        }
        Width {
            get => this._width
            set => this._sms(0xA40, this.num, (this._width := value))   ; SCI_RGBAIMAGESETWIDTH
        }
        RGBA {
            set => this._sms(0xA42, this.num, (Type(value)="Buffer")?value.ptr:value) ; SCI_MARKERDEFINERGBAIMAGE
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
            get => (0xFF000000 & this._BackColor) ? Format("0x{:08X}", this._BackColor) : Format("0x{:06X}", this._BackColor)
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
            get => (0xFF000000 & this._ForeColor) ? Format("0x{:08X}", this._ForeColor) : Format("0x{:06X}", this._ForeColor)
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
            get => (0xFF000000 & this._MultiBack) ? Format("0x{:08X}", this._MultiBack) : Format("0x{:06X}", this._MultiBack)
            set => this._sms(0xA29, this._RGB_BGR(this._MultiBack := value))  ; SCI_SETADDITIONALSELBACK
        }
        MultiFore {
            get => (0xFF000000 & this._MultiFore) ? Format("0x{:08X}", this._MultiFore) : Format("0x{:06X}", this._MultiFore)
            set => this._sms(0xA28, this._RGB_BGR(this._MultiFore := value))  ; SCI_SETADDITIONALSELFORE
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
        Back {                                                      ; color
            get => this._RGB_BGR(this._sms(0x9B2, this.ID))         ; SCI_STYLEGETBACK
            set => this._sms(0x804, this.ID, this._RGB_BGR(value))  ; SCI_STYLESETBACK
        }
        Bold {                                          ; boolean
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
        Font {                                          ; string
            get => this._GetStr(0x9B6, this.ID)         ; SCI_STYLEGETFONT
            set => this._PutStr(0x808, this.ID, value)  ; SCI_STYLESETFONT
        }
        Fore {                                                      ; color
            get => this._RGB_BGR(this._sms(0x9B1, this.ID))         ; SCI_STYLEGETFORE
            set => this._sms(0x803, this.ID, this._RGB_BGR(value))  ; SCI_STYLESETFORE
        }
        Hotspot {                                   ; boolean
            get => this._sms(0x9BC, this.ID)        ; SCI_STYLEGETCHANGEABLE
            set => this._sms(0x833, this.ID, value) ; SCI_STYLESETCHANGEABLE
        }
        Italic {                                    ; boolean
            get => this._sms(0x9BD, this.ID)        ; SCI_STYLEGETHOTSPOT
            set => this._sms(0x969, this.ID, value) ; SCI_STYLESETHOTSPOT
        }
        ResetDefault() {
            return this._sms(0x80A) ; SCI_STYLERESETDEFAULT
        }
        Size {                                              ; float 0.00
            get => (this._sms(0x80E, this.ID) / 100)        ; SCI_STYLEGETSIZEFRACTIONAL
            set => this._sms(0x80D, this.ID, value * 100)   ; SCI_STYLESETSIZEFRACTIONAL
        }
        Underline {                                     ; boolean
            get => this._sms(0x9B8, this.ID)            ; SCI_STYLEGETUNDERLINE
            set => this._sms(0x80B, this.ID, value)     ; SCI_STYLESETUNDERLINE
        }
        Visible {                                   ; boolean
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
        Idle {                              ; int 0 = NONE, 1 = TOVISIBLE, 2 = AFTERVISIBLE, 3 = ALL
            get => this._sms(0xA85)         ; SCI_GETIDLESTYLING
            set => this._sms(0xA84, value)  ; SCI_SETIDLESTYLING
        }
        Last {
            get => this._sms(0x7EC) ; SCI_GETENDSTYLED
        }
        LineState(line, state:="") {                    ; int - user defined integer?
            If (state="")
                return this._sms(0x82D, line)           ; SCI_GETLINESTATE
            Else
                return this._sms(0x82C, line, state)    ; SCI_SETLINESTATE
        }
        MaxLineState {              ; returns last line with a "state" set
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
        Add(line, pixels) {                         ; int line / pixels
            return this._sms(0xA74, line, pixels)   ; SCI_ADDTABSTOP
        }
        Clear(line) {                       ; int line number
            return this._sms(0xA73, line)   ; SCI_CLEARTABSTOPS
        }
        HighlightGuide {                    ; int: column position where highlight indentation guide for matched braces is
            get => this._sms(0x857)         ; SCI_GETHIGHLIGHTGUIDE
            set => this._sms(0x856, value)  ; SCI_SETHIGHLIGHTGUIDE
        }
        Indents {                           ; boolean - TAB indent without adding space/tab
            get => this._sms(0x8D5)         ; SCI_GETTABINDENTS
            set => this._sms(0x8D4, value)  ; SCI_SETTABINDENTS
        }
        IndentGuides {                      ; int 0 = NONE, 1 = REAL, 2 = LOOKFORWARD, 3 = LOOKBOTH
            get => this._sms(0x855)         ; SCI_GETINDENTATIONGUIDES
            set => this._sms(0x854, value)  ; SCI_SETINDENTATIONGUIDES
        }
        IndentPosition(line) {
            return this._sms(0x850, line)   ; SCI_GETLINEINDENTPOSITION
        }
        LineIndentation(line, spaces:="") {             ; n = line, value = num_of_spaces/columns
            If (spaces="")
                return this._sms(0x84F, line)           ; SCI_GETLINEINDENTATION
            Else
                return this._sms(0x84E, line, spaces)   ; SCI_SETLINEINDENTATION
        }
        MinimumWidth {                      ; int pixels
            get => this._sms(0xAA5)         ; SCI_GETTABMINIMUMWIDTH
            set => this._sms(0xAA4, value)  ; SCI_SETTABMINIMUMWIDTH
        }
        Next(line, pixels_pos) {
            return this._sms(0xA75, line, pixels_pos)   ; SCI_GETNEXTTABSTOP
        }
        Unindents {                         ; boolean - BACKSPACE unindents without removing spaces/tabs
            get => this._sms(0x8D7)         ; SCI_GETBACKSPACEUNINDENTS
            set => this._sms(0x8D6, value)  ; SCI_SETBACKSPACEUNINDENTS
        }
        Use {                               ; bool /// false means use spaces instead of tabs
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
    }
    
    class Target extends Scintilla.scint_base {
        All() {
            return this._sms(0xA82)         ; SCI_TARGETWHOLEDOCUMENT
        }
        ; All() {
            ; return this.SetRange(0, this.ctl.Length)
        ; }
        Anchor() {
            return this._sms(0x93E)         ; SCI_SEARCHANCHOR
        }
        End {                               ; position values
            get => this._sms(0x891)         ; SCI_GETTARGETEND
            set => this._sms(0x890, value)  ; SCI_SETTARGETEND
        }
        EndVS {                             ; position values
            get => this._sms(0xAAB)         ; SCI_GETTARGETENDVIRTUALSPACE
            set => this._sms(0xAAA, value)  ; SCI_SETTARGETENDVIRTUALSPACE
        }
        Flags {                             ; int/DWORD
            get => this._sms(0x897)         ; SCI_GETSEARCHFLAGS
            set => this._sms(0x896, value)  ; SCI_SETSEARCHFLAGS
        }
        Next(txt, flags:="") {                      ; moves search ahead and selects next match range
            flags := (flags!="")?flags:this.Flags
            return this._PutStr(0x93F, flags, txt)  ; SCI_SEARCHNEXT
        }
        Prev(txt, flags:="") {                      ; moves search back from target and selects prev match range
            flags := (flags!="")?flags:this.Flags
            return this._PutStr(0x940, flags, txt)  ; SCI_SEARCHPREV
        }
        Replace(txt:="") {
            return this._PutStr(0x892, StrLen(txt), txt) ; SCI_REPLACETARGET
        }
        Search(txt) {
            len := StrPut(txt, "UTF-8")
            len := ((len-1) != StrLen(txt)) ? len - 2 : len - 1
            return this._SetStr(0x895, len, txt) ; SCI_SEARCHINTARGET
        }
        Selection() {
            return this._sms(0x8EF)         ; SCI_TARGETFROMSELECTION
        }
        SetRange(start, end) {
            return this._sms(0xA7E, start, end) ; SCI_SETTARGETRANGE
        }
        Start {                             ; position values
            get => this._sms(0x88F)         ; SCI_GETTARGETSTART
            set => this._sms(0x88E, value)  ; SCI_SETTARGETSTART
        }
        StartVS {                           ; position values
            get => this._sms(0xAA9)         ; SCI_GETTARGETSTARTVIRTUALSPACE
            set => this._sms(0xAA8, value)  ; SCI_SETTARGETSTARTVIRTUALSPACE
        }
        Tag(n) {                            ; 0 = overall match, tags start at 1
            return this._GetStr(0xA38, n)   ; SCI_GETTAG
        }
        Text {
            get => this._GetStr(0xA7F)      ; SCI_GETTARGETTEXT
        }
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
            get => (0xFF000000 & this._BackColor) ? Format("0x{:08X}", this._BackColor) : Format("0x{:06X}", this._BackColor)
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
            get => (0xFF000000 & this._ForeColor) ? Format("0x{:08X}", this._ForeColor) : Format("0x{:06X}", this._ForeColor)
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
    
    class Word extends Scintilla.scint_base {
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
        __New(ctl) { ; 1st param in subclass is parent class
            this.ctl := ctl
        }
        _GetStr(msg, wParam:=0, reverse:=false) { ; get string with NULL terminator
            buf := Buffer(this._sms(msg, wParam) + 1, 0), out_str := ""
            this._sms(msg, wParam, buf.ptr)
            
            If (reverse)
                Loop (offset := buf.Size - 1)
                    If (_asc := NumGet(buf,offset - (A_Index-1),"UChar"))
                        out_str .= Chr(_asc)
            
            return (reverse) ? out_str : StrGet(buf, "UTF-8")
        }
        _PutStr(msg, wParam:=0, str:="") { ; pass a string with NULL terminator
            buf := Buffer(StrLen(str)+1,0)
            StrPut(str,buf,"UTF-8")
            return this._sms(msg, wParam, buf.ptr)
        }
        _SetStr(msg, wParam:=0, str:="") { ; pass a string without NULL terminator
            buf := Buffer(StrPut(str, "UTF-8"),0)
            StrPut(str,buf,"UTF-8")
            len := (NumGet(buf, buf.size-3, "UShort")=0) ? buf.size - 2 : buf.size - 1 ; remove 1 or 2 NULL terminators
            buf2 := Buffer(len, 0)
            DllCall("RtlMoveMemory", "UPtr", buf2.ptr, "UPtr", buf.ptr, "UPtr", len)
            buf := ""
            return this._sms(msg, wParam, buf2.ptr)
        }
        _RGB_BGR(_in) {
            If (0xFF000000 & _in)
                return Format("0x{:06X}",(_in & 0xFF) << 24 | (_in & 0xFF00) << 8 | (_in & 0xFF0000) >> 8 | (_in >> 24))
            Else
                return Format("0x{:06X}",(_in & 0xFF) << 16 | (_in & 0xFF00) | (_in >> 16))
        }
        _sms(msg, wParam:=0, lParam:=0) {
            obj := (this.__Class = "Scintilla") ? this : this.ctl
            status := 0
            If (obj.UseDirect)
                r := DllCall(obj.DirectStatusFunc, "UInt", obj.DirectPtr, "UInt", msg, "Int", wParam, "Int", lParam, "Int*", &status)
                ; r := DllCall(obj.DirectFunc, "UInt", obj.DirectPtr, "UInt", msg, "Int", wParam, "Int", lParam)
            Else
                r := SendMessage(msg, wParam, lParam, obj.hwnd)
            obj._StatusD := status
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
        __New(ptr := 0) {
            If !ptr {
                this.struct := Buffer(8,0)
                this.ptr := this.struct.ptr
            } Else
                this.ptr := ptr
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
        _ptr := 0
        __New(ptr:=0) {
            If !ptr {
                this.struct := Buffer((A_PtrSize=4)?12:16, 0)
            } Else
                this._ptr := ptr
        }
        _SetBuffer() {
            If (this.cpMax) {
                If (this.cpMax < this.cpMin)
                    throw Error("Invalid range.",,"`r`ncpMin: " this.cpMin "`r`ncpMax: " this.cpMax)
                
                this.buf := Buffer(this.cpMax - this.cpMin + 2, 0)
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
            get => (!this._ptr) ? this.struct.ptr : this._ptr
        }
    }
    
    class SCNotification { ; SCNotification
        __New(ptr := 0) {
            this.ptr := ptr
        }
        hwnd {
            get => NumGet(this.ptr, 0, "UPtr")
        }
        id {
            get => NumGet(this.ptr, Scintilla.scn_id, "UPtr")
        }
        wmmsg {
            get => NumGet(this.ptr, Scintilla.scn_wmmsg, "UInt")
        }
        pos {
            get => NumGet(this.ptr, Scintilla.scn_pos, "Int")
        }
        ch {
            get => NumGet(this.ptr, Scintilla.scn_ch, "Int")
        }
        mod {
            get => NumGet(this.ptr, Scintilla.scn_mod, "Int")
        }
        modType {
            get => NumGet(this.ptr, Scintilla.scn_modType, "Int")
        }
        text {
            get {
                ptr := NumGet(this.ptr, Scintilla.scn_text, "UPtr") ; Specifying length helps as described below:
                return (ptr) ? StrGet(ptr, this.length, "UTF-8") : ""
                    ; return StrGet(ptr, this.length, "UTF-8") ; For some reason the following event adds "r" at the end of paste:
                ; Else                            ; SCN_MODIFIED modType: InsertText StartAction User / modType: 0x2011 / asdfr
                    ; return ""                   ; ?? only "asdf" was pasted...
            }
        }
        length {
            get => NumGet(this.ptr, Scintilla.scn_length, "Int")
        }
        linesAdded {
            get => NumGet(this.ptr, Scintilla.scn_linesAdded, "Int")
        }
        message {
            get => NumGet(this.ptr, Scintilla.scn_message, "Int")
        }
        wParam {
            get => NumGet(this.ptr, Scintilla.scn_wParam, "UPtr")
        }
        lParam {
            get => NumGet(this.ptr, Scintilla.scn_lParam, "Ptr")
        }
        line {
            get => NumGet(this.ptr, Scintilla.scn_line, "Int")
        }
        foldLevelNow {
            get => NumGet(this.ptr, Scintilla.scn_foldLevelNow, "Int")
        }
        foldLevelPrev {
            get => NumGet(this.ptr, Scintilla.scn_foldLevelPrev, "Int")
        }
        margin {
            get => NumGet(this.ptr, Scintilla.scn_margin, "Int")
        }
        listType {
            get => NumGet(this.ptr, Scintilla.scn_listType, "Int")
        }
        x {
            get => NumGet(this.ptr, Scintilla.scn_x, "Int")
        }
        y {
            get => NumGet(this.ptr, Scintilla.scn_y, "Int")
        }
        token {
            get => NumGet(this.ptr, Scintilla.scn_token, "Int")
        }
        annotationLinesAdded {
            get => NumGet(this.ptr, Scintilla.scn_annotationLinesAdded, "Int")
        }
        updated {
            get => NumGet(this.ptr, Scintilla.scn_updated, "Int")
        }
        listCompletionMethod {
            get => NumGet(this.ptr, Scintilla.scn_listCompletionMethod, "Int")
        }
        characterSource {
            get => NumGet(this.ptr, Scintilla.scn_characterSource, "Int")
        }
    }
}

dbg(_in) {
    Loop Parse _in, "`n", "`r"
        OutputDebug "AHK: " A_LoopField
}

; =================================================================================
; Newer Scintilla offsets, where Sci_Position is 8 bytes
; =================================================================================
; struct SCNotification {                 offset         size
    ; struct Sci_NotifyHeader nmhdr;     |0              12/24
    ; Sci_Position position;             |12/24          16/32
    ; int ch;                            |16/32          20/36
    ; int modifiers;                     |20/36          24/40
    ; int modificationType;              |24/40          28/44
    ; const char *text;                  |28/48 <------- 32/56 --- x64 offset    
    ; Sci_Position length;               |32/56          36/64
    ; Sci_Position linesAdded;           |36/64          40/72
    ; int message;                       |40/72          44/76
    ; uptr_t wParam;                     |44/80 <------- 48/88 --- x64 offset    
    ; sptr_t lParam;                     |48/88          52/96
    ; Sci_Position line;                 |52/96          56/104
    ; int foldLevelNow;                  |56/104         60/108
    ; int foldLevelPrev;                 |60/108         64/112
    ; int margin;                        |64/112         68/116
    ; int listType;                      |68/116         72/120
    ; int x;                             |72/120         76/124
    ; int y;                             |76/124         80/128
    ; int token;                         |80/128         84/132
    ; Sci_Position annotationLinesAdded; |84/136 <------ 88/144 --- x64 offset
    ; int updated;                       |88/144         92/148
    ; int listCompletionMethod;          |92/148         96/152
    ; int characterSource;               |96/152         100/156 (x64 size = 160)
; };

; struct SCNotification {
 ; Sci_NotifyHeader nmhdr;
 ; Sci_Position position;
 ; /* SCN_STYLENEEDED, SCN_DOUBLECLICK, SCN_MODIFIED, SCN_MARGINCLICK, */
 ; /* SCN_NEEDSHOWN, SCN_DWELLSTART, SCN_DWELLEND, SCN_CALLTIPCLICK, */
 ; /* SCN_HOTSPOTCLICK, SCN_HOTSPOTDOUBLECLICK, SCN_HOTSPOTRELEASECLICK, */
 ; /* SCN_INDICATORCLICK, SCN_INDICATORRELEASE, */
 ; /* SCN_USERLISTSELECTION, SCN_AUTOCSELECTION */
 ; int ch;
 ; /* SCN_CHARADDED, SCN_KEY, SCN_AUTOCCOMPLETED, SCN_AUTOCSELECTION, */
 ; /* SCN_USERLISTSELECTION */
 ; int modifiers;
 ; /* SCN_KEY, SCN_DOUBLECLICK, SCN_HOTSPOTCLICK, SCN_HOTSPOTDOUBLECLICK, */
 ; /* SCN_HOTSPOTRELEASECLICK, SCN_INDICATORCLICK, SCN_INDICATORRELEASE, */
 ; int modificationType; /* SCN_MODIFIED */
 ; const char *text;
 ; /* SCN_MODIFIED, SCN_USERLISTSELECTION, SCN_AUTOCSELECTION, SCN_URIDROPPED */
 ; Sci_Position length;  /* SCN_MODIFIED */
 ; Sci_Position linesAdded; /* SCN_MODIFIED */
 ; int message; /* SCN_MACRORECORD */
 ; uptr_t wParam; /* SCN_MACRORECORD */
 ; sptr_t lParam; /* SCN_MACRORECORD */
 ; Sci_Position line;  /* SCN_MODIFIED */
 ; int foldLevelNow; /* SCN_MODIFIED */
 ; int foldLevelPrev; /* SCN_MODIFIED */
 ; int margin;  /* SCN_MARGINCLICK */
 ; int listType; /* SCN_USERLISTSELECTION */
 ; int x;   /* SCN_DWELLSTART, SCN_DWELLEND */
 ; int y;  /* SCN_DWELLSTART, SCN_DWELLEND */
 ; int token;  /* SCN_MODIFIED with SC_MOD_CONTAINER */
 ; Sci_Position annotationLinesAdded; /* SCN_MODIFIED with SC_MOD_CHANGEANNOTATION */
 ; int updated; /* SCN_UPDATEUI */
 ; int listCompletionMethod;
 ; /* SCN_AUTOCSELECTION, SCN_AUTOCCOMPLETED, SCN_USERLISTSELECTION, */
 ; int characterSource; /* SCN_CHARADDED */
; };

