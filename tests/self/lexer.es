
/* -*- mode: java; mode: font-lock; tab-width: 4; insert-tabs-mode: nil; indent-tabs-mode: nil -*- */
/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is [Open Source Virtual Machine.].
 *
 * The Initial Developer of the Original Code is
 * Adobe System Incorporated.
 * Portions created by the Initial Developer are Copyright (C) 2004-2006
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *   Adobe AS3 Team
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

/*
    TODO

    o punctuators
    o escapes
    o reserved words
    o number literals
    o string literals
    o regexp literals
    x lex break
*/

use namespace intrinsic;

namespace Char

{
    use default namespace Char;
    const EOS = 0;
    const a = "a".charCodeAt(0);
    const b = "b".charCodeAt(0);
    const c = "c".charCodeAt(0);
    const d = "d".charCodeAt(0);
    const e = "e".charCodeAt(0);
    const f = "f".charCodeAt(0);
    const g = "g".charCodeAt(0);
    const h = "h".charCodeAt(0);
    const i = "i".charCodeAt(0);
    const j = "j".charCodeAt(0);
    const k = "k".charCodeAt(0);
    const l = "l".charCodeAt(0);
    const m = "m".charCodeAt(0);
    const n = "n".charCodeAt(0);
    const o = "o".charCodeAt(0);
    const p = "p".charCodeAt(0);
    const q = "q".charCodeAt(0);
    const r = "r".charCodeAt(0);
    const s = "s".charCodeAt(0);
    const t = "t".charCodeAt(0);
    const u = "u".charCodeAt(0);
    const v = "v".charCodeAt(0);
    const w = "w".charCodeAt(0);
    const x = "x".charCodeAt(0);
    const y = "y".charCodeAt(0);
    const z = "z".charCodeAt(0);
    const A = "A".charCodeAt(0);
    const B = "B".charCodeAt(0);
    const C = "C".charCodeAt(0);
    const D = "D".charCodeAt(0);
    const E = "E".charCodeAt(0);
    const F = "F".charCodeAt(0);
    const G = "G".charCodeAt(0);
    const H = "H".charCodeAt(0);
    const I = "I".charCodeAt(0);
    const J = "J".charCodeAt(0);
    const K = "K".charCodeAt(0);
    const L = "L".charCodeAt(0);
    const M = "M".charCodeAt(0);
    const N = "N".charCodeAt(0);
    const O = "O".charCodeAt(0);
    const P = "P".charCodeAt(0);
    const Q = "Q".charCodeAt(0);
    const R = "R".charCodeAt(0);
    const S = "S".charCodeAt(0);
    const T = "T".charCodeAt(0);
    const U = "U".charCodeAt(0);
    const V = "V".charCodeAt(0);
    const W = "W".charCodeAt(0);
    const X = "X".charCodeAt(0);
    const Y = "Y".charCodeAt(0);
    const Z = "Z".charCodeAt(0);
    const Zero = "0".charCodeAt(0);
    const Period = ".".charCodeAt(0);
    const Bang = "!".charCodeAt(0);
    const Equal = "=".charCodeAt(0);
    const Percent = "%".charCodeAt(0);
    const Ampersand = "&".charCodeAt(0);
    const Asterisk = "*".charCodeAt(0);
    const Plus = "+".charCodeAt(0);
    const Dash = "-".charCodeAt(0);
    const Slash = "/".charCodeAt(0);
    const Comma = ",".charCodeAt(0);
    const Colon = ":".charCodeAt(0);
    const Semicolon = ";".charCodeAt(0);
    const LeftAngle = "<".charCodeAt(0);
    const RightAngle = ">".charCodeAt(0);
    const Caret = "^".charCodeAt(0);
    const Bar = "|".charCodeAt(0);
    const QuestionMark = "?".charCodeAt(0);
    const LeftParen = "(".charCodeAt(0);
    const RightParen = ")".charCodeAt(0);
    const LeftBrace = "{".charCodeAt(0);
    const RightBrace = "}".charCodeAt(0);
    const LeftBracket = "[".charCodeAt(0);
    const RightBracket = "]".charCodeAt(0);
    const Tilde = "~".charCodeAt(0);
    const At = "@".charCodeAt(0);
    const SingleQuote = "'".charCodeAt(0);
    const DoubleQuote = "\"".charCodeAt(0);
    const Space = " ".charCodeAt(0);
    const Newline = "\n".charCodeAt();
}

