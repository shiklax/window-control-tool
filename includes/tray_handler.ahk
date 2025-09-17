; ===========================================
; === MODUŁ: tray_handler.ahk ===
; ===========================================

; Ta funkcja tworzy menu w zasobniku systemowym
CreateTrayMenu() {
    ; Ustawiamy naszą własną, niestandardową ikonę z folderu assets
    TraySetIcon(A_ScriptDir . "\assets\app_icon.ico")
    
    ; === NOWOŚĆ: Ustawiamy własny tekst tooltipa dla ikony w trayu ===
    A_IconTip := "Window Control Tool v4.7"

    ; Tworzymy menu, używając wbudowanego obiektu A_TrayMenu
    A_TrayMenu.Delete() ; Czyścimy domyślne menu
    A_TrayMenu.Add("Show / Hide", ToggleGUIVisibility)
    A_TrayMenu.Add() ; Separator
    A_TrayMenu.Add("Exit Application", ExitAppHandler)
    
    ; Ustawiamy "Show / Hide" jako domyślną akcję po lewym kliknięciu
    A_TrayMenu.Default := "Show / Hide"
}

; Ta funkcja będzie przełączać widoczność głównego okna GUI
ToggleGUIVisibility(*) {
    global gui1
    if WinExist("ahk_id " gui1.Hwnd) { ; <-- POPRAWKA
        gui1.Hide()
    } else {
        gui1.Show()
        WinActivate("ahk_id " gui1.Hwnd)
    }
}

; Ta funkcja będzie odpowiedzialna za bezpieczne zamknięcie aplikacji
ExitAppHandler(*) {
    global chkRestoreOnExit
    
    ; Sprawdzamy, czy checkbox jest zaznaczony
    if chkRestoreOnExit.Value {
        RestoreAllWindows() ; Wywołujemy funkcję przywracania okien
    }
    
    SaveProfilesToFile() ; Zawsze zapisujemy profile przed wyjściem
    
    ExitApp() ; Ostatecznie zamykamy aplikację
}