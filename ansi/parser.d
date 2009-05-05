/**
 * parser.d
 * Generates a parse tree from the code
 */

module ansi.parser;


import ansi.interpreter;
import ansi.scanner;
import tango.io.device.File;
import Integer = tango.text.convert.Integer;

enum NodeType {
	FunctionCall,
	Variable,
	Digit,
	String
}

char[][] nodeTypeStrings = ["function call", "variable","digit","string"];

struct ParseTree {
	Node[] topLevelNodes;
	FunctionDescriptor[char[]] functions;
}

struct FunctionDescriptor {
	char[] name;
	int params;
	Node functionBody;
}

struct Node {
	NodeType type;
	char[] text;
	Node[] children;
	ANSValue val = null;
}

int[char[]] builtins; // num of parameters for each builtin function

static this() { // Build builtins lookup table
	builtins["+"] = 2;
	builtins["-"] = 2;
	builtins["*"] = 2;
	builtins["/"] = 2;
	builtins["^"] = 2;
	builtins["%"] = 2;
	builtins["~"] = 1;
	builtins["&"] = 2;
	builtins["|"] = 2;
	builtins["!"] = 1;
	builtins["<"] = 2;
	builtins[">"] = 2;
	builtins["="] = 2;
	builtins["Or"] = 2;
	builtins["O"] = 2;
	builtins["And"] = 2;
	builtins["A"] = 2;
	builtins["$"] = 1;
	builtins["#"] = 1;
	builtins["Nl"] = 0;
	builtins["N"] = 0;
	builtins["'"] = 0;
	builtins["?"] = 0;
	builtins["."] = 2;
	builtins[","] = 3;
	builtins["Slice"] = 3;
	builtins["Sl"] = 3;
	builtins["Listappend"] = 2;
	builtins["La"] = 2;
	builtins["Listconcat"] = 2;
	builtins["Lc"] = 2;
	builtins["List"] = 0;
	builtins["L"] = 0;
	builtins["Listsize"] = 1;
	builtins["Ls"] = 1;
	builtins["Format"] = 1;
	builtins["Ft"] = 1;
	builtins["Set"] = 2;
	builtins["S"] = 2;
	builtins["Exists"] = 1;
	builtins["E"] = 1;
	builtins["Islist"] = 1;
	builtins["Il"] = 1;
	builtins["Isnumber"] = 1;
	builtins["In"] = 1;
	builtins["Istree"] = 1;
	builtins["It"] = 1;
	builtins["If"] = 2;
	builtins["I"] = 2;
	builtins["Ifelse"] = 3;
	builtins["Ie"] = 3;
	builtins["While"] = 2;
	builtins["W"] = 2;
	builtins["Do"] = 2;
	builtins["D"] = 2;
	builtins["For"] = 3;
	builtins["F"] = 3;
	builtins["\\"] = 0;
	builtins["@"] = 0;
	builtins["`"] = 1;
	builtins["B"] = 2;
	builtins.rehash;
}

class Parser {
	public Scanner s = null;
	public FunctionDescriptor[char[]] functions;
	private ParseTree root;
	private bool parsed = false;

	this(char[] f) { s = new Scanner(f, false); }

	this(Scanner scanner) {
		s = scanner;
		s.returnComments = false;
	}

	ParseTree parse() {
		//ParseTree root;
		if(parsed) return root;
		Node temp;
		
		while (s.peekToken().type != TokenType.EOF) {
			if(!parseFunctionDefinition()) {
				if(!parseFunctionCall(temp))
					throw new Exception("Expecting function call or definition");
				root.topLevelNodes ~= temp;
			}
		}
		
		this.functions.rehash;
		root.functions = this.functions;
		parsed = true;
		return root;
	}

	private:
		bool parseFunctionCall(out Node call) {
			Token t = s.nextToken();
			Node temp;
			if(t.type != TokenType.FunctionName) {
				s.putBack();
				return false;
			}
			call.type = NodeType.FunctionCall;
			call.text = t.text;
			if(call.text == "Func")
				throw new Exception("Wrong place for a function definition");
			int numParams;
			if(call.text in builtins)
				numParams = builtins[call.text];
			else if(call.text in functions)
				numParams = functions[call.text].params;
			else
				throw new Exception("Unknown function: " ~ call.text);
			call.children.length = numParams;
			for(int i = 0; i < numParams; i++) {
				if(parseFunctionCall(temp) || parseVariable(temp) || parseDigit(temp) || parseString(temp))
					call.children[i] = temp;
				else
					throw new Exception("Expecting variable, digit, string or function call after " ~ call.text);
			}
			return true;
		}

		bool parseVariable(out Node var) {
			Token t = s.nextToken();
			if(t.type != TokenType.VariableName) {
				s.putBack();
				return false;
			}
			var.type = NodeType.Variable;
			var.text = t.text;
			return true;
		}

		bool parseDigit(out Node digit) {
			Token t = s.nextToken();
			if(t.type != TokenType.Digit) {
				s.putBack();
				return false;
			}
			digit.type = NodeType.Digit;
			digit.text = t.text;
			return true;
		}
		
		bool parseString(out Node str) {
			Token t = s.nextToken();
			if(t.type != TokenType.String) {
				s.putBack();
				return false;
			}
			str.type = NodeType.String;
			str.text = t.text;
			return true;
		}

		bool parseFunctionDefinition() {
			Token t = s.nextToken();
			char[] fname;
			int numParams;
			//FunctionDescriptor* fd = new FunctionDescriptor;
			if(t.type != TokenType.FunctionName) {
				s.putBack();
				return false;
			}
			if(t.text != "Func" && t.text != "Fc") {
				s.putBack();
				return false;
			}
			t = s.nextToken();
			if(t.type != TokenType.FunctionName)
				throw new Exception("Expecting a function name after Func");
			//Check to see if function already exists
			if(t.text in builtins || t.text in functions)
				throw new Exception("Function " ~ t.text ~ " already exists.");
			fname = t.text;
			functions[fname] = *new FunctionDescriptor;
			functions[fname].name = fname;
			t = s.nextToken();
			if(t.type != TokenType.Digit)
				throw new Exception("Expecting number of parameters for function " ~ fname);
			numParams = Integer.toInt(t.text);
			functions[fname].params = numParams;
			//Node temp;
			if(!parseFunctionCall(functions[fname].functionBody))
				throw new Exception("Expecting function body for definition of function " ~ fname);
			if(functions[fname].functionBody.text != "`") {
				throw new Exception("` must be used for function body of function " ~ fname);
			}
			functions[fname].functionBody = functions[fname].functionBody.children[0];
			return true;
		}
}
