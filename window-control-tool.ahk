#SingleInstance Force
Persistent
#Include "MathEvaluator.ahk"
; === Global variables ===
global SelectedHwnd := 0
global IsClickThroughEnabled := false
global ModifiedWindows := Map()
global SavedPositions := Map()
global gui1
global ProfileFile := A_ScriptDir . "\WindowProfiles.ini"

; === Create GUI ===
gui1 := Gui("+Resize", "Window Control Tool v4.7")
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
SelectedWindowText := gui1.Add("Text", "x10 y300 w450 h60 Border", "No window selected`n`nSelect a window from the list above")
SelectedWindowText.SetFont("s8")

; Transparency controls
gui1.Add("Text", "x10 y370", "Transparency:")
OpacitySlider := gui1.Add("Slider", "x10 y390 w350 h20 Range50-255 ToolTip", 255)
OpacityValue := gui1.Add("Text", "x370 y392 w50", "100%")
gui1.Add("Button", "x10 y420 w60 h25", "50%").OnEvent("Click", (*) => SetOpacity(127))
gui1.Add("Button", "x80 y420 w60 h25", "75%").OnEvent("Click", (*) => SetOpacity(191))
gui1.Add("Button", "x150 y420 w60 h25", "100%").OnEvent("Click", (*) => SetOpacity(255))

; === Position & Style Controls ===
posGroup := gui1.Add("GroupBox", "x10 y460 w450 h85", "General Controls")
btnAlwaysOnTop := gui1.Add("Button", "x20 y485 w110 h25", "Always on Top")
btnBorderless := gui1.Add("Button", "x140 y485 w110 h25", "Toggle Borderless")
gui1.Add("Text", "x20 y520", "Quick Layouts:")
btnLayoutLeft := gui1.Add("Button", "x110 y515 w70 h25", "Left Half")
btnLayoutRight := gui1.Add("Button", "x190 y515 w70 h25", "Right Half")
btnLayoutCenter := gui1.Add("Button", "x270 y515 w70 h25", "Center")
btnLayoutMaximize := gui1.Add("Button", "x350 y515 w70 h25", "Maximize")

; === Manual Position & Size ===
manGroup := gui1.Add("GroupBox", "x10 y555 w450 h85", "Manual Position & Size")
gui1.Add("Text", "x20 y580", "X:")
editX := gui1.Add("Edit", "x40 y575 w60 h25 vEditX")
gui1.Add("Text", "x110 y580", "Y:")
editY := gui1.Add("Edit", "x130 y575 w60 h25 vEditY")
gui1.Add("Text", "x200 y580", "W:")
editW := gui1.Add("Edit", "x220 y575 w60 h25 vEditW")
gui1.Add("Text", "x290 y580", "H:")
editH := gui1.Add("Edit", "x310 y575 w60 h25 vEditH")
btnApplyManual := gui1.Add("Button", "x380 y575 w80 h25", "Apply")

; === Saved Profiles ===
profGroup := gui1.Add("GroupBox", "x10 y650 w450 h60", "Position Profiles")
ProfileList := gui1.Add("DropDownList", "x20 y670 w200 h150 vProfileList Choose1")
btnLoadProfile := gui1.Add("Button", "x230 y668 w70 h25", "Load")
btnSaveProfile := gui1.Add("Button", "x310 y668 w70 h25", "Save")
btnDeleteProfile := gui1.Add("Button", "x390 y668 w70 h25", "Delete")

; Options
chkRestoreOnExit := gui1.Add("Checkbox", "x10 y725 Checked", "Restore windows on exit")

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
btnAlwaysOnTop.OnEvent("Click", ToggleAlwaysOnTop)
btnLayoutLeft.OnEvent("Click", (*) => SetWindowLayout("left"))
btnLayoutRight.OnEvent("Click", (*) => SetWindowLayout("right"))
btnLayoutCenter.OnEvent("Click", (*) => SetWindowLayout("center"))
btnLayoutMaximize.OnEvent("Click", (*) => SetWindowLayout("maximize"))
btnBorderless.OnEvent("Click", ToggleBorderless)
btnApplyManual.OnEvent("Click", ApplyManualChanges)
btnLoadProfile.OnEvent("Click", LoadProfile)
btnSaveProfile.OnEvent("Click", SaveProfile)
btnDeleteProfile.OnEvent("Click", DeleteProfile)

OnMessage(0x0006, GuiActivateHandler) ; WM_ACTIVATE

LoadProfilesFromFile()
gui1.Show("w480 h765")
UpdateProfileList()
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
            title: WinGetTitle("ahk_id " hwnd) ; <-- KLUCZOWA POPRAWKA
        }
    }
}

GuiSize(GuiObj, MinMax, Width, Height) {
    if MinMax = -1
        return
    
    try {
        MyListBox.Move(,, Width - 20, Height - 565)
        SelectedWindowText.Move(,, Width - 20)
        OpacitySlider.Move(,, Width - 130)
        OpacityValue.Move(Width - 110)
        posGroup.Move(,, Width - 20)
        manGroup.Move(,, Width - 20)
        profGroup.Move(,, Width - 20)
        chkRestoreOnExit.Move(10, Height - 40)
    }
    catch {
        ; Ignore resize errors
    }
}

