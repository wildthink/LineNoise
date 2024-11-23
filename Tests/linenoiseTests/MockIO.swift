//
//  MockIO.swift
//  
//
//  Created by Jeremy Pereira on 23/03/2022.
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

import LineNoise
import Foundation

struct MockInput: LNInput
{
	var isTTY: Bool { true }
	let data: Data
	var index: Int = 0

	init(_ string: String, encoding: String.Encoding)
	{
		data = string.data(using: encoding)!
	}

	mutating func readByte() throws -> UInt8?
	{
		guard index < data.count else { return nil }
		let ret = data[index]
		index += 1
		return ret
	}

	func inRawMode(body: () throws -> ()) throws
	{
		try body()
	}

	func isSupported(terminal: String) -> Bool
	{
		true
	}
}

struct MockOutput: LNOutput
{
	var outputs: [[UInt8]] = []

	/// Write the string to our internal storage
	/// - Parameters:
	///   - text: The text to write
	///   - encoding: The encoding to use
	/// - Throws: if we can't encode the string
	mutating func write(text: String, encoding: String.Encoding) throws
	{
		guard let data = text.data(using: encoding)
		else { throw LineNoise.Error.cantEncode(text, encoding) }
		outputs.append(Array(data))
	}
}
