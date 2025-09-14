#SingleInstance Force
Persistent

; === Global variables ===
global SelectedHwnd := 0
global IsClickThroughEnabled := false
global ModifiedWindows := Map() ; Track all modified windows
global SavedPositions := Map() ; Track user-saved positions
global gui1 ; Make GUI object accessible to OnMessage handler

; === Create GUI ===
gui1 := Gui("+Resize", "Window Control Tool v1.8")
gui1.SetFont("s9", "Segoe UI")

; Main controls
gui1.Add("Text", "x10 y10", "🔍 Select window to control:")
MyListBox := gui1.Add("ListBox", "x10 y30 w450 h200 VScroll")

; Buttons
btnRefresh := gui1.Add("Button", "x10 y240 w80 h25", "Refresh")
btnHighlight := gui1.Add("Button", "x100 y240 w80 h25", "Highlight")
btnClickThrough := gui1.Add("Button", "x190 y240 w100 h25", "Click-Through")
btnReset := gui1.Add("Button", "x300 y240 w70 h25", "Reset")
btnResetAll := gui1.Add("Button", "x380 y240 w80 h25", "Reset All")

; Current window info
gui1.Add("Text", "x10 y280", "📊 Current window:")
SelectedWindowText := gui1.Add("Text", "x10 y300 w450 h40 Border", "No window selected`n`nSelect a window from the list above")
SelectedWindowText.SetFont("s8")

; Transparency controls
gui1.Add("Text", "x10 y350", "Transparency:")
OpacitySlider := gui1.Add("Slider", "x10 y370 w350 h20 Range50-255 ToolTip", 255)
OpacityValue := gui1.Add("Text", "x370 y372 w50", "100%")
gui1.Add("Button", "x10 y400 w60 h25", "50%").OnEvent("Click", (*) => SetOpacity(127))
gui1.Add("Button", "x80 y400 w60 h25", "75%").OnEvent("Click", (*) => SetOpacity(191))
gui1.Add("Button", "x150 y400 w60 h25", "100%").OnEvent("Click", (*) => SetOpacity(255))

; === Position & Style Controls ===
posGroup := gui1.Add("GroupBox", "x10 y440 w450 h125", "Position & Style")
chkAlwaysOnTop := gui1.Add("Checkbox", "x20 y465", "Always on Top")
btnSavePos := gui1.Add("Button", "x150 y460 w100 h25", "Save Position")
btnRestorePos := gui1.Add("Button", "x260 y460 w100 h25", "Restore Position")
gui1.Add("Text", "x20 y500", "Quick Layouts:")
btnLayoutLeft := gui1.Add("Button", "x110 y495 w70 h25", "Left Half")
btnLayoutRight := gui1.Add("Button", "x190 y495 w70 h25", "Right Half")
btnLayoutCenter := gui1.Add("Button", "x270 y495 w70 h25", "Center")
btnLayoutMaximize := gui1.Add("Button", "x350 y495 w70 h25", "Maximize")

; Options
chkRestoreOnExit := gui1.Add("Checkbox", "x10 y580 Checked", "Restore windows on exit")

; Status bar
StatusBar := gui1.Add("StatusBar",, "Ready | Select a window to begin")

; === Events ===
btnRefresh.OnEvent("Click", RefreshListWithSelection)
btnClickThrough.OnEvent("Click", ToggleClickThrough)
btnHighlight.OnEvent("Click", HighlightWindow)
btnReset.OnEvent("Click", ResetWindow)
btnResetAll.OnEvent("Click", ResetAllWindows)
MyListBox.OnEvent("Change", SetWindow)
MyListBox.OnEvent("DoubleClick", HighlightWindow)
OpacitySlider.OnEvent("Change", ApplyOpacity)
gui1.OnEvent("Close", GuiClose)
gui1.OnEvent("Size", GuiSize)

; === Position & Style Events ===
chkAlwaysOnTop.OnEvent("Click", ToggleAlwaysOnTop)
btnSavePos.OnEvent("Click", SavePosition)
btnRestorePos.OnEvent("Click", RestorePosition)
btnLayoutLeft.OnEvent("Click", (*) => SetWindowLayout("left"))
btnLayoutRight.OnEvent("Click", (*) => SetWindowLayout("right"))
btnLayoutCenter.OnEvent("Click", (*) => SetWindowLayout("center"))
btnLayoutMaximize.OnEvent("Click", (*) => SetWindowLayout("maximize"))

