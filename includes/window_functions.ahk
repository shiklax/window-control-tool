; ===========================================
; === MODUŁ: window_functions.ahk ===
; ===========================================

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
        style := WinGetStyle("ahk_id " hwnd)
        originalClickThrough := (exStyle & 0x20) ? true : false
        originalAlwaysOnTop := (exStyle & 0x8) ? true : false
        originalHasBorder := (style & 0x00C40000)
        WinGetPos(&origX, &origY, &origW, &origH, "ahk_id " hwnd)
        
        ModifiedWindows[hwnd] := {
            opacity: originalOpacity, 
            clickThrough: originalClickThrough,
            alwaysOnTop: originalAlwaysOnTop,
            hasBorder: originalHasBorder,
            x: origX, y: origY, w: origW, h: origH,
            title: WinGetTitle("ahk_id " hwnd)
        }
    }
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
                if originalState.hasBorder {
                    WinSetStyle("+0xC40000", "ahk_id " hwnd)
                }
                WinMove(originalState.x, originalState.y, originalState.w, originalState.h, "ahk_id " hwnd)
                
                if ModifiedWindows.Has(hwnd) {
                    ModifiedWindows.Delete(hwnd)
                }
                count++
            }
            catch {
                ; Ignore window-gone errors
            }
        }
    }
    StatusBar.Text := "Restored " count " windows to original state"
}

