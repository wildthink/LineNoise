//
//  EncodingTests.swift
//  
//
//  Created by Jeremy Pereira on 16/03/2022.
//
@testable import LineNoise
import XCTest
import Foundation

class EncodingTests: XCTestCase
{
    func testUTF8()
	{
		let charString = "abcλαβψ"
		encodingTest(testChars: charString, encoding: .utf8)
	}

	func testISOLatin1()
	{
		let charString = "abc£µÖ"
		encodingTest(testChars: charString, encoding: .isoLatin1)
	}

	func encodingTest(testChars: String, encoding: String.Encoding)
	{
		var data = MockInput(testChars, encoding: encoding)

		for char in testChars
		{
			XCTAssert(try data.readCharacter(encoding: encoding) == char, "read of \(char) failed in \(encoding)")

		}
		XCTAssert(try data.readCharacter(encoding: encoding) == nil)
	}
}