namespace Token

{
    use default namespace Token

    const firstTokenClass = -1
    const Minus = firstTokenClass
    const MinusMinus = Minus - 1
    const Not = MinusMinus - 1
    const NotEquals = Not - 1
    const StrictNotEquals = NotEquals - 1
    const Modulus = StrictNotEquals - 1
    const ModulusAssign = Modulus - 1
    const BitwiseAnd = ModulusAssign - 1
    const LogicalAnd = BitwiseAnd - 1
    const LogicalAndAssign = LogicalAnd - 1
    const BitwiseAndAssign = LogicalAndAssign - 1
    const LeftParen = BitwiseAndAssign - 1
    const RightParen = LeftParen - 1
    const Mult = RightParen - 1
    const MultAssign = Mult - 1
    const Comma = MultAssign  - 1
    const Dot = Comma - 1
    const DoubleDot = Dot - 1
    const TripleDot = DoubleDot - 1
    const LeftDotAngle = TripleDot - 1
    const Div = LeftDotAngle - 1
    const DivAssign = Div - 1
    const Colon = DivAssign - 1
    const DoubleColon = Colon - 1
    const SemiColon = DoubleColon - 1
    const QuestionMark = SemiColon - 1
    const At = QuestionMark - 1
    const LeftBracket = At - 1
    const RightBracket = LeftBracket - 1
    const BitwiseXor = RightBracket - 1
    const BitwiseXorAssign = BitwiseXor - 1
    const LeftBrace = BitwiseXorAssign - 1
    const BitwiseOr = LeftBrace - 1
    const LogicalOr = BitwiseOr - 1
    const LogicalOrAssign = LogicalOr - 1
    const BitwiseOrAssign = LogicalOrAssign - 1
    const RightBrace = BitwiseOrAssign - 1
    const BitwiseNot = RightBrace - 1
    const Plus = BitwiseNot - 1
    const PlusPlus = Plus - 1
    const PlusAssign = PlusPlus - 1
    const LessThan = PlusAssign - 1
    const LeftShift = LessThan - 1
    const LeftShiftAssign = LeftShift - 1
    const LessThanOrEquals = LeftShiftAssign - 1
    const Assign = LessThanOrEquals - 1
    const MinusAssign = Assign - 1
    const Equals = MinusAssign - 1
    const StrictEquals = Equals - 1
    const GreaterThan = StrictEquals - 1
    const GreaterThanOrEquals = GreaterThan - 1
    const RightShift = GreaterThanOrEquals - 1
    const RightShiftAssign = RightShift - 1
    const UnsignedRightShift = RightShiftAssign - 1
    const UnsignedRightShiftAssign = UnsignedRightShift - 1

    /* reserved identifiers */

    const Break = UnsignedRightShiftAssign - 1
    const Case = Break - 1
    const Catch = Case - 1
    const Class = Catch - 1
    const Continue = Class - 1
    const Default = Continue - 1
    const Delete = Default - 1
    const Do = Delete - 1
    const Else = Do - 1
    const Enum = Else - 1
    const Extends = Enum - 1
    const False = Extends - 1
    const Finally = False - 1
    const For = Finally - 1
    const Function = For - 1
    const If = Function - 1
    const In = If - 1
    const InstanceOf = In - 1
    const New = InstanceOf - 1
    const Null = New - 1
    const Return = Null - 1
    const Super = Return - 1
    const Switch = Super - 1
    const This = Switch - 1
    const Throw = This - 1
    const True = Throw - 1
    const Try = True - 1
    const TypeOf = Try - 1
    const Var = TypeOf - 1
    const Void = Var - 1
    const While = Void - 1
    const With = While - 1

    /* contextually reserved identifiers */