RefreshListWithSelection(*) {
    global MyListBox, SelectedHwnd, SelectedWindowText, OpacitySlider, StatusBar, gui1, editX, editY, editW, editH, BlacklistFile

    blacklist := Map()
    try {
        keys := IniRead(BlacklistFile, "Blacklist")
        Loop Parse, keys, "`n", "`r" {
            if (A_LoopField != "") {
                keyParts := StrSplit(A_LoopField, "=")
                blacklist[keyParts[1]] := true
            }
        }
    }
    catch
    {
        ; Ignorujemy błąd, jeśli plik lub sekcja nie istnieje.
    }

    previousSelectedHwnd := SelectedHwnd
    MyListBox.Delete()
    listItems := []
    
    for hwnd in WinGetList() {
        title := WinGetTitle("ahk_id " hwnd)
        style := WinGetStyle("ahk_id " hwnd)

        if (title != "" && WinGetMinMax("ahk_id " hwnd) != -1 && (style & 0x10000000) && (hwnd != gui1.Hwnd)) {
            processName := ""
            
            ; === POPRAWNIE SFORMATOWANY BLOK TRY...CATCH ===
            try {
                processName := WinGetProcessName("ahk_id " hwnd)
            }
            catch
            {
                processName := "<Protected Process>"
            }

            blacklistKey := processName . "|" . title
            
            if !blacklist.Has(blacklistKey) {
                displayTitle := title
                if StrLen(displayTitle) > 50 {
                    displayTitle := SubStr(displayTitle, 1, 47) . "..."
                }
                listItems.Push("[" processName "] " displayTitle " - ID:" hwnd)
            }
        }
    }
    
    if (listItems.Length == 0) {
        MyListBox.Add(["No valid windows found."])
        StatusBar.Text := "No valid windows found or all are hidden"
    }
    else
    {
        MyListBox.Add(listItems)
        StatusBar.Text := "Found " listItems.Length " windows"
    }
    
    if (previousSelectedHwnd && WinExist("ahk_id " previousSelectedHwnd)){ ; Dodatkowe zabezpieczenie
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
    editX.Value := ""
    editY.Value := ""
    editW.Value := ""
    editH.Value := ""
}
SetWindow(*) {
    global SelectedHwnd, MyListBox, SelectedWindowText, OpacitySlider, StatusBar, editX, editY, editW, editH
    
    currentSelection := MyListBox.Text
    if (currentSelection = "" || currentSelection = "No valid windows found." || !RegExMatch(currentSelection, "ID:(\d+)$", &m)) {
        return
    }
    
    SelectedHwnd := m[1]
    
    CaptureOriginalState(SelectedHwnd)

    title := WinGetTitle("ahk_id " SelectedHwnd)
    processName := ""
    try {
        processName := WinGetProcessName("ahk_id " SelectedHwnd)
    } catch {
        processName := "<Protected Process>"
    }
    
    displayTitle := title
    if StrLen(displayTitle) > 50 {
        displayTitle := SubStr(displayTitle, 1, 47) . "..."
    }
    SelectedWindowText.Text := "Title: " displayTitle "`nProcess: " processName "`nHWND: " SelectedHwnd
    
    currentOpacity := WinGetTransparent("ahk_id " SelectedHwnd)
    OpacitySlider.Value := (currentOpacity == "" ? 255 : currentOpacity)
    UpdateOpacityDisplay()
    
    WinGetPos(&x, &y, &w, &h, "ahk_id " SelectedHwnd)
    editX.Value := x
    editY.Value := y
    editW.Value := w
    editH.Value := h
    
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
    global SelectedHwnd, StatusBar
    if !SelectedHwnd {
        MsgBox("Please select a window first.",, "Icon! 0x30")
        return
    }
    
    try {
        WinSetExStyle("+0x80000", "ahk_id " SelectedHwnd)
        WinSetExStyle("^0x20", "ahk_id " SelectedHwnd)
        
        isNowClickThrough := (WinGetExStyle("ahk_id " SelectedHwnd) & 0x20)
        StatusBar.Text := "Click-through " (isNowClickThrough ? "ENABLED" : "DISABLED")
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
            WinSetAlwaysOnTop(originalState.alwaysOnTop, "ahk_id " SelectedHwnd) ; <-- POPRAWKA (było hwnd)
            
            if originalState.hasBorder {
                WinSetStyle("+0xC40000", "ahk_id " SelectedHwnd) ; <-- POPRAWKA (było hwnd)
            }
            WinMove(originalState.x, originalState.y, originalState.w, originalState.h, "ahk_id " SelectedHwnd) ; <-- POPRAWKA (było hwnd)

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
    global SelectedHwnd, StatusBar, gui1
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
        WinActivate("ahk_id " gui1.Hwnd)
        StatusBar.Text := "Window highlighted. Control Tool is now active."
    }
    catch as e {
        MsgBox("Failed to highlight window: " e.message, "Error", "Icon! 0x10")
    }
}

ToggleAlwaysOnTop(*) {
    global SelectedHwnd, StatusBar
    if !SelectedHwnd {
        MsgBox("Please select a window first.",, "Icon! 0x30")
        return
    }
    
    WinSetAlwaysOnTop(-1, "ahk_id " SelectedHwnd)
    isNowOnTop := (WinGetExStyle("ahk_id " SelectedHwnd) & 0x8)
    StatusBar.Text := "Always on Top " (isNowOnTop ? "ENABLED" : "DISABLED")
}

ApplyManualChanges(*) {
    global SelectedHwnd, StatusBar, editX, editY, editW, editH
    if !SelectedHwnd {
        MsgBox("Please select a window first.",, "Icon! 0x30")
        return
    }

    WinGetPos(&currentX, &currentY, &currentW, &currentH, "ahk_id " SelectedHwnd)

    x := editX.Value != "" ? EvalExpr(editX.Value) : currentX
    y := editY.Value != "" ? EvalExpr(editY.Value) : currentY
    w := editW.Value != "" ? EvalExpr(editW.Value) : currentW
    h := editH.Value != "" ? EvalExpr(editH.Value) : currentH

    if (x = "" || y = "" || w = "" || h = "") {
        MsgBox("One or more values is not a valid number or expression.", "Error", "Icon! 0x10")
        return
    }
    x := Round(x)
    y := Round(y)
    w := Round(w)
    h := Round(h)
    if (w <= 0 || h <= 0) {
        MsgBox("Width and height must be positive numbers.", "Error", "Icon! 0x10")
        return
    }

    try {
        WinMove(x, y, w, h, "ahk_id " SelectedHwnd)
        StatusBar.Text := "Position and size applied: " x "," y " " w "x" h
        
        editX.Value := x
        editY.Value := y
        editW.Value := w
        editH.Value := h
        
    } catch as e {
        MsgBox("Failed to apply changes: " e.message, "Error", "Icon! 0x10")
    }
}

SetWindowLayout(layout) {
    global SelectedHwnd, StatusBar, editX, editY, editW, editH
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
    } else if (layout == "right") {
        WinMove(monX + monWidth / 2, monY, monWidth / 2, monHeight, "ahk_id " SelectedHwnd)
    } else if (layout == "center") {
        WinGetPos(&x, &y, &w, &h, "ahk_id " SelectedHwnd)
        newX := monX + (monWidth - w) / 2
        newY := monY + (monHeight - h) / 2
        WinMove(newX, newY, , , "ahk_id " SelectedHwnd)
    }

    StatusBar.Text := "Layout applied: " . layout
    
    WinGetPos(&x, &y, &w, &h, "ahk_id " SelectedHwnd)
    editX.Value := x
    editY.Value := y
    editW.Value := w
    editH.Value := h
}

ToggleBorderless(*) {
    global SelectedHwnd, StatusBar
    if !SelectedHwnd {
        MsgBox("Please select a window first.",, "Icon! 0x30")
        return
    }
    CaptureOriginalState(SelectedHwnd)
    WinSetStyle("^0xC40000", "ahk_id " SelectedHwnd)
    StatusBar.Text := "Toggled borderless mode."
}