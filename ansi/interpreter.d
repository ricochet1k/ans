/**
 * interpreter.d
 * Interprets a BRZRK program when presented with a parse tree.
 */

module ansi.interpreter;


import ansi.scanner;
import ansi.parser;
import ansi.SymbolTable;
import Integer = tango.text.convert.Integer;
import tango.text.Util;
import tango.io.Console;

static char[] currline = null;
char readChar(){
	while(currline is null || currline.length == 0) currline = Cin.copyln();
	char c = currline[0];
	currline = currline[1..$];
	return c;
}
char[] readLine(){
	while(currline is null || currline.length == 0) return Cin.copyln();
	char[] l = currline;
	currline = null;
	return l;
}

enum ANSTypeEnum {
	Number,
	List,
	Tree
}

class ANSValue {
	ANSTypeEnum type;

	union {
		long intValue;
		ANSValue[] list;
		Node tree;
	}

	this() { }

	this(long value) {
		intValue = value;
		type = ANSTypeEnum.Number;
	}

	this(ANSValue[] value) {
		list = value;
		type = ANSTypeEnum.List;
	}

	this(Node value) {
		tree = value;
		type = ANSTypeEnum.Tree;
	}

	this(bool value) {
		if(value)
			this(1L);
		else
			this(0L);
	}
	
	ANSValue copy(){
		if(type == ANSTypeEnum.Number)
			return new ANSValue(intValue);
		if(type == ANSTypeEnum.List)
			return new ANSValue(list.dup);
		return this; // tree cannot be null
	}

	bool getBool() {
		if(type == ANSTypeEnum.Number)
			return (intValue != 0);
		if(type == ANSTypeEnum.List)
			return (list.length != 0);
		return true; // tree cannot be null
	}

	char[] typeString() {
		if(type == ANSTypeEnum.Number)
			return "number";
		if(type == ANSTypeEnum.List)
			return "list";
		return "tree";
	}
	
	char[] toString(){
		if(type == ANSTypeEnum.List)
			return listToCharArray(list,true);
		if(type == ANSTypeEnum.Number)
			return Integer.toString(intValue);
		throw new Exception("Cannot turn tree into string");
	}
}

char[] listToCharArray(ANSValue[] list,bool asStr) {
	char[] str;
	if(!asStr) str = "[";
	for(int i = 0; i < list.length; i++){
		if(list[i].type == ANSTypeEnum.Number)
			if(asStr) str ~= cast(char)list[i].intValue;
			else str ~= Integer.toString(list[i].intValue);
		else if(list[i].type == ANSTypeEnum.List)
			str ~= listToCharArray(list[i].list,asStr);
		else 
			throw new Exception("Cannot convert tree to string");
		if(!asStr && i < list.length - 1)
			str ~= ", ";
	}
	if(!asStr) str ~= "]";
	return str;
}

class BreakLoop {}

class Exit {}

class Interpreter {
	//Parser parser = null;
	private ParseTree tree;
	FunctionDescriptor[char[]] functions;
	private SymbolTable symbols = null;
	private bool inLoop = false;

	this(Parser p) {
		//this.parser = p;
		//Stdout.formatln("Parsing");
		tree = p.parse();
		//Stdout.formatln("Getting functions");
		functions = p.functions;
		//Stdout.formatln("Creating symbol table");
		symbols = new SymbolTable();
	//Stdout.formatln("Done");
	}

	int run(ANSValue[] arguments) {
		for(int i = 0; i < arguments.length; i++)
			symbols.set("_" ~ cast(char) ('a' + i), arguments[i]);
		try {
			//Stdout.formatln("Evaluating...");
			for(int i = 0; i < tree.topLevelNodes.length; i++)
				evaluate(tree.topLevelNodes[i]);
			//Stdout.formatln("Done");
			if(symbols.exists("_"))
				return symbols.get("_").intValue;
			return 0;
		}
		catch(BreakLoop bl) {
			throw new Exception("Break command outside loop.");
		} catch(Exit e) {}
		return 0;
	}

