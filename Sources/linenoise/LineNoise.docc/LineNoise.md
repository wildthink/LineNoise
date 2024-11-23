# ``LineNoise``

A lightweight Swift replacement for the GNU readline library: supports line 
editing, history and tab completions.

## Overview

This is a pure Swift implementation of the [Linenoise](http://github.com/antirez/linenoise) 
library. A minimal, zero-config readline replacement. This version (Linenoise-Swift-UTF8) - based on 
 [linenoise-swift](https://github.com/andybest/linenoise-swift) - is modified for 
better support for UTF-8.

### Supports
* Mac OS and Linux
* Line editing with emacs keybindings
* History handling
* Completion
* Hints
* UTF-8 and 8 bit character sets

### Pure Swift
Implemented in pure Swift, with a Swifty API, this library is easy to embed in 
projects using Swift Package Manager. It currently has two dependencies:

- [Swift-System](https://github.com/apple/swift-system) for some file handling manipulation
- [Nimble](https://github.com/Quick/Nimble) which is used in the test suite.

## Quick Start
Linenoise-Swift is easy to use, and can be used as a replacement 
for [`Swift.readLine`](https://developer.apple.com/documentation/swift/1641199-readline). 
Here is a simple example:

```swift
let ln = LineNoise()

do 
{
	let input = try ln.getLine(prompt: "> ")
} 
catch 
{
	print(error)
}
	
```

## Basics
Simply creating a new `LineNoise` object is all that is necessary in most cases, 
with STDIN used for input and STDOUT used for output by default. However, it is 
possible to supply different files for input and output if you wish:

```swift
// 'in' and 'out' are objects that conform to LNInput and LNOutput
let ln = LineNoise(inputFile: in, outputFile: out)
```

`in` must conform to ``LNInput`` and `out` must conform to ``LNOutput``. The
`FileDescriptor` type from `Swift-System` has been extended to conform to both.

## History
### Adding to History
Adding to the history is easy:

```swift
let ln = LineNoise()

do 
{
	let input = try ln.getLine(prompt: "> ")
	ln.addHistory(input)
} 
catch 
{
	print(error)
}
```

### Limit the Number of Items in History
You can optionally set the maximum amount of items to keep in history. Setting 
this to `nil` (the default) will keep an unlimited amount of items in history.
```swift
ln.setHistoryMaxLength(100)
```

### Saving the History to a File
```swift
ln.saveHistory(toFile: "/tmp/history.txt")
```

### Loading History From a File
This will add all of the items from the file to the current history
```swift
ln.loadHistory(fromFile: "/tmp/history.txt")
```

### History Editing Behavior
By default, any edits by the user to a line in the history will be discarded if 
the user moves forward or back in the history without pressing Enter.  If you 
prefer to have all edits preserved, then use the following:
```swift
ln.preserveHistoryEdits = true
```

## Completion
![Completion example](completion.gif)

Linenoise supports completion with `tab`. You can provide a callback to return 
an array of possible completions:

```swift
let ln = LineNoise()

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
```

The completion callback gives you whatever has been typed before `tab` is 
pressed. Simply return an array of Strings for possible completions. These can be 
cycled through by pressing `tab` multiple times.

## Hints
![Hints example](hints.gif)

Linenoise supports providing hints as you type. These will appear to the right 
of the current input, and can be selected by pressing <kbd>tab</kbd>.

The hints callback has the contents of the current line as input, and returns a 
tuple consisting of an optional hint string and an optional color for the hint 
text, e.g.:

```swift
let ln = LineNoise()

ln.setHintsCallback { currentBuffer in
	let hints = [
		"Carpe Diem",
		"Lorem Ipsum",
		"Swift is Awesome!"
	]
	
	let filtered = hints.filter { $0.hasPrefix(currentBuffer) }
	
	if let hint = filtered.first 
	{
		// Make sure you return only the missing part of the hint
		let hintText = String(hint.dropFirst(currentBuffer.count))
		
		// (R, G, B)
		let color = (127, 0, 127)
		
		return (hintText, color)
	} 
	else 
	{
		return (nil, nil)
	}
}

```

## Acknowledgements
This package started as a clone of [Linenoise-Swift](https://github.com/andybest/linenoise-swift) 
with modifications to support UTF-8 multibyte characters. Linenoise-Swift is 
heavily based on the [original linenoise library](http://github.com/antirez/linenoise) 
by [Salvatore Sanfilippo (antirez)](http://github.com/antirez)

