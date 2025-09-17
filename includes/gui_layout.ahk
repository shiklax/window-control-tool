; ===========================================
; === MODUŁ: gui_layout.ahk ===
; ===========================================

CreateGUI() {
    ; Deklarujemy zmienne jako globalne
    global gui1, MyListBox, btnRefresh, btnHighlight, btnHide, SelectedWindowText
    global btnReset, btnResetAll, btnAlwaysOnTop, btnBorderless, btnClickThrough
    global OpacitySlider, OpacityValue, btnLayoutLeft, btnLayoutRight, btnLayoutCenter
    global editX, editY, editW, editH, btnApplyManual
    global ProfileList, btnLoadProfile, btnSaveProfile, btnDeleteProfile
    global chkRestoreOnExit, StatusBar
    ; === NOWE ZMIENNE DLA SKALOWANIA ===
    global ScaleSlider, ScaleValueText, btnApplyScale, btnResetScale

    gui1 := Gui("-Resize -MaximizeBox -MinimizeBox", "Window Control Tool v4.7")
    gui1.SetFont("s9", "Segoe UI")

    ; === Lewa kolumna bez zmian ===
    LeftColumnGroup := gui1.Add("GroupBox", "x10 y5 w380 h600", "Window Selection & Control")
    gui1.Add("Text", "x20 y30", "🔍 Select window to control:")
    MyListBox := gui1.Add("ListBox", "x20 y50 w360 h250 VScroll")
    btnRefresh := gui1.Add("Button", "x20 y310 w110 h25", "Refresh")
    btnHighlight := gui1.Add("Button", "x140 y310 w110 h25", "Highlight")
    btnHide := gui1.Add("Button", "x260 y310 w110 h25", "Hide")
    gui1.Add("Text", "x20 y355", "📊 Current window:")
    SelectedWindowText := gui1.Add("Text", "x20 y375 w360 h125 Border", "No window selected...")
    SelectedWindowText.SetFont("s8")
    btnReset := gui1.Add("Button", "x20 y510 w175 h25", "Reset Selected")
    btnResetAll := gui1.Add("Button", "x205 y510 w175 h25", "Reset All")

    ; === KOLUMNA PRAWA: Narzędzia modyfikacji ===
    RightColumnGroup := gui1.Add("GroupBox", "x400 y5 w380 h600", "Modification Tools")
    
    styleGroup := gui1.Add("GroupBox", "x410 y25 w360 h65", "Style & Behavior")
    btnAlwaysOnTop := gui1.Add("Button", "x420 y45 w110 h25", "Always on Top")
    btnBorderless := gui1.Add("Button", "x540 y45 w110 h25", "Toggle Borderless")
    btnClickThrough := gui1.Add("Button", "x660 y45 w100 h25", "Click-Through")

    transparencyGroup := gui1.Add("GroupBox", "x410 y100 w360 h100", "Transparency")
    OpacitySlider := gui1.Add("Slider", "x420 y120 w270 h25 Range50-255 ToolTip", 255)
    OpacityValue := gui1.Add("Text", "x700 y122 w60", "100%")
    gui1.Add("Button", "x420 y155 w80 h25", "50%").OnEvent("Click", (*) => SetOpacity(127))
    gui1.Add("Button", "x510 y155 w80 h25", "75%").OnEvent("Click", (*) => SetOpacity(191))
    gui1.Add("Button", "x600 y155 w80 h25", "100%").OnEvent("Click", (*) => SetOpacity(255))

    ; === SEKCJA "POSITION & SIZE" ZOSTAŁA POWIĘKSZONA ===
    positionGroup := gui1.Add("GroupBox", "x410 y210 w360 h260", "Position & Size") ; <-- Zwiększona wysokość (było h190)
    
    gui1.Add("Text", "x420 y230", "Quick Layouts:")
    btnLayoutLeft := gui1.Add("Button", "x510 y225 w80 h25", "Left Half")
    btnLayoutRight := gui1.Add("Button", "x600 y225 w80 h25", "Right Half")
    btnLayoutCenter := gui1.Add("Button", "x690 y225 w80 h25", "Center")

    gui1.Add("Text", "x420 y270", "Manual Position:")
    gui1.Add("Text", "x430 y295", "X:")
    editX := gui1.Add("Edit", "x450 y290 w80 h25 vEditX")
    gui1.Add("Text", "x540 y295", "Y:")
    editY := gui1.Add("Edit", "x560 y290 w80 h25 vEditY")
    gui1.Add("Text", "x430 y330", "W:")
    editW := gui1.Add("Edit", "x450 y325 w80 h25 vEditW")
    gui1.Add("Text", "x540 y330", "H:")
    editH := gui1.Add("Edit", "x560 y325 w80 h25 vEditH")
    btnApplyManual := gui1.Add("Button", "x670 y290 w90 h60", "Apply")

    ; === NOWE KONTROLKI DO SKALOWANIA ===
    gui1.Add("Text", "x420 y370", "Scale (proportional):")
    ScaleSlider := gui1.Add("Slider", "x420 y390 w240 h25 Range50-150 ToolTip", 100)
    ScaleValueText := gui1.Add("Text", "x670 y392 w50", "100%")
    btnApplyScale := gui1.Add("Button", "x420 y425 w110 h25", "Apply Scale")
    btnResetScale := gui1.Add("Button", "x540 y425 w110 h25", "Reset Scale")

    ; === SEKCJA PROFILI PRZESUNIĘTA W DÓŁ ===
    profileGroup := gui1.Add("GroupBox", "x410 y480 w360 h70", "Window State Profiles") ; <-- Zmienione Y (było 410)
    ProfileList := gui1.Add("DropDownList", "x420 y505 w200 h150 vProfileList Choose1") ; <-- Zmienione Y (było 435)
    btnLoadProfile := gui1.Add("Button", "x630 y503 w40 h25", "Load") ; <-- Zmienione Y
    btnSaveProfile := gui1.Add("Button", "x675 y503 w40 h25", "Save") ; <-- Zmienione Y
    btnDeleteProfile := gui1.Add("Button", "x720 y503 w40 h25", "Delete") ; <-- Zmienione Y

    ; === Kontrolki na samym dole ===
    chkRestoreOnExit := gui1.Add("Checkbox", "x10 y615 Checked", "Restore windows on exit")
    StatusBar := gui1.Add("StatusBar",, "Ready | Select a window to begin")
}