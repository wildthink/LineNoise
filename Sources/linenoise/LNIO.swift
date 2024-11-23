//
//  LNIO.swift
//  
//
//  Created by Jeremy Pereira on 17/03/2022.
//
//  Copyright (c) Jeremy Pereira 2022
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import System
import Foundation

/// Input files must conform to this protocol
public protocol LNInput
{
	/// True if the input file is a tty
	var isTTY: Bool { get }

	/// Read a single byte from the input
	/// - Returns: The byte read or `nil` if end of file.
	/// - Throws: If there's an IO error.
	mutating func readByte() throws -> UInt8?

	/// Puts the input into raw mode (if supported)
	///
	/// - Parameters:
	///   - body: A closure to execute.
	/// - Throws: If an exception occurs getting into raw mode or the closure throws
	func inRawMode(body: () throws -> ()) throws

	/// Tell us if the terminal type is supported by this input
	/// - Parameter terminal: The terminal in question
	/// - Returns: `true` if the terminal is supported
	func isSupported(terminal: String) -> Bool
}

public extension LNInput
{
	/// Read a character from the input and decode it with the given encoding
	///
	/// A default implementation is provided.
	/// - Parameter encoding: The encoding to use
	/// - Returns: A character or `nil` if end of input
	/// - Throws: if there is an IO error or the character cannot be decoded
	mutating func readCharacter(encoding: String.Encoding) throws -> Character?
	{
		let bytes: [UInt8]
		switch encoding
		{
		case .utf8:
			bytes = try readUTF8()
		default:
			if let input = try readByte()
			{
				bytes = [input]
			}
			else
			{
				bytes = []
			}
		}
		guard bytes.count > 0 else { return nil }
		guard let ret =  String(bytes: bytes, encoding: encoding)?.first
		else { throw LineNoise.Error.unsupportedEncoding(encoding) }
		return ret
	}

	/// Read UTF-8 bytes from the input
	/// - Parameter inputFile: Unix file descriptor of readable file
	/// - Throws: If the input is not valid UTF-8
	/// - Returns: A UTF-8 byte sequence
	private mutating func readUTF8() throws -> [UInt8]
	{
		guard let byte = try readByte() else { return [] }

		var unicodePoint = [byte]
		let extensionChars = try byte.utf8ByteCount() - 1
		for _ in  0 ..< extensionChars
		{
			guard let byte = try readByte() else { throw LineNoise.Error.truncatedUTF8 }
			guard byte.leadingOneCount == 1
			else
			{
				throw LineNoise.Error.invalidUTF8Continuation(byte)
			}
			unicodePoint.append(byte)
		}
		return unicodePoint
	}
}
/// Output files must conform to this protocol
/// - Todo: Terminal support test
public protocol LNOutput
{
	/// Write a string to self using the given encoding
	/// - Parameters:
	///   - text: The text string to write
	///   - encoding: The encoding to use to translate the text to raw bytes
	/// - Throws: If there's an IO error or the encoding doesn't work
	mutating func write(text: String, encoding: String.Encoding) throws
}

@available(macOS 11.0, *)
extension FileDescriptor: LNInput
{
	public var isTTY: Bool
	{
		Terminal.isTTY(self.rawValue)
	}

	public func readByte() throws -> UInt8?
	{
		var input: UInt8 = 0
		let count = Darwin.read(self.rawValue, &input, 1)
		guard count != -1 else { throw Errno(rawValue: errno) }
		return count == 0 ? nil : input
	}

	public func inRawMode(body: () throws -> ()) throws
	{
		if !isTTY
		{
			throw LineNoise.Error.notATTY
		}

		var originalTermios: termios = termios()

		if tcgetattr(rawValue, &originalTermios) == -1
		{
			throw Errno(rawValue: errno)
		}

		var raw = originalTermios

		#if os(Linux) || os(FreeBSD)
			raw.c_iflag &= ~UInt32(BRKINT | ICRNL | INPCK | ISTRIP | IXON)
			raw.c_oflag &= ~UInt32(OPOST)
			raw.c_cflag |= UInt32(CS8)
			raw.c_lflag &= ~UInt32(ECHO | ICANON | IEXTEN | ISIG)
		#else
			raw.c_iflag &= ~UInt(BRKINT | ICRNL | INPCK | ISTRIP | IXON)
			raw.c_oflag &= ~UInt(OPOST)
			raw.c_cflag |= UInt(CS8)
			raw.c_lflag &= ~UInt(ECHO | ICANON | IEXTEN | ISIG)
		#endif

		// VMIN = 16
		raw.c_cc.16 = 1

		if tcsetattr(rawValue, Int32(TCSADRAIN), &raw) < 0
		{
			throw Errno(rawValue: errno)
		}
		defer
		{
			// Disable raw mode
			_ = tcsetattr(rawValue, TCSADRAIN, &originalTermios)
		}
		// Run the body
		try body()

	}

	public func isSupported(terminal: String) -> Bool
	{
#if os(macOS)
		if let xpcServiceName = ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"], xpcServiceName.localizedCaseInsensitiveContains("com.apple.dt.xcode")
		{
			return false
		}
#endif
		return !["", "dumb", "cons25", "emacs"].contains(terminal)
	}
}

extension FileDescriptor: LNOutput
{
	public func write(text: String, encoding: String.Encoding) throws
	{
		guard let dataToWrite = text.data(using: encoding)
		else { throw LineNoise.Error.cantEncode(text, encoding) }
		try writeAll(dataToWrite)
	}

}


fileprivate extension UInt8
{
	/// Number of leading one bits
	var leadingOneCount: Int { (~self).leadingZeroBitCount }

	/// If this is a lead byte in a UTF-8 code point, calculate how many
	///  bytes there are in the entire code point **including this one**
	/// - Throws: If this is not a leading byte i.e. if it starts `0b10...`
	/// - Returns: the entire code point byte count, will be in the range `1 ... 4`
	func utf8ByteCount() throws -> Int
	{
		switch leadingOneCount
		{
		case 0: return 1
		case 2: return 2
		case 3: return 3
		case 4: return 4
		default: throw LineNoise.Error.invalidUTF8Start(self)
		}
	}
}
