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

/// ANSI/ASCII control codes
internal enum ControlCharacters: UInt8
{
    case Null       = 0
    case Ctrl_A     = 1
    case Ctrl_B     = 2
    case Ctrl_C     = 3
    case Ctrl_D     = 4
    case Ctrl_E     = 5
    case Ctrl_F     = 6
    case Bell       = 7
    case Ctrl_H     = 8
    case Tab        = 9
	case newLine	= 10
    case Ctrl_K     = 11
    case Ctrl_L     = 12
    case Enter      = 13
    case Ctrl_N     = 14
    case Ctrl_P     = 16
    case Ctrl_T     = 20
    case Ctrl_U     = 21
    case Ctrl_W     = 23
    case Esc        = 27
    case Backspace  = 127

	/// Create a Swift `Character` from the control code
    var character: Character
	{
        return Character(UnicodeScalar(Int(self.rawValue))!)
    }
}