OnMessage(0x0006, GuiActivateHandler) ; WM_ACTIVATE

gui1.Show("w480 h620")
RefreshListWithSelection()

; === Functions ===

GuiActivateHandler(wParam, lParam, msg, hwnd) {
    global gui1
    if (hwnd == gui1.Hwnd && wParam > 0) {
        RefreshListWithSelection()
    }
}

CaptureOriginalState(hwnd) {
    global ModifiedWindows
    if !ModifiedWindows.Has(hwnd) {
        originalOpacity := WinGetTransparent("ahk_id " hwnd)
        exStyle := WinGetExStyle("ahk_id " hwnd)
        originalClickThrough := (exStyle & 0x20) ? true : false
        originalAlwaysOnTop := (exStyle & 0x8) ? true : false
        WinGetPos(&origX, &origY, &origW, &origH, "ahk_id " hwnd)
        
        ModifiedWindows[hwnd] := {
            opacity: originalOpacity, 
            clickThrough: originalClickThrough,
            alwaysOnTop: originalAlwaysOnTop,
            x: origX, y: origY, w: origW, h: origH
        }
    }
}

GuiSize(GuiObj, MinMax, Width, Height) {
    if MinMax = -1
        return
    
    try {
        MyListBox.Move(,, Width - 20, Height - 420)
        SelectedWindowText.Move(,, Width - 20)
        OpacitySlider.Move(,, Width - 130)
        OpacityValue.Move(Width - 110)
        posGroup.Move(,, Width - 20)
        chkRestoreOnExit.Move(10, Height - 40)
    }
    catch {
        ; Ignore error
    }
}

GuiClose(*) {
    global chkRestoreOnExit
    if chkRestoreOnExit.Value {
        RestoreAllWindows()
    }
    ExitApp()
}

RestoreAllWindows() {
    global ModifiedWindows, StatusBar
    count := 0
    tempMap := ModifiedWindows.Clone()
    for hwnd, originalState in tempMap {
        if WinExist("ahk_id " hwnd) {
            try {
                if originalState.opacity == "" {
                    WinSetTransparent("Off", "ahk_id " hwnd)
                } else {
                    WinSetTransparent(originalState.opacity, "ahk_id " hwnd)
                }
                
                WinSetExStyle(originalState.clickThrough ? "+0x20" : "-0x20", "ahk_id " hwnd)
                WinSetAlwaysOnTop(originalState.alwaysOnTop, "ahk_id " hwnd)
                WinMove(originalState.x, originalState.y, originalState.w, originalState.h, "ahk_id " hwnd)
                
                if ModifiedWindows.Has(hwnd) {
                    ModifiedWindows.Delete(hwnd)
                }
                count++
            }
            catch {
                ; Ignore error
            }
        }
    }
    StatusBar.Text := "Restored " count " windows to original state"
}

RefreshListWithSelection(*) {
    global MyListBox, SelectedHwnd, SelectedWindowText, OpacitySlider, StatusBar
    previousSelectedHwnd := SelectedHwnd
    MyListBox.Delete()
    listItems := []
    
    for hwnd in WinGetList() {
        title := WinGetTitle("ahk_id " hwnd)
        style := WinGetStyle("ahk_id " hwnd)
        if (title != "" && !WinGetMinMax("ahk_id " hwnd) && (style & 0x10000000)) {
            displayTitle := title
            if StrLen(displayTitle) > 60 {
                displayTitle := SubStr(displayTitle, 1, 57) . "..."
            }
            listItems.Push(displayTitle " - ID:" hwnd)
        }
    }
    
    if (listItems.Length == 0) {
        StatusBar.Text := "No valid windows found"
        return
    }
    
    MyListBox.Add(listItems)
    StatusBar.Text := "Found " listItems.Length " windows"
    
    if (previousSelectedHwnd && WinExist("ahk_id " previousSelectedHwnd)) {
        for index, itemText in listItems {
            if InStr(itemText, "ID:" previousSelectedHwnd) {
                MyListBox.Choose(index)
                return
            }
        }
    }
    
    SelectedHwnd := 0
    SelectedWindowText.Text := "No window selected`n`nSelect a window from the list above"
    OpacitySlider.Value := 255
    UpdateOpacityDisplay()
}

