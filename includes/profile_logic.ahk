; ===========================================
; === MODUŁ: profile_logic.ahk ===
; ===========================================

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
    SaveProfilesToFile() ; Zapisz od razu
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
        SaveProfilesToFile() ; Zapisz od razu
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