	private ANSValue evaluate(Node tTree) {
		ANSValue val = new ANSValue();
		if(tTree.type == NodeType.Digit) {
			//Stdout.formatln(" Digit");
			val.type = ANSTypeEnum.Number;
			val.intValue = Integer.toInt(tTree.text);
			return val;
		}
		if(tTree.type == NodeType.String) {
			//Stdout.formatln(" String");
			ANSValue[] str = new ANSValue[tTree.text.length];
			for(int i = 0; i < tTree.text.length; i++) {
				str[i] = new ANSValue(cast(int) tTree.text[i]);
			//writef(str.tail.typeStr ~ " "); Stdout.formatln(str.tail.iValue);
			}
			val.type = ANSTypeEnum.List;
			val.list = str;
			return val;
		}
		if(tTree.type == NodeType.Variable) {
			//Stdout.formatln(" Variable");
			if(symbols.exists(tTree.text)) {
				return symbols.get(tTree.text);
			}
			else
				throw new Exception("Unknown variable: " ~ tTree.text);
		}
		if(tTree.type == NodeType.FunctionCall) {
			//Stdout.formatln(" FunctionCall");
			if(tTree.text in builtins)
				//Stdout.formatln(tTree.text);
				return evaluateBuiltin(tTree);
			else if(tTree.text in functions)
				return evaluateFunction(tTree);
			else
				throw new Exception(tTree.text ~ " is not a known function.");
		}
	}

