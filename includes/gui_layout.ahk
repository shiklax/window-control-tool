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

    gui1 := Gui("-Resize -MaximizeBox", "Window Control Tool v4.7")
    gui1.SetFont("s9", "Segoe UI")

    ; === KOLUMNA LEWA: Lista okien i zarządzanie (POSZERZONA) ===
    LeftColumnGroup := gui1.Add("GroupBox", "x10 y5 w380 h620", "Window Selection & Control")

    gui1.Add("Text", "x20 y30", "🔍 Select window to control:")
    MyListBox := gui1.Add("ListBox", "x20 y50 w360 h250 VScroll")

    btnRefresh := gui1.Add("Button", "x20 y310 w110 h25", "Refresh")
    btnHighlight := gui1.Add("Button", "x140 y310 w110 h25", "Highlight")
    btnHide := gui1.Add("Button", "x260 y310 w110 h25", "Hide")

    gui1.Add("Text", "x20 y355", "📊 Current window:")
    SelectedWindowText := gui1.Add("Text", "x20 y375 w360 h80 Border", "No window selected`n`nSelect a window from the list above")
    SelectedWindowText.SetFont("s8")

    btnReset := gui1.Add("Button", "x20 y465 w175 h25", "Reset Selected")
    btnResetAll := gui1.Add("Button", "x205 y465 w175 h25", "Reset All")

    ; === KOLUMNA PRAWA: Narzędzia modyfikacji (PRZESUNIĘTA) ===
    RightColumnGroup := gui1.Add("GroupBox", "x400 y5 w380 h620", "Modification Tools")

    ; --- Grupa: Styl i Zachowanie ---
    styleGroup := gui1.Add("GroupBox", "x410 y25 w360 h65", "Style & Behavior")
    btnAlwaysOnTop := gui1.Add("Button", "x420 y45 w110 h25", "Always on Top")
    btnBorderless := gui1.Add("Button", "x540 y45 w110 h25", "Toggle Borderless")
    btnClickThrough := gui1.Add("Button", "x660 y45 w100 h25", "Click-Through")

    ; --- Grupa: Przezroczystość ---
    transparencyGroup := gui1.Add("GroupBox", "x410 y100 w360 h100", "Transparency")
    OpacitySlider := gui1.Add("Slider", "x420 y120 w270 h25 Range50-255 ToolTip", 255)
    OpacityValue := gui1.Add("Text", "x700 y122 w60", "100%")
    gui1.Add("Button", "x420 y155 w80 h25", "50%").OnEvent("Click", (*) => SetOpacity(127))
    gui1.Add("Button", "x510 y155 w80 h25", "75%").OnEvent("Click", (*) => SetOpacity(191))
    gui1.Add("Button", "x600 y155 w80 h25", "100%").OnEvent("Click", (*) => SetOpacity(255))

    ; --- Grupa: Pozycja i Rozmiar ---
    positionGroup := gui1.Add("GroupBox", "x410 y210 w360 h190", "Position & Size")
    gui1.Add("Text", "x420 y230", "Quick Layouts:")
    btnLayoutLeft := gui1.Add("Button", "x510 y225 w80 h25", "Left Half")
    btnLayoutRight := gui1.Add("Button", "x600 y225 w80 h25", "Right Half")
    btnLayoutCenter := gui1.Add("Button", "x690 y225 w80 h25", "Center")

    ; === Twój poprawiony układ "Manual Position" zintegrowany z nowymi współrzędnymi ===
    gui1.Add("Text", "x420 y270", "Manual Position:")
    gui1.Add("Text", "x430 y295", "X:")
    editX := gui1.Add("Edit", "x450 y290 w80 h25 vEditX")
    gui1.Add("Text", "x540 y295", "Y:")
    editY := gui1.Add("Edit", "x450 y325 w80 h25 vEditY") ; <-- Twoja korekta Y
    gui1.Add("Text", "x430 y330", "W:") ; <-- Twoja korekta tekstu
    editW := gui1.Add("Edit", "x560 y290 w80 h25 vEditW") ; <-- Twoja korekta X
    gui1.Add("Text", "x540 y330", "H:") ; <-- Twoja korekta tekstu i X
    editH := gui1.Add("Edit", "x560 y325 w80 h25 vEditH") ; <-- Twoja korekta X i Y
    btnApplyManual := gui1.Add("Button", "x670 y290 w90 h60", "Apply") ; <-- Przesunięty Apply

    ; --- Grupa: Profile ---
    profileGroup := gui1.Add("GroupBox", "x410 y410 w360 h70", "Window State Profiles")
    ProfileList := gui1.Add("DropDownList", "x420 y435 w200 h150 vProfileList Choose1")
    btnLoadProfile := gui1.Add("Button", "x630 y433 w40 h25", "Load")
    btnSaveProfile := gui1.Add("Button", "x675 y433 w40 h25", "Save")
    btnDeleteProfile := gui1.Add("Button", "x720 y433 w40 h25", "Delete")

    ; === Kontrolki na samym dole ===
    chkRestoreOnExit := gui1.Add("Checkbox", "x10 y635 Checked", "Restore windows on exit")
    StatusBar := gui1.Add("StatusBar",, "Ready | Select a window to begin")
}