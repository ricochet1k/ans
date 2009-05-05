/**
 * scanner.d
 * Implements token scanning.
 */

module ansi.scanner;


import tango.io.Console;
import tango.text.Util;
import tango.text.Unicode;
import tango.io.device.File;
import tango.io.model.IConduit;
import Integer = tango.text.convert.Integer;

enum TokenType {
	FunctionName = 0,
	VariableName,
	Digit,
	String,
	Comment,
	EOF
}

struct Token {
	TokenType type;
	char[] text;
}

class Scanner {
	public bool returnComments;
	private Token[] tokens;
	private int index = 0; //Current index in tokens array
	
	private Token EOFtok;
	
	private char[] file;
	private uint fileLoc;

	this(char[] f, bool returnComments = false) {
		//this.stream = stream;
		this.returnComments = returnComments;
		EOFtok.type = TokenType.EOF;
		
		//Cout("a").newline;
		file = cast(char[])File.get(f);
		//Cout("b").newline;
		//Cout(Integer.toString(file.length)).newline;
		fileLoc = 0;
		
		Token t = getNextToken();
		//Cout(t.text).newline;
		while (t.type != TokenType.EOF) {
			tokens ~= t;
			//Cout(t.text).newline;
			t = getNextToken();
		}
		file = null;
		fileLoc = 0;
	}
	
	private bool EOF(){
		return file is null || fileLoc >= file.length;
	}
	
	private char getChar(){
		if(EOF) return 0;
		/*char[] s = new char[1];
		s[0] = file[fileLoc];
		Cout(s).flush;*/
		return file[fileLoc++];
	}
	
	private void ungetChar(){
		if(fileLoc > 0) fileLoc--;
	}

	private Token getNextToken() {
		Token ret;
		if(EOF)
			return EOFtok;
		char c = getChar();
		while (isWhitespace(c) || c == '{') {
			if(c == '{') {
				while (c == '{') { // comment
					if(returnComments) {
						ret.type = TokenType.Comment;
					}
					c = getChar();
					while (c != '}') {
						if(returnComments)
							ret.text ~= c;
						if(EOF)
							throw new Exception("Premature end of file in comment.");
						c = getChar();
					}
					if(returnComments)
						return ret;
					if(EOF)
						return EOFtok;
					c = getChar();
				}
			} else {
				if(EOF)
					return EOFtok;
				c = getChar();
			}
		}
		if(c == '"') { // String
			ret.type = TokenType.String;
			c = getChar();
			while (c != '"') {
				if(EOF)
					throw new Exception("Premature end of file in string.");
				ret.text ~= c;
				c = getChar();
			}
			return ret;
		}
		if(isDigit(c)) {
			ret.type = TokenType.Digit;
			ret.text ~= c;
			return ret;
		}
		if(isUpper(c))
			ret.type = TokenType.FunctionName;
		if(c == '_')
			ret.type = TokenType.VariableName;
		if(isUpper(c) || c == '_') {
			//Cout(c);
			ret.text ~= c;
			if(EOF)
				return ret;
			c = getChar();
			while (c >= 'a' && c <= 'z') { // loop until a char is not a lowercase letter
				//Cout(c);
				ret.text ~= c;
				if(EOF)
					return ret;
				c = getChar();
			}
			//Cout(c);
			ungetChar(); // return the last grabbed char to the input stream
			return ret;
		} // +-*/^%~&|!<>=$#''?.,;\@`
		if(contains("+-*/^%~&|!<>=$#'?.,;\\@`" /*'*/, c)) {
			ret.type = TokenType.FunctionName;
			ret.text ~= c;
			return ret;
		}
		throw new Exception("Unknown char (" ~ c ~ ")");
	}

	Token nextToken() {
		if(index != tokens.length)
			return tokens[index++];
		return EOFtok;
	}

	Token peekToken() {
		if(index != tokens.length)
			return tokens[index];
		return EOFtok;
	}

	void putBack() { if(index > 0)
		index--;
	else
		throw new Exception("Can't put back before beginning");
	}

	void rewind() { index = 0; }
}
