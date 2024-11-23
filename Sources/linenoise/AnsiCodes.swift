/*
 Copyright (c) 2022, Jeremy Pereira <jeremy.j.pereira at icloud dot com>
 Copyright (c) 2017, Andy Best <andybest.net at gmail dot com>
 Copyright (c) 2010-2014, Salvatore Sanfilippo <antirez at gmail dot com>
 Copyright (c) 2010-2013, Pieter Noordhuis <pcnoordhuis at gmail dot com>
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation

/// ANSI terminal escape codes
public struct AnsiCodes
{
	/// Erase the character to the right of the cursoe
    public static var eraseRight: String
	{
        return escapeCode("0K")
    }
    /// Return the cursor to the home position
    public static var homeCursor: String
	{
        return escapeCode("H")
    }
    /// Clear the screen
    public static var clearScreen: String
	{
        return escapeCode("2J")
    }
    /// Reports the current cursor position by responding
	///
	/// ```
	/// ESC[n;mR
	/// ```
	/// where `n` and `m` are the row and column
    public static var cursorLocation: String
	{
        return escapeCode("6n")
    }

	/// Constructs a string consisting of an ANSI CSI escape code
	///
	/// Most useful ANSI commands are prefixed with the control sequence
	/// introducer. This consists of <kbd>ESC</kbd>`[`. This function prefixes
	/// that to the control sequence.
	/// - Parameter input: The control sequence
	/// - Returns: The full ANSI escape code.
    public static func escapeCode(_ input: String) -> String
	{
        return "\u{001B}[" + input
    }

	/// Move the cursor forwards
	/// - Parameter columns: Number of columns to move forwards
	/// - Returns: The escape coder to move the cursor forward by the given
	///            amount.
    public static func cursorForward(_ columns: Int) -> String
	{
        return escapeCode("\(columns)C")
    }

	/// Set the termoinal colour.
	///
	/// This only sets the foreground colour. The background is set to the
	/// default.
	/// - Parameters:
	///   - color: The colour to set
	///   - bold: whether the character should be bold
	/// - Returns: The escape sequence to set the character colour and wieight.
    public static func termColor(color: Int, bold: Bool) -> String
	{
        return escapeCode("\(color);\(bold ? 1 : 0);49m")
    }

	/// Set the colour in 256 bit mode
	///
	/// This only sets the foreground colour.
	/// - Parameter color: Colour to set
	/// - Returns: The escape code to set a 256 bit colour
    public static func termColor256(color: Int) -> String
	{
        return escapeCode("38;5;\(color)m")
    }

	/// Resets the terminal colours to the default
    public static var origTermColor: String
	{
        return escapeCode("0m")
    }
    
}
