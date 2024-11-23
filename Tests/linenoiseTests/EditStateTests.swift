/*
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

#if canImport(Nimble)
import Nimble
import XCTest
@testable import LineNoise

class EditStateTests: XCTestCase {
    
    func testInitEmptyBuffer() {
        let s = EditState(prompt: "$ ")
        expect(s.currentBuffer).to(equal(""))
        expect(s.location).to(equal(0))
        expect(s.prompt).to(equal("$ "))
    }
    
    func testInsertCharacter() {
        let s = EditState(prompt: "")
        s.insertCharacter("A"["A".startIndex])
        
        expect(s.currentBuffer).to(equal("A"))
        expect(s.location).to(equal(s.currentBuffer.count))
        expect(s.cursorPosition).to(equal(1))
    }
    
    func testBackspace() {
        let s = EditState(prompt: "")
        s.insertCharacter("A"["A".startIndex])
        
        expect(s.backspace()).to(beTrue())
        expect(s.currentBuffer).to(equal(""))
        expect(s.location).to(equal(0))
        
        // No more characters left, so backspace should return false
        expect(s.backspace()).to(beFalse())
    }
    
    func testMoveLeft() {
        let s = EditState(prompt: "")
		s.set(buffer: "Hello")
        s.location = s.currentBuffer.count
        
        expect(s.moveLeft()).to(beTrue())
        expect(s.cursorPosition).to(equal(4))
        
        s.location = 0
        expect(s.moveLeft()).to(beFalse())
    }
    
    func testMoveRight() {
        let s = EditState(prompt: "")
		s.set(buffer: "Hello")
		s.location = 0
        
        expect(s.moveRight()).to(beTrue())
        expect(s.cursorPosition).to(equal(1))
        
        s.location = s.currentBuffer.count
        expect(s.moveRight()).to(beFalse())
    }
    
    func testMoveHome() {
        let s = EditState(prompt: "")
		s.set(buffer: "Hello")
        s.location = s.currentBuffer.count
        
        expect(s.moveHome()).to(beTrue())
        expect(s.cursorPosition).to(equal(0))
        
        expect(s.moveHome()).to(beFalse())
    }
    
    func testMoveEnd() {
        let s = EditState(prompt: "")
		s.set(buffer: "Hello")
        s.location = 0
        
        expect(s.moveEnd()).to(beTrue())
        expect(s.cursorPosition).to(equal(5))
        
        expect(s.moveEnd()).to(beFalse())
    }
    
    func testRemovePreviousWord() {
        let s = EditState(prompt: "")
		s.set(buffer: "Hello world")
        s.location = s.currentBuffer.count
        
        expect(s.deletePreviousWord()).to(beTrue())
        expect(s.currentBuffer).to(equal("Hello "))
        expect(s.location).to(equal("Hello ".count))
        
		s.set(buffer: "")
        s.location = s.currentBuffer.count
        
        expect(s.deletePreviousWord()).to(beFalse())
        
        // Test with cursor location in the middle of the text
		s.set(buffer: "This is a test")
       	s.location = 8
        
        expect(s.deletePreviousWord()).to(beTrue())
        expect(s.currentBuffer).to(equal("This a test"))
    }
    
    func testDeleteToEndOfLine() {
        let s = EditState(prompt: "")
		s.set(buffer: "Hello world")
        s.location = s.currentBuffer.count
        
        expect(s.deleteToEndOfLine()).to(beFalse())
        
        s.location = 5
        
        expect(s.deleteToEndOfLine()).to(beTrue())
        expect(s.currentBuffer).to(equal("Hello"))
    }
    
    func testDeleteCharacter() {
        let s = EditState(prompt: "")
		s.set(buffer: "Hello world")
        s.location = s.currentBuffer.count
        
        expect(s.deleteCharacter()).to(beFalse())
        
        s.location = 0
        
        expect(s.deleteCharacter()).to(beTrue())
        expect(s.currentBuffer).to(equal("ello world"))
        
        s.location = 5
        
        expect(s.deleteCharacter()).to(beTrue())
        expect(s.currentBuffer).to(equal("ello orld"))
    }
    
    func testEraseCharacterRight() {
        let s = EditState(prompt: "")
		s.set(buffer: "Hello")
        s.location = s.currentBuffer.count
        
        expect(s.eraseCharacterRight()).to(beFalse())
        
        s.location = 0
        expect (s.eraseCharacterRight()).to(beTrue())
        expect(s.currentBuffer).to(equal("ello"))
        
        // Test empty buffer
		s.set(buffer: "")
        s.location = 0
        expect(s.eraseCharacterRight()).to(beFalse())
    }
    
    func testSwapCharacters() {
        let s = EditState(prompt: "")
		s.set(buffer: "Hello")
		s.location = s.currentBuffer.count
        
        // Cursor at the end of the text
        expect(s.swapCharacterWithPrevious()).to(beTrue())
        expect(s.currentBuffer).to(equal("Helol"))
        expect(s.location).to(equal(s.currentBuffer.count))
        
        // Cursor in the middle of the text
        s.location = s.currentBuffer.count
        expect(s.swapCharacterWithPrevious()).to(beTrue())
        expect(s.currentBuffer).to(equal("Hello"))
        expect(s.location).to(equal(s.currentBuffer.count))
        
        // Cursor at the start of the text
        s.location = 0
        expect(s.swapCharacterWithPrevious()).to(beTrue())
        expect(s.currentBuffer).to(equal("eHllo"))
        expect(s.location).to(equal(2))
    }

	func testInsertMultibyteUTF8()
	{
		let s = EditState(prompt: "? ")
		s.insertCharacter("λ")
		s.insertCharacter("A")

		expect(s.currentBuffer).to(equal("λA"))
		expect(s.location).to(equal(s.currentBuffer.count))
		expect(s.cursorPosition).to(equal(2))
		XCTAssert(s.moveHome(), "Failed to move to home")
		s.insertCharacter("(")
		expect(s.currentBuffer).to(equal("(λA"))
		expect(s.cursorPosition).to(equal(1))
	}
}

#if os(Linux) || os(FreeBSD)
    extension EditStateTests {
        static var allTests: [(String, (EditStateTests) -> () throws -> Void)] {
            return [
                ("testInitEmptyBuffer", testInitEmptyBuffer),
                ("testInsertCharacter", testInsertCharacter),
                ("testBackspace", testBackspace),
                ("testMoveLeft", testMoveLeft),
                ("testMoveRight", testMoveRight),
                ("testMoveHome", testMoveHome),
                ("testMoveEnd", testMoveEnd),
                ("testRemovePreviousWord", testRemovePreviousWord),
                ("testDeleteToEndOfLine", testDeleteToEndOfLine),
                ("testDeleteCharacter", testDeleteCharacter),
                ("testEraseCharacterRight", testEraseCharacterRight),
				("testInsertMultibyteUTF8", testInsertMultibyteUTF8),
            ]
        }
    }
#endif
#endif // canImport(Nimble)
