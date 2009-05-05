/**
 * SymbolTable.d
 * A simple symbol table
 */

module ansi.SymbolTable;


import ansi.interpreter;

class SymbolTable {
	private Scope currScope = null;

	this() {
		currScope = new Scope();
	}

	void pushScope() {
		Scope temp = new Scope();
		temp.nextScope = currScope;
		currScope = temp;
	}

	void popScope() {
		Scope temp = currScope.nextScope;
		currScope.nextScope = null;
		currScope = temp;
	}

	void set(char[] key, ANSValue value, bool force = false) {
		if(force) currScope.forceSet(key,value);
		else currScope[key] = value;
	}

	ANSValue get(char[] key) {
		return currScope[key];
	}

	bool exists(char[] key) {
		return currScope.exists(key);
	}
}

class Scope {
// Scope doesn't need to look up the chain,
// functions should be restricted to their scope (or should they?)
	ANSValue[char[]] vars;
	Scope nextScope = null;

	ANSValue opIndex(char[] key) {
		if(key in vars)
			return vars[key];
		//if(nextScope is null)
		return null;
		//return nextScope[key];
	}

	void opIndexAssign(ANSValue val, char[] key) {
		//if(key in vars || nextScope is null)
		vars[key] = val;
		//else if(nextScope.exists(key))
		//	nextScope[key] = val;
		//else
		//	vars[key] = val;
	}
	
	void forceSet(char[] key, ANSValue val) {
		vars[key] = val;
	}

	bool exists(char[] key) {
		if(key in vars)
			return true;
		//if(nextScope !is null)
		//	return nextScope.exists(key);
		return false;
	}
}