	private ANSValue evaluateBuiltin(Node tTree) {
		//Cout("Evaluating ")(tTree.text).newline;
		ANSValue zero = new ANSValue(0L);
		
		ANSValue[] params;
		params.length = tTree.children.length;
		for(int i = 0; i < params.length; i++) {
			if(i == 0 && (tTree.text == "Set" || tTree.text == "S" || tTree.text == "Exists" || tTree.text == "E" || tTree.text == "`"))
				//params[i] = new ANSValue(tTree.children[i]);
				continue;
			else
				params[i] = evaluate(tTree.children[i]);
		}
		
		switch(tTree.text) {
			/++++++++++++++++++++++++++++++++++++++++ Math +++++++++++++++++++++++++++++++++++++++/
			case "+", "-", "*", "/", "^", "%", "&", "|":
				char op = tTree.text[0];
				if(params[0].type != ANSTypeEnum.Number)
					throw new Exception("First argument to " ~ op ~ " must be type number not type " ~ params[0].typeString());
				if(params[1].type != ANSTypeEnum.Number)
					throw new Exception("Second argument to " ~ op ~ " must be type number not type " ~ params[1].typeString());
				ANSValue val = new ANSValue(0L);
				if(op == '+')
					val.intValue = params[0].intValue + params[1].intValue;
				else if(op == '-')
					val.intValue = params[0].intValue - params[1].intValue;
				else if(op == '*')
					val.intValue = params[0].intValue * params[1].intValue;
				else if(op == '/')
					val.intValue = params[0].intValue / params[1].intValue;
				else if(op == '^')
					val.intValue = params[0].intValue ^ params[1].intValue;
				else if(op == '%')
					val.intValue = params[0].intValue % params[1].intValue;
				else if(op == '&')
					val.intValue = params[0].intValue & params[1].intValue;
				else if(op == '|')
					val.intValue = params[0].intValue | params[1].intValue;
				else
					throw new Exception("Oops 1!");
				return val;
			case "~":
				if(params[0].type != ANSTypeEnum.Number)
					throw new Exception("Argument to ~ does not evaluate to a number.");
				params[0].intValue = ~params[0].intValue;
				return params[0];
			
			
			/++++++++++++++++++++++++++++++++++++++++ Logical +++++++++++++++++++++++++++++++++++++++/
			case "!":
				return new ANSValue(params[0].getBool() ? 0L : 1L);
			case "<", ">", "=":
				char op = tTree.text[0];
				if(params[0].type != ANSTypeEnum.Number)
					throw new Exception("First argument to " ~ op ~ " must be type number not type " ~ params[0].typeString());
				if(params[1].type != ANSTypeEnum.Number)
					throw new Exception("Second argument to " ~ op ~ " must be type number not type " ~ params[1].typeString());
				if(op == '<')
					return new ANSValue(params[0].intValue < params[1].intValue);
				else if(op == '>')
					return new ANSValue(params[0].intValue > params[1].intValue);
				else
					// op == '='
					return new ANSValue(params[0].intValue == params[1].intValue);
			case "Or", "O":
				return new ANSValue(params[0].getBool() || params[1].getBool());
			case "And", "A":
				return new ANSValue(params[0].getBool() && params[1].getBool());
			
			
			/++++++++++++++++++++++++++++++++++++++++ IO +++++++++++++++++++++++++++++++++++++++/
			case "$":
				// string print
				//Stdout.formatln("  String Print");
				//Stdout.formatln("  out");
				if(params[0].type == ANSTypeEnum.Number){
					char[] s = new char[1]; s[0] = cast(char) params[0].intValue;
					Cout(s);
				} else if(params[0].type == ANSTypeEnum.List)
					Cout(listToCharArray(params[0].list,true));
				else
					throw new Exception("Cannot convert tree to string");
				return zero;
			case "#":
				// number print
				//Cout("number print").newline;
				if(params[0].type == ANSTypeEnum.Number)
					Cout(Integer.toString(params[0].intValue));
				else if(params[0].type == ANSTypeEnum.List)
					Cout(listToCharArray(params[0].list,false));
				else
					throw new Exception("Cannot convert tree to string");
				Cout.flush;
				return zero;
			case "Nl", "N":
				Cout.newline;
				return zero;
			case "'":
				return new ANSValue(cast(int) readChar());
			case "?":
				return new ANSValue(Integer.toInt(readLine()));
			
			/++++++++++++++++++++++++++++++++++++++++ Lists +++++++++++++++++++++++++++++++++++++++/
			case ".": // list get (list, index)
				return params[0].list[params[1].intValue];
			case ",": // list set (list, index, newvalue)
				params[0].list[params[1].intValue] = params[2];
			case "Slice", "Sl":
				return new ANSValue(params[0].list[params[1].intValue .. params[2].intValue]);
			case "Listappend", "La":
				return new ANSValue(params[0].list ~ params[1]);
			case "Listconcat", "Lc":
				return new ANSValue(params[0].list ~ params[1].list);
			case "List", "L":
				return new ANSValue(new ANSValue[0]);
			case "Listsize", "Ls":
				return new ANSValue(params[0].list.length);
			case "Format", "Ft":
				char[] str = listToCharArray(params[0].list,true);
				char[] newstr,var;
				int i = 0;
				int slicestart;
				while(i < str.length){
					slicestart = i;
					while(i < str.length && str[i] != '~') i++;
					//Cout("newstr ~= \"")(str[slicestart..i])("\" [")(Integer.toString(slicestart))(", ")(Integer.toString(i))("]").newline;
					newstr ~= str[slicestart..i];
					//Cout("str = ")(newstr).newline;
					if(i == str.length) break;
					// encountered ~
					//Cout("~ at ")(Integer.toString(i)).newline;
					i++;
					slicestart = i;
					while(i < str.length && str[i] != '~') i++;
					if(i == str.length) throw new Exception("unmatched ~");
					if(i == slicestart)
						newstr ~= str[i];
					else {
						var = str[slicestart..i];
						//Cout("var = ")(var)(" [")(Integer.toString(slicestart))(", ")(Integer.toString(i)).newline;
						if(symbols.exists(var)){
							ANSValue val = symbols.get(var);
							if(val.type == ANSTypeEnum.Number)
								newstr ~= cast(char) val.intValue;
							else if(val.type == ANSTypeEnum.List)
								newstr ~= listToCharArray(val.list,true);
							else
								throw new Exception("Cannot convert tree to string");
						} else throw new Exception("variable " ~ var ~ " doesn't exist");
					}
					i++;
					//Cout("nstr = ")(newstr).newline;
				}
				ANSValue[] ret;
				ret.length = newstr.length;
				for(int j = 0; j < newstr.length; j++)
					ret[j] = new ANSValue(cast(int)newstr[j]);
				return new ANSValue(ret);
			
			/++++++++++++++++++++++++++++++++++++++++ Variables +++++++++++++++++++++++++++++++++++++++/
			case "Set", "S":
				if(tTree.children[0].type != NodeType.Variable)
					throw new Exception("Expected variable name after Set");
				symbols.set(tTree.children[0].text, params[1].copy);
				return params[1];
			case "Exists", "E":
				if(tTree.children[0].type != NodeType.Variable)
					throw new Exception("Exists needs a variable, not a " ~ nodeTypeStrings[tTree.children[0].type]);
				return new ANSValue(symbols.exists(tTree.children[0].text));
			case "Islist", "Il":
				return new ANSValue(params[0].type == ANSTypeEnum.List);
			case "Isnumber", "In":
				return new ANSValue(params[0].type == ANSTypeEnum.Number);
			case "Istree", "It":
				return new ANSValue(params[0].type == ANSTypeEnum.Tree);
			
			
			/++++++++++++++++++++++++++ Loops and conditionals ++++++++++++++++++++++++++++++++++/
			case "If", "I":
				if(params[0].getBool())
					return evaluate(params[1].tree);
				return zero;
			case "Ifelse", "Ie":
				if(params[0].getBool())
					return evaluate(params[1].tree);
				else
					return evaluate(params[2].tree);
			case "While", "W":
				if(tTree.children[0].text != "`")
					throw new Exception("Expression of While must use `");
				if(tTree.children[1].text != "`")
					throw new Exception("Body of While must use `");
				inLoop = true;
				try {
					while(evaluate(params[0].tree).getBool()) {
						evaluate(params[1].tree);
					}
				}
				catch(BreakLoop bl) { }
				finally {
					inLoop = false;
				}
				return zero;
			case "Do", "D":
				if(params[0].type != ANSTypeEnum.Tree)
					throw new Exception("Expecting tree for expression of Do");
				if(params[1].type != ANSTypeEnum.Tree)
					throw new Exception("Expecting tree for body of Do");
				inLoop = true;
				try {
					do {
						evaluate(params[1].tree);
					} while(evaluate(params[0].tree).getBool());
				}
				catch(BreakLoop bl) { }
				finally {
					inLoop = false;
				}
				return zero;
			case "For", "F":
				//Cout("Start of For").newline;
				if(tTree.children[0].type != NodeType.Variable)
					throw new Exception("Expected variable as first param in For");
				if(params[0].type != ANSTypeEnum.Number)
					throw new Exception("Expected a variable set to a number as first param in For");
				if(params[1].type != ANSTypeEnum.Number)
					throw new Exception("Expecting number value as second param in For");
				if(params[2].type != ANSTypeEnum.Tree)
					throw new Exception("Body of For not a tree (" ~ params[2].typeString ~ ")");
				//Cout("End checks").newline;
				int start = params[0].intValue;
				int end = params[1].intValue;
				int incr = 1;
				if(start > end)
					incr = -1;
				char[] varname = tTree.children[0].text;
				ANSValue var = symbols.get(varname);
				inLoop = true;
				//Cout("Start try").newline;
				try {
					for(int i = start; i != end + incr; i += incr) {
						//Stdout.formatln("i: %d",i);
						var.intValue = i;
						symbols.set(varname, var);
						evaluate(params[2].tree);
					
					}
				}
				catch(BreakLoop bl) {
				}
				finally {
					inLoop = false;
				}
				return zero;
			
			
			/++++++++++++++++++++++++++++++++++++++++ Other +++++++++++++++++++++++++++++++++++++++/
			case "B":
				return params[1];
			case "\\":
				throw new BreakLoop();
			case "@":
				throw new Exit();
			case "`":
				if(tTree.children[0].type == NodeType.Variable) {
					ANSValue val = symbols.get(tTree.children[0].text);
					if(val.type != ANSTypeEnum.Tree)
						throw new Exception("` cannot be used with variable type " ~ val.typeString());
					return evaluate(val.tree);
				}
				return new ANSValue(tTree.children[0]);
			default:
				throw new Exception("Command not found: " ~ tTree.text);
		}
	}

	private ANSValue evaluateFunction(Node tTree) {
		//Stdout.formatln("Starting non builtin function");
		ANSValue[] params = new ANSValue[tTree.children.length];
		for(int i = 0; i < tTree.children.length; i++)
			params[i] = evaluate(tTree.children[i]);
		symbols.pushScope();
		for(int i = 0; i < tTree.children.length; i++)
			symbols.set("_" ~ cast(char) ('a' + i), params[i]);
		symbols.set("_", new ANSValue(0L));
		try {
			evaluate(functions[tTree.text].functionBody);
		}
		catch(BreakLoop bl) {
			throw new Exception("Break command outside loop.");
		} catch(Exit e) {}
		ANSValue ret = symbols.get("_");
		symbols.popScope();
		return ret;
	}
}