SetWindow(*) {
    global SelectedHwnd, MyListBox, SelectedWindowText, IsClickThroughEnabled, OpacitySlider, StatusBar, chkAlwaysOnTop
    if MyListBox.Text = "" || !RegExMatch(MyListBox.Text, "ID:(\d+)", &m) {
        return
    }
    
    SelectedHwnd := m[1]
    
    CaptureOriginalState(SelectedHwnd)

    title := WinGetTitle("ahk_id " SelectedHwnd)
    
    displayTitle := title
    if StrLen(displayTitle) > 50 {
        displayTitle := SubStr(displayTitle, 1, 47) . "..."
    }
    SelectedWindowText.Text := "Title: " displayTitle "`nHWND: " SelectedHwnd
    
    currentOpacity := WinGetTransparent("ahk_id " SelectedHwnd)
    OpacitySlider.Value := (currentOpacity == "" ? 255 : currentOpacity)
    UpdateOpacityDisplay()
    
    exStyle := WinGetExStyle("ahk_id " SelectedHwnd)
    IsClickThroughEnabled := (exStyle & 0x20)
    
    chkAlwaysOnTop.Value := (exStyle & 0x8)
    
    StatusBar.Text := "Selected: " displayTitle
}

SetOpacity(value) {
    global OpacitySlider
    OpacitySlider.Value := value
    ApplyOpacity()
}

UpdateOpacityDisplay() {
    global OpacitySlider, OpacityValue
    percentage := Round((OpacitySlider.Value / 255) * 100)
    OpacityValue.Text := percentage "%"
}

ApplyOpacity(*) {
    global SelectedHwnd, OpacitySlider, StatusBar
    if !SelectedHwnd {
        return
    }
    
    WinSetTransparent(OpacitySlider.Value, "ahk_id " SelectedHwnd)
    UpdateOpacityDisplay()
    
    percentage := Round((OpacitySlider.Value / 255) * 100)
    StatusBar.Text := "Opacity set to " percentage "% for selected window"
}

ToggleClickThrough(*) {
    global SelectedHwnd, IsClickThroughEnabled, StatusBar
    if !SelectedHwnd {
        MsgBox("Please select a window first.",, "Icon! 0x30")
        return
    }
    
    try {
        WinSetExStyle("Toggle", "ahk_id " SelectedHwnd)
        IsClickThroughEnabled := !IsClickThroughEnabled
        StatusBar.Text := "Click-through " (IsClickThroughEnabled ? "ENABLED" : "DISABLED")
    }
    catch as e {
        MsgBox("Failed to toggle click-through: " e.message, "Error", "Icon! 0x10")
    }
}

ResetWindow(*) {
    global SelectedHwnd, StatusBar, ModifiedWindows
    if !SelectedHwnd {
        MsgBox("Please select a window first.",, "Icon! 0x30")
        return
    }
    
    try {
        if ModifiedWindows.Has(SelectedHwnd) {
            originalState := ModifiedWindows[SelectedHwnd]
            
            if originalState.opacity == "" {
                WinSetTransparent("Off", "ahk_id " SelectedHwnd)
            } else {
                WinSetTransparent(originalState.opacity, "ahk_id " SelectedHwnd)
            }
            
            WinSetExStyle(originalState.clickThrough ? "+0x20" : "-0x20", "ahk_id " SelectedHwnd)
            WinSetAlwaysOnTop(originalState.alwaysOnTop, "ahk_id " SelectedHwnd)
            WinMove(originalState.x, originalState.y, originalState.w, originalState.h, "ahk_id " SelectedHwnd)

            ModifiedWindows.Delete(SelectedHwnd)
            SetWindow()
            StatusBar.Text := "Window properties reset to original state"
            MsgBox("Window '" originalState.title "' has been reset.", "Reset Complete", "Icon! 0x40")
        } else {
            StatusBar.Text := "Window was not modified."
        }
    }
    catch as e {
        MsgBox("Failed to reset window: " e.message, "Error", "Icon! 0x10")
    }
}

