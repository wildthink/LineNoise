//
//  LineNoiseTests.swift
//  
//
//  Created by Jeremy Pereira on 23/03/2022.
//

import XCTest
@testable import LineNoise

class LineNoiseTests: XCTestCase
{

    override func setUpWithError() throws
	{
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws
	{
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSeveralLines() throws
	{
		let input = MockInput("abc\rdef\r", encoding: .utf8)
		let output = MockOutput()

		let ln = LineNoise(inputFile: input, outputFile: output, encoding: .utf8)
		do
		{
			let line1 = try ln.getLine(prompt: "")
			XCTAssert(line1 == "abc")
			let line2 = try ln.getLine(prompt: "")
			XCTAssert(line2 == "def", "line 2 was '\(line2)'")
		}
		catch
		{
			XCTFail("\(error)")
		}
    }

	func testNewLine() throws
 	{
		let input = MockInput("abc\ndef\r", encoding: .utf8)
		let output = MockOutput()

		let ln = LineNoise(inputFile: input, outputFile: output, encoding: .utf8)
		do
		{
			let line1 = try ln.getLine(prompt: "")
			XCTAssert(line1 == "abc")
			let line2 = try ln.getLine(prompt: "")
			XCTAssert(line2 == "def", "line 2 was '\(line2)'")
		}
		catch
		{
			XCTFail("\(error)")
		}
	}
}
