/*
 Copyright (c) 2022-2023, Jeremy Pereira <jeremy.j.pereira at icloud dot net>
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

#if os(Linux) || os(FreeBSD)
    import Glibc
#else
//    import Darwin
#endif
import Foundation
import System


/// The `LineNoise` class provides all the functionality for this library
///
/// For the most part, you can simply create a `LineNoise` instance and start
/// using it straight away.
/// ```swift
/// let ln = LineNoise()
///
/// do
/// {
///     let input = try ln.getLine(prompt: "> ")
///     ln.addHistory(input)
/// }
/// catch
/// {
///     print(error)
/// }
/// ```
/// There are APIs to limit the amount of history and to save it to a file.
/// Tab completion and hints are also supported.
///
/// The executable `LinenoiseDemo` demonstrates some of the features available.
/// It also serves as example source code.
@available(macOS 11.0, *)
public class LineNoise
{
    var history: History = History()
    
    var completionCallback: ((String) -> ([String]))?
    var hintsCallback: ((String) -> (String?, (Int, Int, Int)?))?

    let currentTerm: String

    var tempBuf: String?
    
    var inputFile: LNInput
    var outputFile: LNOutput
	let encoding: String.Encoding
    
    // MARK: - Public Interface

	/// Enumeration that determines what mode the linenoise is operating in.
	///
	/// The features of Linenoise are only supported for certain types of tty
	/// file.
	public enum Mode
	{
		/// Input is a tty but not an ANSI one.
		case unsupportedTTY
		/// Input is a supported tty
		case supportedTTY
		/// Input is not a TTY e.g. regular file.
		case notATTY
	}

	/// The mode in which we are operating with respect to the input
	///
	/// See ``LineNoise/LineNoise/Mode-swift.enum`` for info.
	public let mode: Mode

	/// Controls history edit preservation
	///
	/// If false (the default) any edits by the user to a line in the history
	/// will be discarded if the user moves forward or back in the history
	/// without pressing Enter.  If true, all history edits will be preserved.
	public var preserveHistoryEdits = false


	/// Initialise a `LineNoise` instance
	/// - Parameters:
	///   - inputFile: POSIX file descriptor of input (defaults to stdin)
	///   - outputFile: POSIX file descriptor of output (defaults to stdout)
	///   - encloding: The character encoding for the terminal. Defaults to UTF-8.
	///                Not all encodings from `String.Encoding` are supported.
	///                If the encoding is fixed 8 bit or UTF-8 it will work.
	public init(inputFile: LNInput = FileDescriptor.standardInput,
				outputFile: LNOutput = FileDescriptor.standardOutput,
				encoding: String.Encoding = .utf8)
	{
        self.inputFile = inputFile
        self.outputFile = outputFile
		self.encoding = encoding
		self.currentTerm = ProcessInfo.processInfo.environment["TERM"] ?? ""

 		if !inputFile.isTTY
		{
            mode = .notATTY
        }
		else if inputFile.isSupported(terminal: self.currentTerm)
		{
            mode = .supportedTTY
        }
        else
		{
            mode = .unsupportedTTY
        }
    }

	/// Add a string to history
	///
	/// History addition is not automatic. The application must decide whether
	/// it is appropriate to add a line to the history.
	/// - Parameter item: Item to add to history
    public func addHistory(_ item: String)
	{
        history.add(item)
    }

	/// Adds a callback for tab completion
	/// - Parameter callback: A callback taking the current text and returning
	///                       an array of Strings containing possible completions
    public func setCompletionCallback(_ callback: @escaping (String) -> ([String]) )
	{
        completionCallback = callback
    }
    
	/// Adds a callback for hints as you type
	/// - Parameter callback: A callback taking the current text and optionally
	///                       returning the hint and a tuple of RGB colours for
	///                       the hint text
    public func setHintsCallback(_ callback: @escaping (String) -> (String?, (Int, Int, Int)?))
	{
        hintsCallback = callback
    }

	/// Loads history from a file and appends it to the current history buffer
	/// - Parameter path: The path of the history file
	/// - Throws: Can throw an error if the file cannot be found or loaded
    public func loadHistory(fromFile path: String) throws
	{
        try history.load(fromFile: path)
    }

	/// Saves history to a file
	/// - Parameter path: The path of the history file to save
	/// - Throws: Can throw an error if the file cannot be written to
    public func saveHistory(toFile path: String) throws
	{
        try history.save(toFile: path)
    }

	/// Sets the maximum amount of items to keep in history
	///
	/// If this limit is reached, the oldest item is discarded when a new item
	/// is added.
	/// - todo: Use an optional and `nil` for unlimited history.
	/// - Parameter historyMaxLength: The maximum length of history. Setting
	///                               this to 0 (the default) will keep
	///                               'unlimited' items in history

    public func setHistoryMaxLength(_ historyMaxLength: UInt?)
	{
        history.maxLength = historyMaxLength
    }

	/// Clear the screen
	///  - Throws: Can throw an error if the terminal cannot be written to.
    public func clearScreen() throws
	{
        try output(text: AnsiCodes.homeCursor)
        try output(text: AnsiCodes.clearScreen)
    }

	/// Get a line of input
	///
	/// The main function of Linenoise. Gets a line of input from the user.
	/// - Parameter prompt: The prompt to be shown to the user at the beginning of the line.
	/// - Returns: The input from the user
	/// - Throws: Can throw an error if the terminal cannot be written to.
    public func getLine(prompt: String) throws -> String
	{
        // If there was any temporary history, remove it
        tempBuf = nil

        switch mode
		{
        case .notATTY:
            return try getLineNoTTY(prompt: prompt)

        case .unsupportedTTY:
            return try getLineUnsupportedTTY(prompt: prompt)

        case .supportedTTY:
            return try getLineRaw(prompt: prompt)
        }
    }
        
    // MARK: - Text output

    private func output(character: ControlCharacters) throws
	{
        try output(character: character.character)
    }

    internal func output(character: Character) throws
	{
		try output(text: String(character))
    }
    
    internal func output(text: String) throws
	{
		try outputFile.write(text: text, encoding: encoding)
    }
    
    // MARK: - Cursor movement
    internal func updateCursorPosition(editState: EditState) throws
	{
        try output(text: "\r" + AnsiCodes.cursorForward(editState.cursorPosition + editState.prompt.count))
    }
    
    internal func moveLeft(editState: EditState) throws
	{
        // Left
        if editState.moveLeft()
		{
            try updateCursorPosition(editState: editState)
        }
		else
		{
            try output(character: ControlCharacters.Bell.character)
        }
    }
    
    internal func moveRight(editState: EditState) throws
	{
        // Left
        if editState.moveRight()
		{
            try updateCursorPosition(editState: editState)
        }
		else
		{
            try output(character: ControlCharacters.Bell.character)
        }
    }
    
    internal func moveHome(editState: EditState) throws
	{
        if editState.moveHome()
		{
            try updateCursorPosition(editState: editState)
        }
		else
		{
            try output(character: ControlCharacters.Bell.character)
        }
    }
    
	internal func moveEnd(editState: EditState, bell: Bool = true) throws
	{
        if editState.moveEnd()
		{
            try updateCursorPosition(editState: editState)
        }
		else if bell
		{
            try output(character: ControlCharacters.Bell.character)
        }
    }

    internal func getCursorXPosition() throws -> Int?
	{
        do
		{
            try output(text: AnsiCodes.cursorLocation)
        }
		catch
		{
            return nil
        }
        
        var buf = [Character]()
        var i = 0
        while true
		{
			if let c = try inputFile.readCharacter(encoding: encoding)
			{
                buf[i] = c
            }
			else
			{
                return nil
            }
            if buf[i] == "R"
			{ // "R"
                break
            }
            i += 1
        }
        
        // Check the first characters are the escape code
		if buf[0] != ControlCharacters.Esc.character || buf[1] != "["
		{
            return nil
        }
        
        let positionText = String(buf[2..<buf.count])
        let rowCol = positionText.split(separator: ";")
        
        if rowCol.count != 2
		{
            return nil
        }
        
        return Int(String(rowCol[1]))
    }
    
    internal func getNumCols() throws -> Int
	{
        var winSize = winsize()
        
        if ioctl(1, UInt(TIOCGWINSZ), &winSize) == -1 || winSize.ws_col == 0
		{
            // Couldn't get number of columns with ioctl
            guard let start = try getCursorXPosition()
			else { return 80 }
            
            do
			{
                try output(text: AnsiCodes.cursorForward(999))
            }
			catch
			{
                return 80
            }
            
            guard let cols = try getCursorXPosition()
			else
			{
                return 80
            }
            // Restore original cursor position
            do
			{
                try output(text: "\r" + AnsiCodes.cursorForward(start))
            }
			catch
			{
                // Can't recover from this
            }
            
            return cols
        }
		else
		{
            return Int(winSize.ws_col)
        }
    }
    
    // MARK: - Buffer manipulation
    internal func refreshLine(editState: EditState) throws
	{
        var commandBuf = "\r"                // Return to beginning of the line
        commandBuf += editState.prompt
        commandBuf += editState.buffer
        commandBuf += try refreshHints(editState: editState)
        commandBuf += AnsiCodes.eraseRight
        
        // Put the cursor in the original position
        commandBuf += "\r"
        commandBuf += AnsiCodes.cursorForward(editState.cursorPosition + editState.prompt.count)
        
        try output(text: commandBuf)
    }
    
    internal func insertCharacter(_ char: Character, editState: EditState) throws
	{
        editState.insertCharacter(char)
        
        if editState.location == editState.buffer.endIndex
		{
            try output(character: char)
        }
		else
		{
            try refreshLine(editState: editState)
        }
    }
    
    internal func deleteCharacter(editState: EditState) throws
	{
        if !editState.deleteCharacter()
		{
            try output(character: ControlCharacters.Bell.character)
        }
		else
		{
            try refreshLine(editState: editState)
        }
    }
    
    // MARK: - Completion
    
    internal func completeLine(editState: EditState) throws -> Character?
	{
        if completionCallback == nil
		{
            return nil
        }
        
        let completions = completionCallback!(editState.currentBuffer)
        
        if completions.count == 0
		{
            try output(character: ControlCharacters.Bell.character)
            return nil
        }
        
        var completionIndex = 0
        
        // Loop to handle inputs
        while true
		{
            if completionIndex < completions.count
			{
                try editState.withTemporaryState
				{
					editState.set(buffer: completions[completionIndex])
                    _ = editState.moveEnd()
                    
                    try refreshLine(editState: editState)
                }
            }
			else
			{
                try refreshLine(editState: editState)
            }

            guard let char = try inputFile.readCharacter(encoding: encoding) else { return nil }
            
            switch char
			{
            case ControlCharacters.Tab.character:
                // Move to next completion
                completionIndex = (completionIndex + 1) % (completions.count + 1)
                if completionIndex == completions.count
				{
                    try output(character: ControlCharacters.Bell.character)
                }
                
            case ControlCharacters.Esc.character:
                // Show the original buffer
                if completionIndex < completions.count
				{
                    try refreshLine(editState: editState)
                }
                return char
                
            default:
                // Update the buffer and return
                if completionIndex < completions.count
				{
					editState.set(buffer: completions[completionIndex])
                    _ = editState.moveEnd()
                }
                
                return char
            }
        }
    }
    
    // MARK: - History
    
    internal func moveHistory(editState: EditState, direction: History.HistoryDirection) throws
	{
        // If we're at the end of history (editing the current line),
        // push it into a temporary buffer so it can be retreived later.
        if history.currentIndex == history.historyItems.count
		{
            tempBuf = editState.currentBuffer
        }
        else if preserveHistoryEdits
		{
            history.replaceCurrent(editState.currentBuffer)
        }
        
        if let historyItem = history.navigateHistory(direction: direction)
		{
			editState.set(buffer: historyItem)
            _ = editState.moveEnd()
            try refreshLine(editState: editState)
        }
		else
		{
            if case .next = direction
			{
				editState.set(buffer: tempBuf ?? "")
                _ = editState.moveEnd()
                try refreshLine(editState: editState)
            }
			else
			{
                try output(character: ControlCharacters.Bell.character)
            }
        }
    }
    
    // MARK: - Hints
    
    internal func refreshHints(editState: EditState) throws -> String
	{
        if hintsCallback != nil
		{
            var cmdBuf = ""
            
            let (hintOpt, color) = hintsCallback!(editState.currentBuffer)
            
            guard let hint = hintOpt else { return "" }
            
            let currentLineLength = editState.prompt.count + editState.currentBuffer.count
            
            let numCols = try getNumCols()
            
            // Don't display the hint if it won't fit.
            if hint.count + currentLineLength > numCols
			{
                return ""
            }
            
            let colorSupport = Terminal.termColorSupport(termVar: currentTerm)
            
            var outputColor = 0
            if color == nil
			{
                outputColor = 37
            }
			else
			{
                outputColor = Terminal.closestColor(to: color!,
                                                    withColorSupport: colorSupport)
            }
            
            switch colorSupport
			{
            case .standard:
                cmdBuf += AnsiCodes.termColor(color: (outputColor & 0xF) + 30, bold: outputColor > 7)
            case .twoFiftySix:
                cmdBuf += AnsiCodes.termColor256(color: outputColor)
            }
            cmdBuf += hint
            cmdBuf += AnsiCodes.origTermColor
            
            return cmdBuf
        }
        
        return ""
    }
    
    // MARK: - Line editing
    
    internal func getLineNoTTY(prompt: String) throws -> String
	{
		var ret = ""

		var eolReached = false
		var c = try inputFile.readCharacter(encoding: encoding)
		while let aChar = c, !eolReached
		{
			if aChar == "\n"
			{
				eolReached = true
			}
			else
			{
				ret.append(aChar)
				c = try inputFile.readCharacter(encoding: encoding)
			}
		}
		guard eolReached || !ret.isEmpty else { throw Error.EOF }
        return ret
    }
    
    internal func getLineRaw(prompt: String) throws -> String
	{
        var line: String = ""

		try inputFile.inRawMode
		{
			line = try editLine(prompt: prompt)
		}
        return line
    }

    internal func getLineUnsupportedTTY(prompt: String) throws -> String
	{
        // Since the terminal is unsupported, fall back to Swift's readLine.
        print(prompt, terminator: "")
        if let line = readLine()
		{
            return line
        }
        else
		{
            throw Error.EOF
        }
    }

    internal func handleEscapeCode(editState: EditState) throws
	{
		var seq: [Character] = []
		for _ in 0 ... 1
		{
			guard let char = try inputFile.readCharacter(encoding: encoding)
			else { throw Error.EOF }
			seq.append(char)
		}

        if seq[0] == "["
		{
			if ("0" ... "9").contains(seq[1])
			{
                // Handle multi-byte sequence ^[[0...
				guard let char = try inputFile.readCharacter(encoding: encoding)
				else { throw Error.EOF }
				seq.append(char)

                if seq[2] == "~"
				{
                    switch seq[1]
					{
                    case "1", "7":
                        try moveHome(editState: editState)
                    case "3":
                        // Delete
                        try deleteCharacter(editState: editState)
                    case "4":
                        try moveEnd(editState: editState)
                    default:
                        break
                    }
                }
            }
			else
			{
                // ^[...
                switch seq[1]
				{
                case "A":
                    try moveHistory(editState: editState, direction: .previous)
                case "B":
                    try moveHistory(editState: editState, direction: .next)
                case "C":
                    try moveRight(editState: editState)
                case "D":
                    try moveLeft(editState: editState)
                case "H":
                    try moveHome(editState: editState)
                case "F":
                    try moveEnd(editState: editState)
                default:
                    break
                }
            }
        }
		else if seq[0] == "O"
		{
            // ^[O...
            switch seq[1]
			{
            case "H":
                try moveHome(editState: editState)
            case "F":
                try moveEnd(editState: editState)
            default:
                break
            }
        }
    }
    
    internal func handleCharacter(_ char: Character, editState: EditState) throws -> String?
	{
        switch char
		{
            
		case ControlCharacters.Enter.character, ControlCharacters.newLine.character:
			try moveEnd(editState: editState, bell: false)
            return editState.currentBuffer
            
        case ControlCharacters.Ctrl_A.character:
            try moveHome(editState: editState)
            
        case ControlCharacters.Ctrl_E.character:
            try moveEnd(editState: editState)
            
        case ControlCharacters.Ctrl_B.character:
            try moveLeft(editState: editState)
            
        case ControlCharacters.Ctrl_C.character:
            // Throw an error so that CTRL+C can be handled by the caller
            throw Error.CTRL_C
            
        case ControlCharacters.Ctrl_D.character:
            // If there is a character at the right of the cursor, remove it
            // If the cursor is at the end of the line, act as EOF
            if !editState.eraseCharacterRight()
			{
                if editState.currentBuffer.count == 0
				{
                    throw Error.EOF
                }
				else
				{
                    try output(character: .Bell)
                }
            }
			else
			{
                try refreshLine(editState: editState)
            }
            
        case ControlCharacters.Ctrl_P.character:
            // Previous history item
            try moveHistory(editState: editState, direction: .previous)
            
        case ControlCharacters.Ctrl_N.character:
            // Next history item
            try moveHistory(editState: editState, direction: .next)
            
        case ControlCharacters.Ctrl_L.character:
            // Clear screen
            try clearScreen()
            try refreshLine(editState: editState)
            
        case ControlCharacters.Ctrl_T.character:
            if !editState.swapCharacterWithPrevious()
			{
                try output(character: .Bell)
            }
			else
			{
                try refreshLine(editState: editState)
            }
            
        case ControlCharacters.Ctrl_U.character:
            // Delete whole line
			editState.set(buffer: "")
            _ = editState.moveEnd()
            try refreshLine(editState: editState)
            
        case ControlCharacters.Ctrl_K.character:
            // Delete to the end of the line
            if !editState.deleteToEndOfLine()
			{
                try output(character: .Bell)
            }
            try refreshLine(editState: editState)
            
        case ControlCharacters.Ctrl_W.character:
            // Delete previous word
            if !editState.deletePreviousWord()
			{
                try output(character: .Bell)
            }
			else
			{
                try refreshLine(editState: editState)
            }
            
        case ControlCharacters.Backspace.character:
            // Delete character
            if editState.backspace()
			{
                try refreshLine(editState: editState)
            }
			else
			{
                try output(character: .Bell)
            }
            
        case ControlCharacters.Esc.character:
            try handleEscapeCode(editState: editState)
            
        default:
            // Insert character
            try insertCharacter(char, editState: editState)
            try refreshLine(editState: editState)
        }
        
        return nil
    }
    
    internal func editLine(prompt: String) throws -> String
	{
        try output(text: prompt)
        
        let editState: EditState = EditState(prompt: prompt)
        
        while true
		{
			guard var char = try inputFile.readCharacter(encoding: encoding)
			else { return "" }
            
            if char == ControlCharacters.Tab.character && completionCallback != nil
			{
                if let completionChar = try completeLine(editState: editState)
				{
                    char = completionChar
                }
            }
            
            if let rv = try handleCharacter(char, editState: editState)
			{
                return rv
            }
        }
    }

}