ResetAllWindows(*) {
    global ModifiedWindows
    if ModifiedWindows.Count == 0 {
        MsgBox("No modified windows to reset.",, "Icon! 0x30")
        return
    }
    
    result := MsgBox("This will reset ALL " ModifiedWindows.Count " modified windows to their original state.`n`nContinue?",, "YesNo Icon! 0x20")
    if result == "Yes" {
        RestoreAllWindows()
        MsgBox("All modified windows have been reset.",, "Icon! 0x40")
        RefreshListWithSelection()
    }
}

HighlightWindow(*) {
    global SelectedHwnd, StatusBar
    if !SelectedHwnd {
        MsgBox("Please select a window first.",, "Icon! 0x30")
        return
    }
    
    try {
        WinActivate("ahk_id " SelectedHwnd)
        originalOpacity := WinGetTransparent("ahk_id " SelectedHwnd)
        originalOpacity := (originalOpacity == "" ? 255 : originalOpacity)
        
        Loop 2 {
            WinSetTransparent(100, "ahk_id " SelectedHwnd)
            Sleep(150)
            WinSetTransparent(255, "ahk_id " SelectedHwnd)
            Sleep(150)
        }
        WinSetTransparent(originalOpacity, "ahk_id " SelectedHwnd)
        StatusBar.Text := "Window highlighted and activated"
    }
    catch as e {
        MsgBox("Failed to highlight window: " e.message, "Error", "Icon! 0x10")
    }
}

ToggleAlwaysOnTop(*) {
    global SelectedHwnd, StatusBar, chkAlwaysOnTop
    if !SelectedHwnd {
        chkAlwaysOnTop.Value := !chkAlwaysOnTop.Value
        MsgBox("Please select a window first.",, "Icon! 0x30")
        return
    }
    
    WinSetAlwaysOnTop(-1, "ahk_id " SelectedHwnd)
    isNowOnTop := (WinGetExStyle("ahk_id " SelectedHwnd) & 0x8)
    StatusBar.Text := "Always on Top " (isNowOnTop ? "ENABLED" : "DISABLED")
}

SavePosition(*) {
    global SelectedHwnd, SavedPositions, StatusBar
    if !SelectedHwnd {
        MsgBox("Please select a window first.",, "Icon! 0x30")
        return
    }
    
    WinGetPos(&x, &y, &w, &h, "ahk_id " SelectedHwnd)
    SavedPositions[SelectedHwnd] := {x: x, y: y, w: w, h: h}
    StatusBar.Text := "Position saved: X=" x ", Y=" y ", W=" w ", H=" h
}

RestorePosition(*) {
    global SelectedHwnd, SavedPositions, StatusBar
    if !SelectedHwnd {
        MsgBox("Please select a window first.",, "Icon! 0x30")
        return
    }
    
    if !SavedPositions.Has(SelectedHwnd) {
        MsgBox("Position was not saved for this window yet.",, "Icon! 0x30")
        return
    }
    
    savedPos := SavedPositions[SelectedHwnd]
    WinMove(savedPos.x, savedPos.y, savedPos.w, savedPos.h, "ahk_id " SelectedHwnd)
    StatusBar.Text := "Position restored to: X=" savedPos.x ", Y=" savedPos.y
}

SetWindowLayout(layout) {
    global SelectedHwnd, StatusBar
    if !SelectedHwnd {
        MsgBox("Please select a window first.",, "Icon! 0x30")
        return
    }
    
    primaryMonitor := MonitorGetPrimary()
    MonitorGetWorkArea(primaryMonitor, &monX, &monY, &monRight, &monBottom)
    monWidth := monRight - monX
    monHeight := monBottom - monY

    if (layout == "left") {
        WinMove(monX, monY, monWidth / 2, monHeight, "ahk_id " SelectedHwnd)
        StatusBar.Text := "Window moved to the left half."
    } else if (layout == "right") {
        WinMove(monX + monWidth / 2, monY, monWidth / 2, monHeight, "ahk_id " SelectedHwnd)
        StatusBar.Text := "Window moved to the right half."
    } else if (layout == "center") {
        WinGetPos(&x, &y, &w, &h, "ahk_id " SelectedHwnd)
        newX := monX + (monWidth - w) / 2
        newY := monY + (monHeight - h) / 2
        WinMove(newX, newY, , , "ahk_id " SelectedHwnd)
        StatusBar.Text := "Window centered."
    } else if (layout == "maximize") {
        WinMaximize("ahk_id " SelectedHwnd)
        StatusBar.Text := "Window maximized."
    }
}