GuiClose(*) {
    global chkRestoreOnExit
    if chkRestoreOnExit.Value {
        RestoreAllWindows()
    }
    SaveProfilesToFile()
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
    global MyListBox, SelectedHwnd, SelectedWindowText, OpacitySlider, StatusBar, gui1, editX, editY, editW, editH
    previousSelectedHwnd := SelectedHwnd
    MyListBox.Delete()
    listItems := []
    
    for hwnd in WinGetList() {
        title := WinGetTitle("ahk_id " hwnd)
        style := WinGetStyle("ahk_id " hwnd)
        if (title != "" && !WinGetMinMax("ahk_id " hwnd) && (style & 0x10000000) && (hwnd != gui1.Hwnd)) {
            processName := ""
            try {
                processName := WinGetProcessName("ahk_id " hwnd)
            }
            catch {
                processName := "<Protected Process>"
            }

            displayTitle := title
            if StrLen(displayTitle) > 50 {
                displayTitle := SubStr(displayTitle, 1, 47) . "..."
            }
            listItems.Push("[" processName "] " displayTitle " - ID:" hwnd)
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
    editX.Value := ""
    editY.Value := ""
    editW.Value := ""
    editH.Value := ""
}

SetWindow(*) {
    global SelectedHwnd, MyListBox, SelectedWindowText, IsClickThroughEnabled, OpacitySlider, StatusBar
    global editX, editY, editW, editH
    
    if MyListBox.Text = "" || !RegExMatch(MyListBox.Text, "ID:(\d+)$", &m) {
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
    
    exStyle := WinGetExStyle("ahk_id " SelectedHwnd)
    IsClickThroughEnabled := (exStyle & 0x20)

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
    global SelectedHwnd, IsClickThroughEnabled, StatusBar
    if !SelectedHwnd {
        MsgBox("Please select a window first.",, "Icon! 0x30")
        return
    }
    
    try {
        if IsClickThroughEnabled {
            WinSetExStyle("-0x20", "ahk_id " SelectedHwnd)
            StatusBar.Text := "Click-through DISABLED"
        } else {
            WinSetExStyle("+0x20", "ahk_id " SelectedHwnd)
            StatusBar.Text := "Click-through ENABLED"
        }
        IsClickThroughEnabled := !IsClickThroughEnabled
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
            if originalState.hasBorder {
                WinSetStyle("+0xC40000", "ahk_id " SelectedHwnd)
            }
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
    if ModifiedWindows.Count == 0 {
        MsgBox("No modified windows to reset.",, "Icon! 0x30")
        return
    }
    
    result := MsgBox("This will reset ALL " ModifiedWindows.Count " modified windows to their original state.`n`nContinue?",, "YesNo Icon! 0x20")
    if result == "Yes" {
        RestoreAllWindows()
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

    ; Get current window position for relative calculations
    WinGetPos(&currentX, &currentY, &currentW, &currentH, "ahk_id " SelectedHwnd)

    ; Evaluate expressions or use current values if empty
    x := editX.Value != "" ? EvalExpr(editX.Value) : currentX
    y := editY.Value != "" ? EvalExpr(editY.Value) : currentY
    w := editW.Value != "" ? EvalExpr(editW.Value) : currentW
    h := editH.Value != "" ? EvalExpr(editH.Value) : currentH

    ; Check if any evaluation failed
    if (x = "" || y = "" || w = "" || h = "") {
        MsgBox("One or more values is not a valid number or expression.`n`nExamples:`n• 100`n• 300+50`n• 200*2`n• 1920/2`n• (800+200)/2", "Error", "Icon! 0x10")
        return
    }

    ; Convert to integers (WinMove requires integers)
    x := Round(x)
    y := Round(y)
    w := Round(w)
    h := Round(h)

    ; Validate dimensions (must be positive)
    if (w <= 0 || h <= 0) {
        MsgBox("Width and height must be positive numbers.", "Error", "Icon! 0x10")
        return
    }

    ; Apply new position and size
    try {
        WinMove(x, y, w, h, "ahk_id " SelectedHwnd)
        StatusBar.Text := "Position and size applied: " x "," y " " w "x" h
        
        ; Update the edit boxes with the actual values
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
    } else if (layout == "maximize") {
        WinMaximize("ahk_id " SelectedHwnd)
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

UpdateProfileList() {
    global SavedPositions, ProfileList
    ProfileList.Delete()
    profileNames := []
    for name in SavedPositions {
        profileNames.Push(name)
    }
    if profileNames.Length > 0 {
        ProfileList.Add(profileNames)
        ProfileList.Choose(1)
    }
}

SaveProfile(*) {
    global SelectedHwnd, SavedPositions, StatusBar
    if !SelectedHwnd {
        MsgBox("Please select a window to save its state.",, "Icon! 0x30")
        return
    }
    
    profileName := InputBox("Enter a name for this window state profile:", "Save Profile").Value
    if (profileName = "") {
        return
    }
    
    WinGetPos(&x, &y, &w, &h, "ahk_id " SelectedHwnd)
    opacity := WinGetTransparent("ahk_id " SelectedHwnd)
    opacity := (opacity = "" ? 255 : opacity)
    exStyle := WinGetExStyle("ahk_id " SelectedHwnd)
    style := WinGetStyle("ahk_id " SelectedHwnd)
    
    SavedPositions[profileName] := {
        x: x, y: y, w: w, h: h,
        opacity: opacity,
        clickThrough: (exStyle & 0x20) ? true : false,
        alwaysOnTop: (exStyle & 0x8) ? true : false,
        hasBorder: (style & 0x00C40000) ? true : false
    }

    SaveProfilesToFile() ; <-- KLUCZOWA ZMIANA: Zapisz zmiany do pliku natychmiast

    StatusBar.Text := "Profile '" profileName "' saved."
    UpdateProfileList()
}

LoadProfile(*) {
    global SelectedHwnd, SavedPositions, StatusBar, ProfileList, editX, editY, editW, editH, OpacitySlider
    if !SelectedHwnd {
        MsgBox("Please select a window to apply the profile to.",, "Icon! 0x30")
        return
    }
    
    profileName := ProfileList.Text
    if (profileName = "" || !SavedPositions.Has(profileName)) {
        MsgBox("Please select a valid profile from the list.",, "Icon! 0x30")
        return
    }
    
    savedState := SavedPositions[profileName]
    
    WinMove(savedState.x, savedState.y, savedState.w, savedState.h, "ahk_id " SelectedHwnd)
    WinSetTransparent(savedState.opacity, "ahk_id " SelectedHwnd)
    WinSetExStyle(savedState.clickThrough ? "+0x20" : "-0x20", "ahk_id " SelectedHwnd)
    WinSetAlwaysOnTop(savedState.alwaysOnTop, "ahk_id " SelectedHwnd)
    WinSetStyle(savedState.hasBorder ? "+0xC40000" : "-0xC40000", "ahk_id " SelectedHwnd)
    
    editX.Value := savedState.x
    editY.Value := savedState.y
    editW.Value := savedState.w
    editH.Value := savedState.h
    OpacitySlider.Value := savedState.opacity
    UpdateOpacityDisplay()
    
    StatusBar.Text := "Profile '" profileName "' loaded."
}

DeleteProfile(*) {
    global SavedPositions, StatusBar, ProfileList
    profileName := ProfileList.Text
    if (profileName = "" || !SavedPositions.Has(profileName)) {
        MsgBox("Please select a valid profile to delete.",, "Icon! 0x30")
        return
    }
    
    result := MsgBox("Are you sure you want to delete the profile '" profileName "'?",, "YesNo Icon? 0x20")
    if result == "Yes" {
        SavedPositions.Delete(profileName)
        SaveProfilesToFile() ; <-- KLUCZOWA ZMIANA: Zapisz zmiany do pliku natychmiast

        StatusBar.Text := "Profile '" profileName "' deleted."
        UpdateProfileList()
    }
}

LoadProfilesFromFile() {
    global SavedPositions, ProfileFile
    if !FileExist(ProfileFile) {
        return
    }
    
    sections := []
    fileContent := FileRead(ProfileFile)
    Loop Parse, fileContent, "`n", "`r" {
        if RegExMatch(A_LoopField, "^\s*\[(.*)\]\s*$", &match) {
            sections.Push(match[1])
        }
    }

    for index, profileName in sections
    {
        if (profileName = "")
            continue

        SavedPositions[profileName] := {
            x: IniRead(ProfileFile, profileName, "x", 0),
            y: IniRead(ProfileFile, profileName, "y", 0),
            w: IniRead(ProfileFile, profileName, "w", 800),
            h: IniRead(ProfileFile, profileName, "h", 600),
            opacity: IniRead(ProfileFile, profileName, "opacity", 255),
            clickThrough: IniRead(ProfileFile, profileName, "clickThrough", false),
            alwaysOnTop: IniRead(ProfileFile, profileName, "alwaysOnTop", false),
            hasBorder: IniRead(ProfileFile, profileName, "hasBorder", true)
        }
    }
}

SaveProfilesToFile() {
    global SavedPositions, ProfileFile
    if FileExist(ProfileFile) {
        FileDelete(ProfileFile)
    }
    for profileName, state in SavedPositions {
        IniWrite(state.x, ProfileFile, profileName, "x")
        IniWrite(state.y, ProfileFile, profileName, "y")
        IniWrite(state.w, ProfileFile, profileName, "w")
        IniWrite(state.h, ProfileFile, profileName, "h")
        IniWrite(state.opacity, ProfileFile, profileName, "opacity")
        IniWrite(state.clickThrough, ProfileFile, profileName, "clickThrough")
        IniWrite(state.alwaysOnTop, ProfileFile, profileName, "alwaysOnTop")
        IniWrite(state.hasBorder, ProfileFile, profileName, "hasBorder")
    }
}