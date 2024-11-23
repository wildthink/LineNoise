/*
 Copyright (c) 2022, Jeremy Pereira <jeremy.j.pereira at icloud dot net>
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

import LineNoise
import Foundation
//import ArgumentParser

struct LineNoiseDemo // : ParsableCommand
{
	var eolMarker = false

	func run()
	{

		let ln = LineNoise(encoding: .utf8)

		ln.setCompletionCallback
		{
		  currentBuffer in
		  let completions = [
			  "Hello, world!",
			  "Hello, Linenoise!",
			  "Swift is Awesome!"
		  ]
		  return completions.filter { $0.hasPrefix(currentBuffer) }
		}

		ln.setHintsCallback
		{
		  currentBuffer in
		  let hints = [
			  "Carpe Diem",
			  "Lorem Ipsum",
			  "Swift is Awesome!"
		  ]

		  let filtered = hints.filter { $0.hasPrefix(currentBuffer) }

		  if let hint = filtered.first {
			  // Make sure you return only the missing part of the hint
			  let hintText = String(hint.dropFirst(currentBuffer.count))

			  // (R, G, B)
			  let color = (127, 0, 127)

			  return (hintText, color)
		  } else {
			  return (nil, nil)
		  }
		}

		do
		{
		  try ln.clearScreen()
		}
		catch
		{
		  print(error)
		}

		print("Type 'exit' to quit")

		var done = false
		while !done
		{
		  do
		  {
			  let output = try ln.getLine(prompt: "? ")
			  if eolMarker
			  {
				  print("<EOL>", terminator: "")
			  }
			  print("\nOutput: \(output)")
			  ln.addHistory(output)

			  // This next bit allows us to check that signals work
			  if output == "loop"
			  {
				  var loopCount = 0
				  while loopCount < 10000000
				  {
					  print(loopCount)
					  loopCount += 1
				  }
			  }
			  else if output == "exit"
			  {
				  // Typing 'exit' will quit
				  break
			  }
		  }
		  catch LineNoise.Error.CTRL_C
		  {
			  print("\nCaptured CTRL+C. Quitting.")
			  done = true
		  }
		  catch LineNoise.Error.EOF
		  {
			  print("\nEnd of input. Quitting.")
			  done = true
		  }
		  catch
		  {
			  print(error)
		  }
		}

	}
}

LineNoiseDemo().run()