    const Call = With - 1
    const Cast = Call - 1
    const Const = Cast - 1
    const Decimal = Const - 1
    const Double = Decimal - 1
    const Dynamic = Double - 1
    const Each = Dynamic - 1
    const Final = Each - 1
    const Get = Final - 1
    const Has = Get - 1
    const Implements = Has - 1
    const Import = Implements - 1
    const Int = Import - 1
    const Interface = Int - 1
    const Internal = Interface - 1
    const Intrinsic = Internal - 1
    const Is = Intrinsic - 1
    const Let = Is - 1
    const Namespace = Let - 1
    const Native = Namespace - 1
    const Number = Native - 1
    const Override = Number - 1
    const Package = Override - 1
    const Precision = Package - 1
    const Private = Precision - 1
    const Protected = Private - 1
    const Prototype = Protected - 1
    const Public = Prototype - 1
    const Rounding = Public - 1
    const Standard = Rounding - 1
    const Strict = Standard - 1
    const To = Strict - 1
    const Set = To - 1
    const Static = Set - 1
    const Type = Static - 1
    const UInt = Type - 1
    const Undefined = UInt - 1
    const Use = Undefined - 1
    const Xml = Use - 1
    const Yield = Xml - 1

    /* literals */

    const AttributeIdentifier = Yield - 1
    const BlockComment = AttributeIdentifier - 1
    const DocComment = BlockComment - 1
    const Eol = DocComment - 1
    const Identifier = Eol - 1

    // The interpretation of these 4 literal types can be done during lexing

    const ExplicitDecimalLiteral = Identifier - 1
    const ExplicitDoubleLiteral = ExplicitDecimalLiteral - 1
    const ExplicitIntLiteral = ExplicitDoubleLiteral - 1
    const ExplicitUIntLiteral = ExplicitIntLiteral - 1

    // The interpretation of these 3 literal types is deferred until defn phase

    const DecimalIntegerLiteral = ExplicitUIntLiteral - 1
    const DecimalLiteral = DecimalIntegerLiteral - 1
    const HexIntegerLiteral = DecimalLiteral - 1

    const RegexpLiteral = HexIntegerLiteral - 1
    const SlashSlashComment = RegexpLiteral - 1
    const StringLiteral = SlashSlashComment - 1
    const Space = StringLiteral - 1
    const XmlLiteral = Space - 1
    const XmlPart = XmlLiteral - 1
    const XmlMarkup = XmlPart - 1
    const XmlText = XmlMarkup - 1
    const XmlTagEndEnd = XmlText - 1
    const XmlTagStartEnd = XmlTagEndEnd - 1

    // meta

    const ERROR = XmlTagStartEnd - 1
    const EOS = ERROR - 1
    const BREAK = EOS - 1 
    const lastTokenClass = BREAK

    const names = [
        "<unused index>", 
        "minus",
        "minusminus",
        "not",
        "notequals",
        "strictnotequals",
        "modulus",
        "modulusassign",
        "bitwiseand",
        "logicaland",
        "logicalandassign",
        "bitwiseandassign",
        "leftparen",
        "rightparen",
        "mult",
        "multassign",
        "comma",
        "dot",
        "doubledot",
        "tripledot",
        "leftdotangle",
        "div",
        "divassign",
        "colon",
        "doublecolon",
        "semicolon",
        "questionmark",
        "at",
        "leftbracket",
        "rightbracket",
        "bitwisexor",
        "bitwisexorassign",
        "leftbrace",
        "bitwiseor",
        "logicalor",
        "logicalorassign",
        "bitwiseorassign",
        "rightbrace",
        "bitwisenot",
        "plus",
        "plusplus",
        "plusassign",
        "lessthan",
        "leftshift",
        "leftshiftassign",
        "lessthanorequals",
        "assign",
        "minusassign",
        "equals",
        "strictequals",
        "greaterthan",
        "greaterthanorequals",
        "rightshift",
        "rightshiftassign",
        "unsignedrightshift",
        "unsignedrightshiftassign",
        "break",
        "case",
        "catch",
        "class",
        "continue",
        "default",
        "delete",
        "do",
        "else",
        "enum",
        "extends",
        "false",
        "finally",
        "for",
        "function",
        "if",
        "in",
        "instanceof",
        "new",
        "null",
        "return",
        "super",
        "switch",
        "this",
        "throw",
        "true",
        "try",
        "typeof",
        "var",
        "void",
        "while",
        "with",

        "call",
        "cast",
        "const",
        "decimal",
        "double",
        "dynamic",
        "each",
        "final",
        "get",
        "has",
        "implements",
        "import",
        "int",
        "interface",
        "internal",
        "intrinsic",
        "is",
        "let",
        "namespace",
        "native",
        "Number",
        "override",
        "package",
        "precision",
        "private",
        "protected",
        "prototype",
        "public",
        "rounding",
        "standard",
        "strict",
        "to",
        "set",
        "static",
        "type",
        "uint",
        "undefined",
        "use",
        "xml",
        "yield",

        "attributeidentifier",
        "blockcomment",
        "doccomment",
        "eol",
        "identifier",
        "explicitdecimalliteral",
        "explicitdoubleliteral",
        "explicitintliteral",
        "explicituintliteral",
        "decimalintegerliteral",
        "decimalliteral",
        "hexintegerliteral",
        "regexpliteral",
        "linecomment",
        "stringliteral",
        "space",
        "xmlliteral",
        "xmlpart",
        "xmlmarkup",
        "xmltext",
        "xmltagendend",
        "xmltagstartend",

        "ERROR",
        "EOS",
        "BREAK"
    ]
    
