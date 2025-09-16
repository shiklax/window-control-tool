; math_evaluator.ahk
; Mathematical expression evaluator library for AutoHotkey v2
; Usage: #Include "math_evaluator.ahk"

/**
 * Evaluates a mathematical expression string
 * @param expr - String containing mathematical expression (e.g., "300+30", "200*2")
 * @returns Number result or empty string if invalid
 */
EvalExpr(expr) {
    expr := Trim(expr)
    if (expr = "")
        return ""
    
    ; Replace commas with dots for decimal notation
    expr := StrReplace(expr, ",", ".")
    
    ; Remove all spaces
    expr := StrReplace(expr, " ", "")
    
    ; Check if expression contains only allowed characters
    if !RegExMatch(expr, "^[0-9+\-*/().\s]+$") {
        return ""
    }
    
    ; If it's just a number, return it
    if IsNumeric(expr) {
        return Float(expr)
    }
    
    try {
        result := EvaluateExpression(expr)
        return IsNumeric(result) ? Float(result) : ""
    } catch {
        return ""
    }
}

/**
 * Internal function: Evaluates expression with proper operator precedence
 * @param expr - Cleaned expression string
 * @returns Number result
 */
EvaluateExpression(expr) {
    ; Remove spaces
    expr := StrReplace(expr, " ", "")
    
    ; Handle parentheses first
    while RegExMatch(expr, "\(([^()]+)\)", &match) {
        innerResult := EvaluateExpression(match[1])
        if (innerResult = "")
            throw Error("Invalid expression")
        expr := StrReplace(expr, match[0], innerResult)
    }
    
    ; Split by + and - (lowest precedence)
    parts := []
    operators := []
    current := ""
    i := 1
    
    while (i <= StrLen(expr)) {
        char := SubStr(expr, i, 1)
        if (char = "+" || char = "-") {
            if (current = "")
                throw Error("Invalid expression")
            parts.Push(current)
            operators.Push(char)
            current := ""
        } else {
            current .= char
        }
        i++
    }
    if (current != "")
        parts.Push(current)
    
    if (parts.Length = 1) {
        ; No + or -, try * and /
        return EvaluateMultDiv(parts[1])
    }
    
    ; Evaluate first part
    result := EvaluateMultDiv(parts[1])
    if (!IsNumeric(result))
        throw Error("Invalid expression")
    
    ; Process remaining parts
    Loop parts.Length - 1 {
        operator := operators[A_Index]
        nextValue := EvaluateMultDiv(parts[A_Index + 1])
        if (!IsNumeric(nextValue))
            throw Error("Invalid expression")
        
        if (operator = "+") {
            result := result + nextValue
        } else if (operator = "-") {
            result := result - nextValue
        }
    }
    
    return result
}

/**
 * Internal function: Handles multiplication and division
 * @param expr - Expression part to evaluate
 * @returns Number result
 */
EvaluateMultDiv(expr) {
    parts := []
    operators := []
    current := ""
    i := 1
    
    while (i <= StrLen(expr)) {
        char := SubStr(expr, i, 1)
        if (char = "*" || char = "/") {
            if (current = "")
                throw Error("Invalid expression")
            parts.Push(current)
            operators.Push(char)
            current := ""
        } else {
            current .= char
        }
        i++
    }
    if (current != "")
        parts.Push(current)
    
    if (parts.Length = 1) {
        ; Just a number
        return IsNumeric(parts[1]) ? Float(parts[1]) : ""
    }
    
    ; Evaluate first part
    result := Float(parts[1])
    if (!IsNumeric(result))
        throw Error("Invalid expression")
    
    ; Process remaining parts
    Loop parts.Length - 1 {
        operator := operators[A_Index]
        nextValue := Float(parts[A_Index + 1])
        if (!IsNumeric(nextValue))
            throw Error("Invalid expression")
        
        if (operator = "*") {
            result := result * nextValue
        } else if (operator = "/") {
            if (nextValue = 0)
                throw Error("Division by zero")
            result := result / nextValue
        }
    }
    
    return result
}

/**
 * Enhanced IsNumeric function for this library
 * @param val - Value to check
 * @returns Boolean
 */
IsNumeric(val) {
    try {
        Float(val)
        return true
    } catch {
        return false
    }
}