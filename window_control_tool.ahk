; =================================================
; === GŁÓWNY PLIK: window_control_tool.ahk ===
; =================================================
#SingleInstance Force
Persistent

; === Global variables ===
global SelectedHwnd := 0
global ModifiedWindows := Map()
global SavedPositions := Map()
global gui1
global ProfileFile := A_ScriptDir . "\window_profiles.ini"
global BlacklistFile := A_ScriptDir . "\window_blacklist.ini"
global previewGui := ""
global lastCalculatedSize := Map("x", 0, "y", 0, "w", 0, "h", 0)

; === Ładowanie modułów ===
#Include "%A_ScriptDir%\includes\math_evaluator.ahk"
#Include "%A_ScriptDir%\includes\profile_logic.ahk"
#Include "%A_ScriptDir%\includes\window_functions.ahk"
#Include "%A_ScriptDir%\includes\gui_layout.ahk"
#Include "%A_ScriptDir%\includes\tray_handler.ahk"

; Inicjalizacja GUI (funkcja z gui_layout.ahk)
CreateTrayMenu()
CreateGUI()

; === Events (klej łączący GUI z funkcjami) ===
btnRefresh.OnEvent("Click", RefreshListWithSelection)
btnClickThrough.OnEvent("Click", ToggleClickThrough)
btnHighlight.OnEvent("Click", HighlightWindow)
btnReset.OnEvent("Click", ResetWindow)
btnResetAll.OnEvent("Click", ResetAllWindows)
MyListBox.OnEvent("Change", SetWindow)
MyListBox.OnEvent("DoubleClick", HighlightWindow)
OpacitySlider.OnEvent("Change", ApplyOpacity)
gui1.OnEvent("Close", GuiClose)
btnAlwaysOnTop.OnEvent("Click", ToggleAlwaysOnTop)
btnLayoutLeft.OnEvent("Click", (*) => SetWindowLayout("left"))
btnLayoutRight.OnEvent("Click", (*) => SetWindowLayout("right"))
btnLayoutCenter.OnEvent("Click", (*) => SetWindowLayout("center"))
btnBorderless.OnEvent("Click", ToggleBorderless)
btnApplyManual.OnEvent("Click", ApplyManualChanges)
btnLoadProfile.OnEvent("Click", LoadProfile)
btnSaveProfile.OnEvent("Click", SaveProfile)
btnDeleteProfile.OnEvent("Click", DeleteProfile)
ScaleSlider.OnEvent("Change", UpdateScalePreview)
btnApplyScale.OnEvent("Click", ApplyScaling) 
btnResetScale.OnEvent("Click", ResetScaling) 
btnHide.OnEvent("Click", BlacklistSelectedWindow)

OnMessage(0x0006, GuiActivateHandler) ; WM_ACTIVATE

; === Główna logika startowa ===
LoadProfilesFromFile()
gui1.Show("w800 h650")
UpdateProfileList()
RefreshListWithSelection()
return ; Zatrzymuje auto-wykonywanie, chociaż Persistent i tak by to zrobił

; === Funkcje Główne Aplikacji ===
GuiClose(*) {
    ; Zamiast zamykać aplikację, teraz tylko ją ukrywamy
    ToggleGUIVisibility()
}