    class Token 
    {
        var kind
        var utf8id
        function Token(kind,utf8id)
        {
            this.kind = kind
            this.utf8id = utf8id
        }

        function tokenText () : String
        {
            return this.utf8id;
        }
    }

    const tokenStore = new Array;

    function maybeReservedIdentifier (lexeme:String) : int
    {
        // ("maybeReservedIdentifier lexeme=",lexeme);
        switch (lexeme) {

        // ContextuallyReservedIdentifiers

        case "break": return Break;
        case "case": return Case;
        case "catch": return Catch;
        case "class": return Class;
        case "continue": return Continue;
        case "default": return Default;
        case "delete": return Delete;
        case "do": return Do;
        case "else": return Else;
        case "enum": return Enum;
        case "extends": return Extends;
        case "false": return False;
        case "finally": return Finally;
        case "for": return For;
        case "function": return Function;
        case "if": return If;
        case "in": return In;
        case "instanceof": return InstanceOf;
        case "new": return New;
        case "null": return Null;
        case "return": return Return;
        case "super": return Super;
        case "switch": return Switch;
        case "this": return This;
        case "throw": return Throw;
        case "true": return True;
        case "try": return Try;
        case "typeof": return TypeOf;
        case "var": return Var;
        case "void": return Void;
        case "while": return While;
        case "with": return With;

        // ContextuallyReservedIdentifiers

        case "call": return Call;
        case "cast": return Cast;
        case "const": return Const;
        case "decimal": return Decimal;
        case "double": return Double;
        case "dynamic": return Dynamic;
        case "each": return Each;
        case "eval": return Eval;
        case "final": return Final;
        case "get": return Get;
        case "has": return Has;
        case "implements": return Implements;
        case "import": return Import;
        case "int": return Int;
        case "interface" : return Interface;
        case "internal": return Internal;
        case "intrinsic": return Intrinsic;
        case "is": return Is;
        case "let": return Let;
        case "namespace": return Namespace;
        case "native": return Native;
        case "Number": return Number;
        case "override": return Override;
        case "package": return Package;
        case "precision": return Precision;
        case "private": return Private;
        case "protected": return Protected;
        case "prototype": return Prototype;
        case "public": return Public;
        case "rounding": return Rounding;
        case "standard": return Standard;
        case "strict": return Strict;
        case "to": return To;
        case "set": return Set;
        case "static": return Static;
        case "to": return To;
        case "type": return Type;
        case "uint": return Uint;
        case "undefined": return Undefined;
        case "use": return Use;
        case "xml": return Xml;
        case "yield": return Yield;
        default: return makeInstance (Identifier,lexeme);
        }            
    }

    function makeInstance(token_class:int, lexeme:String) : int
    {
        tokenStore.push(new Token(token_class, lexeme));
        return tokenStore.length - 1;
    }

    function getTokenClass (tid : int) : int
    {
        // if the token id is negative, it is a token_class

        if (tid < 0)
        {
           return tid;
        }

        // otherwise, get instance data from the instance vector.

        var t : Token = tokens[tid];
        return t.getTokenClass();
    }
    
    function tokenText ( tid : int ) : String
    {
        if (tid < 0) {
            // if the token id is negative, it is a token_class.
            var text = names[-tid];
        }
        else {
            // otherwise, get instance data from the instance vector
            var tok : Token = tokenStore[tid];
            var text = tok.tokenText();
        }
        return text;
    }

