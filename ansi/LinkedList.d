/**
 * LinkedList.d
 * A simple doubly liked list.
 */

module ansi.LinkedList;

import ansi.interpreter;

class LinkedList {
	Link head = null;
	Link tail = null;

	void prepend(Link link) {
		//writefln("prepend");
		if(head is null) { // tail is null too
			//writefln("  head is null");
			head = link;
			tail = link;
		} else {
			//writefln("  head not null");
			//head.previous = link;
			link.next = head;
			head = link;
		}
	}

	void append(Link link) {
		if(head is null) {
			head = link;
			tail = link;
		} else {
			tail.next = link;
			//link.previous = tail;
			tail = link;
		}
	}

	Link popFront() {
		Link oldHead = head;
		//Link* temp = head.next;
		//if(head.next != null) {
		//	head.next.previous = null;
		//}
		if(head == tail) {
			head = null;
			tail = null;
		} else {
			head = head.next;
			oldHead.next = null;
		}
		return oldHead;
	}

	/*Link popBack() { // Doesn't work on a single linked list
		Link oldTail = tail;
		//if(tail.previous != null) {
		//	tail.previous.next = null;
		//}
		if(head == tail) {
			head = null;
			tail = null;
		}
		//tail.previous = null;
		//tail = tail.previous;
		return oldTail;
	}*/
	
	bool isEmpty(){
		return (head is null);
	}
}

class Link {
	char[] typeStr;
	union { int iValue; LinkedList list; BZKValue[char[]] aa; }
	//Link previous;
	Link next;

	this(int ival)               { this.iValue = ival; this.typeStr = "int";  }
	this(LinkedList l)           { this.list = l;      this.typeStr = "list"; }
	this(BZKValue[char[]] array) { this.aa = array;    this.typeStr = "aa";   }

	//void remove() { // doesn't work on a singly linked list
		//this.next.previous = this.previous;
		//this.previous.next = this.next;
		//this.next = null;
		//this.previous = null;
	//}

	/*void insertAfter(Link link) {
		link.next = this.next;
		//link.previous = this;
		//this.next.previous = link;
		this.next = link;
	}*/

	/*void insertBefore(Link link) { // doesn't work on a singly linked list
		link.previous = this.previous;
		link.next = this;
		this.previous.next = link;
		this.previous = link;
	}*/
}