; ===========================================
; === MODUŁ: gui_layout.ahk ===
; ===========================================

CreateGUI() {
    ; Deklarujemy zmienne jako globalne, aby były dostępne
    ; w głównym skrypcie i innych modułach
    global gui1, MyListBox, btnRefresh, btnHighlight, SelectedWindowText
    global btnReset, btnResetAll, btnAlwaysOnTop, btnBorderless, btnClickThrough
    global OpacitySlider, OpacityValue, btnLayoutLeft, btnLayoutRight, btnLayoutCenter
    global btnLayoutMaximize, editX, editY, editW, editH, btnApplyManual
    global ProfileList, btnLoadProfile, btnSaveProfile, btnDeleteProfile
    global chkRestoreOnExit, StatusBar

    gui1 := Gui("-Resize -MaximizeBox", "Window Control Tool v4.7")
    gui1.SetFont("s9", "Segoe UI")

    ; === KOLUMNA LEWA: Lista okien i zarządzanie ===
    LeftColumnGroup := gui1.Add("GroupBox", "x10 y5 w280 h620", "Window Selection & Control")

    gui1.Add("Text", "x20 y30", "🔍 Select window to control:")
    MyListBox := gui1.Add("ListBox", "x20 y50 w260 h250 VScroll")

    btnRefresh := gui1.Add("Button", "x20 y310 w80 h25", "Refresh")
    btnHighlight := gui1.Add("Button", "x110 y310 w80 h25", "Highlight")
    
    gui1.Add("Text", "x20 y355", "📊 Current window:")
    SelectedWindowText := gui1.Add("Text", "x20 y375 w260 h80 Border", "No window selected`n`nSelect a window from the list above")
    SelectedWindowText.SetFont("s8")

    btnReset := gui1.Add("Button", "x20 y465 w125 h25", "Reset Selected")
    btnResetAll := gui1.Add("Button", "x155 y465 w125 h25", "Reset All")

    ; === KOLUMNA PRAWA: Narzędzia modyfikacji ===
    RightColumnGroup := gui1.Add("GroupBox", "x300 y5 w380 h620", "Modification Tools")

    styleGroup := gui1.Add("GroupBox", "x310 y25 w360 h65", "Style & Behavior")
    btnAlwaysOnTop := gui1.Add("Button", "x320 y45 w110 h25", "Always on Top")
    btnBorderless := gui1.Add("Button", "x440 y45 w110 h25", "Toggle Borderless")
    btnClickThrough := gui1.Add("Button", "x560 y45 w100 h25", "Click-Through")

    transparencyGroup := gui1.Add("GroupBox", "x310 y100 w360 h100", "Transparency")
    OpacitySlider := gui1.Add("Slider", "x320 y120 w270 h25 Range50-255 ToolTip", 255)
    OpacityValue := gui1.Add("Text", "x600 y122 w60", "100%")
    gui1.Add("Button", "x320 y155 w80 h25", "50%").OnEvent("Click", (*) => SetOpacity(127))
    gui1.Add("Button", "x410 y155 w80 h25", "75%").OnEvent("Click", (*) => SetOpacity(191))
    gui1.Add("Button", "x500 y155 w80 h25", "100%").OnEvent("Click", (*) => SetOpacity(255))

    positionGroup := gui1.Add("GroupBox", "x310 y210 w360 h190", "Position & Size")
    gui1.Add("Text", "x320 y230", "Quick Layouts:")
    btnLayoutLeft := gui1.Add("Button", "x410 y225 w80 h25", "Left Half")
    btnLayoutRight := gui1.Add("Button", "x500 y225 w80 h25", "Right Half")
    btnLayoutCenter := gui1.Add("Button", "x590 y225 w80 h25", "Center")

    gui1.Add("Text", "x320 y300", "Manual Position:")
    gui1.Add("Text", "x330 y325", "X:")
    editX := gui1.Add("Edit", "x350 y320 w80 h25 vEditX")
    gui1.Add("Text", "x440 y325", "Y:")
    editY := gui1.Add("Edit", "x460 y320 w80 h25 vEditY")
    gui1.Add("Text", "x330 y360", "W:")
    editW := gui1.Add("Edit", "x350 y355 w80 h25 vEditW")
    gui1.Add("Text", "x440 y360", "H:")
    editH := gui1.Add("Edit", "x460 y355 w80 h25 vEditH")
    btnApplyManual := gui1.Add("Button", "x570 y320 w90 h60", "Apply")

    profileGroup := gui1.Add("GroupBox", "x310 y410 w360 h70", "Window State Profiles")
    ProfileList := gui1.Add("DropDownList", "x320 y435 w200 h150 vProfileList Choose1")
    btnLoadProfile := gui1.Add("Button", "x530 y433 w40 h25", "Load")
    btnSaveProfile := gui1.Add("Button", "x575 y433 w40 h25", "Save")
    btnDeleteProfile := gui1.Add("Button", "x620 y433 w40 h25", "Delete")

    chkRestoreOnExit := gui1.Add("Checkbox", "x10 y635 Checked", "Restore windows on exit")
    StatusBar := gui1.Add("StatusBar",, "Ready | Select a window to begin")
}