    function test () 
    {
        for( let i = firstTokenClass; i >= lastTokenClass; --i )
            print(i,": ",names[-i])
    }

}

Token::test()

namespace Lexer

{
    use default namespace Lexer;

    class Scanner 
    {
        private var tokenList : Array;
        private var followsNewline : Boolean;

        private var src : String;
        private var origin : String;
        private var curIndex : int;
        private var markIndex : int;

        public function Scanner (src:String, origin:String)
            : src = src
            , origin = origin
            , tokenList = new Array
            , curIndex = 0
            , markIndex = 0
        {
            print("scanning: ",src);
        }

        public function next () 
            : String
        {
            if (curIndex == src.length)
            {
                curIndex++;
                return Char::EOS;
            }
            else
            {
                return src.charCodeAt(curIndex++);
            }
        }
	
        public function lexeme() 
            : String 
        {
            return src.slice (markIndex,curIndex)
        }

        public function retract() 
            : void
        {
            curIndex--;
            print("retract cur=",curIndex);
        }

        private function mark () 
            : void
        {
            markIndex = curIndex;
            print("mark mark=",markIndex);
        }

        public function tokenList (lexPrefix)
            : int
        {
            let tokenList = new Array;
            let token = lexPrefix ();
            tokenList.push (token);
            while (token != Token::BREAK &&
                   token != Token::EOS &&
                   token != Token::ERROR) 
            {
                token = start ();
                tokenList.push (token);
            }
            return tokenList.reverse();
        }

        public function div () : int
        {
            let c : int = next ();
            switch (c) 
            {
                case Char::Equal : return Token::DivAssign;
                default:
                    retract ();
                    return Token::Div;
            }
        }

        public function regexp ()
        {
            let c : int = next ();
            switch (c)
            {
                case Char::Slash :
                    return regexpFlags ();
                default:
                    return regexp ();
            }
        }

        public function regexpFlags ()
        {
            let c : int = next ();
            if (Unicode.isIdentifierPart (String.fromCharCode(c))) {
                return regexpFlags ();
            }
            else {
                retract ();
                return Token::makeInstance (Token::RegexpLiteral,lexeme());
            }
        }

        public function start ()
            : int
        {
            var c : int;
            while (true)
            {
                mark();
                c = next();
                //                print("c[",curIndex-1,"]=",String.fromCharCode(c));
                switch (c)
                {
                case 0xffffffef: return utf8sig ();
                case Char::EOS: print("EOS"); return Token::EOS;
                case Char::Slash: return Token::BREAK;
                case Char::Newline: return Token::Newline;
                case Char::Space: return Token::Space;
                case Char::LeftParen: return Token::LeftParen;
                case Char::RightParen: return Token::RightParen;
                case Char::Comma: return Token::Comma;
                case Char::Semicolon: return Token::Semicolon;
                case Char::QuestionMark: return Token::QuestionMark;
                case Char::LeftBracket: return Token::LeftBracket;
                case Char::RightBracket: return Token::RightBracket;
                case Char::LeftBrace: return Token::LeftBrace;
                case Char::RightBrace: return Token::RightBrace;
                case Char::Tilde: return Token::BitwiseNot;
                case Char::At: return Token::At;
                case Char::SingleQuote: return stringLiteral (c);
                case Char::DoubleQuote: return stringLiteral (c);
                case Char::Dash: return minus ();
                case Char::Bang: return not ();
                case Char::Percent: return remainder ();
                case Char::Ampersand: return and ();
                case Char::Asterisk: return mult ();
                case Char::Colon: return colon ();
                case Char::Caret: return caret ();
                case Char::Bar: return or ();
                case Char::Plus: return plus ();
                case Char::LeftAngle: return lessthan ();
                case Char::Equal: return equal ();
                case Char::RightAngle: return greaterthan ();
                case Char::Zero: return zero ();
                case Char::b: return b_ ();
                case Char::c: return c_ ();
                case Char::d: return d_ ();
                case Char::e: return e_ ();
                case Char::f: return f_ ();
                case Char::g: return g_ ();
                case Char::i: return i_ ();
                case Char::n: return n_ ();
                case Char::o: return o_ ();
                case Char::p: return p_ ();
                case Char::r: return r_ ();
                case Char::s: return s_ ();
                case Char::t: return t_ ();
                case Char::u: return u_ ();
                case Char::v: return v_ ();
                case Char::w: return w_ ();
                default:
                    /*
                    if (Unicode.isDecimalDigit (c)) 
                    {
                        return digit (c);
                    } 
                    else
                    */ 
                    if (Unicode.isIdentifierStart (String.fromCharCode(c)))
                    {
                        return identifier ();
                    } 
                    else
                    {
                        return intrinsic::print("invalid prefix ", c);
                    }
                }
            }
            Debug.assert(false);
		}

