/**
 * brzrk.d
 * An interpreter for the Ans language.
 */

module ans;


import tango.io.device.File;
import tango.io.Stdout;
import tango.io.Console;
import Integer = tango.text.convert.Integer;

import ansi.scanner;
import ansi.parser;
import ansi.interpreter;


char[][] TokenTypes = ["FUNC", "VAR ", "DIGT", "STR ", "CMNT", "EOF "];
char[][] NodeTypes = ["FUNC", "VAR ", "DIGT", "STR "];

void main(char[][] args) {
	if(args.length == 1){
		Cout("Filename must be specified.").newline;
		return;
	}
	char[] filename = args[1];
	bool showComments = false, scan = false, parse = false, run = true;
	for(int i = 2; i < args.length; i++){
		switch(args[i]){
		case "-s":
			scan = !scan;
			break;
		case "-p":
			parse = !parse;
			break;
		case "-r":
			run = !run;
			break;
		case "-sc":
			showComments = true;
			break;	
		}
	}
	//File f = new File(filename, File.ReadExisting);
	
	Scanner s = new Scanner(filename, showComments);
	s.rewind();
	
	if(scan) {
		Cout("***Scanning phase***").newline;	
		Token t;
		t = s.nextToken();
		while (t.type != TokenType.EOF) {
			Cout(TokenTypes[cast(int) t.type]);
			Cout(": ");
			Cout(t.text).newline;
			t = s.nextToken();
		}
		Cout.newline;
	}
	Parser p;
	if(parse || run) {
		s.rewind();
		p = new Parser(s);
	}
	if(parse) {
		Cout("***Parsing phase***").newline;
		ParseTree pt = p.parse();
		if(pt.functions.length == 0)
			Cout("No function defenitions.").newline;
		else {
			Cout("Functions:").newline;
			for(int i = 0; i < pt.functions.values.length; i++) {
				Cout("  (")(Integer.toString(pt.functions.values[i].params))(")")(pt.functions.values[i].name);
				printNode(pt.functions.values[i].functionBody, 1);
				Cout.newline;
			}
		}
		Cout("Tree:").newline;
		for(int i = 0; i < pt.topLevelNodes.length; i++)
			printNode(pt.topLevelNodes[i]);
	}
	if(run) {
		ANSValue[] arguments;
		arguments.length = 0;
		Interpreter i = new Interpreter(p);
		//Cout("***Running program***").newline;
		i.run(arguments);
	}
//char c = getchar();
//putchar(c);
}

void printNode(Node n, int indentlevel = 0) {
	Cout(NodeTypes[cast(int) n.type])(" ");
	for(int i = 0; i < indentlevel; i++)
		Cout("--");
	Cout("> ")(n.text).newline;
	for(int i = 0; i < n.children.length; i++)
		printNode(n.children[i], indentlevel + 1);
}