        private function identifier () 
            : int 
        {
            let c : int = next ();
            //            print("c[",curIndex-1,"]=",String.fromCharCode(c))
            switch (c) 
            {
            case Char::a : 
            case Char::b :
            case Char::c : 
            case Char::d : 
            case Char::e : 
            case Char::f : 
            case Char::g : 
            case Char::h : 
            case Char::i : 
            case Char::j : 
            case Char::k : 
            case Char::l : 
            case Char::m : 
            case Char::n : 
            case Char::o : 
            case Char::p : 
            case Char::q : 
            case Char::r : 
            case Char::s : 
            case Char::t : 
            case Char::u : 
            case Char::v : 
            case Char::w : 
            case Char::x : 
            case Char::y : 
            case Char::z : 
            case Char::A : 
            case Char::B :
            case Char::B :
            case Char::C :
            case Char::D :
            case Char::E :
            case Char::F :
            case Char::G :
            case Char::H :
            case Char::I :
            case Char::J :
            case Char::K :
            case Char::L :
            case Char::M :
            case Char::N :
            case Char::O :
            case Char::P :
            case Char::Q :
            case Char::R :
            case Char::S :
            case Char::T :
            case Char::U :
            case Char::V :
            case Char::W :
            case Char::X :
            case Char::Y :
            case Char::Z : return identifier ();
            default:
                if (Unicode.isIdentifierPart (String.fromCharCode(c)) && c != Char::EOS)
                {
                    return identifier ();
                }
                else
                {
                    retract ();                    
                    return Token::maybeReservedIdentifier (lexeme ());
                }
            }
        }

        private function b_ () : int 
        {
            let c : int = next ();
            switch (c) 
            {
                case Char::r : return br_ ();
                default:
                    retract ();
                    return identifier ();
            }
        }

        private function br_ () 
            : int 
        {
            let c : int = next ();
            switch (c) 
            {
                case Char::e : return identifier ();
                default:
                    retract ();
                    return identifier ();
            }
        }

        private function d_ () 
            : int 
        {
            let c : int = next ();
            switch (c) 
            {
                case Char::e : return identifier ();
                default:
                    retract ();
                    return identifier ();
            }
        }

        private function n_ () 
            : int 
        {
            let c : int = next();
            switch (c) 
            {
                case Char::a : return na_ ();
                case Char::e : return ne_ ();
                case Char::u : return nu_ ();
                default:
                    retract ();
                    return identifier ();
            }
        }

        private function nu_ ()
            : int
        {
            let c : int = next ();
            switch (c) {
            case Char::l : return nul_ ();
            default:
                retract ();
                return identifier ();
            }
        }

        private function nul_ ()
            : int
        {
            let c : int = next ();
            switch (c) {
            case Char::l : return null_ ();
            default:
                retract ();
                return identifier ();
            }
        }

        private function null_ () 
            : int 
        {
            let c : int = next ();
            if (Unicode.isIdentifierPart (String.fromCharCode(c)))
            {
                return identifier ();
            }
            else
            {
                retract();
                return Token::Null;
            }
        }
    }

    function test() 
    {
        var scan = new Scanner ("/abc/ null break /def/xyz","test");
        var list = scan.tokenList (scan.start);
        let tk = Token::EOS;
        do {
            print("tokenList.length=",list.length);
            while (list.length > 0) {
                tk=list.pop();
                print(" ",Token::tokenText(tk));
                if (tk == Token::BREAK) {
                    list = scan.tokenList (scan.regexp);
                    print("tokenList.length=",list.length);
                }
            }
        } while (tk != Token::EOS);
        print ("scanned!");
    }

    test ();
}