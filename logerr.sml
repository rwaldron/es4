(*
 * The following licensing terms and conditions apply and must be
 * accepted in order to use the Reference Implementation:
 *
 *    1. This Reference Implementation is made available to all
 * interested persons on the same terms as Ecma makes available its
 * standards and technical reports, as set forth at
 * http://www.ecma-international.org/publications/.
 *
 *    2. All liability and responsibility for any use of this Reference
 * Implementation rests with the user, and not with any of the parties
 * who contribute to, or who own or hold any copyright in, this Reference
 * Implementation.
 *
 *    3. THIS REFERENCE IMPLEMENTATION IS PROVIDED BY THE COPYRIGHT
 * HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * End of Terms and Conditions
 *
 * Copyright (c) 2007 Adobe Systems Inc., The Mozilla Foundation, Opera
 * Software ASA, and others.
 *)

structure LogErr = struct

fun locToString {file, span, post_newline} =
    let
        val ({line=line1, col=col1}, {line=line2, col=col2}) = span
    in
        file ^ ":" ^
        (Int.toString line1) ^ ":" ^ (Int.toString col1) ^ "-" ^
        (Int.toString line2) ^ "." ^ (Int.toString col2)
    end

val (loc:(Ast.LOC option) ref) = ref NONE
fun setLoc (p:Ast.LOC option) = loc := p

val doNamespaces = ref true

val (lastReported:(Ast.LOC option) ref) = ref NONE

fun log ss =
    let
        val loc_changed = not (!lastReported = !loc)
    in
        if loc_changed
        then
            ((case !loc of
              NONE => ()
            | SOME l => TextIO.print ("[locn] " ^ (locToString l) ^ "\n"));
            lastReported := (!loc))
        else ();
        List.app TextIO.print ss;
        TextIO.print "\n"
    end

fun locstr ss =
    case !loc of
	NONE => String.concat ss
      | SOME l => String.concat (ss @ [" (near ", (locToString l), ")"])

fun join sep ss =
    case ss of
        [] => ""
      | [x] => x
      | x :: xs => x ^ sep ^ (join sep xs)

fun error ss = case !loc of
		   NONE => log ("**ERROR** (unknown location)" :: ss)
		 | SOME l => log ("**ERROR** (near " :: (locToString l) :: ") " :: ss)

fun namespace (ns:Ast.NAMESPACE) =
	let
		val specialNames = [
			 (Name.ES4NS, "__ES4__"),
			 (Name.publicNS, "public"),
			 (Name.metaNS, "meta"),
			 (Name.magicNS, "magic"),
			 (Name.intrinsicNS, "intrinsic"),
			 (Name.informativeNS, "informative"),
			 (Name.ECMAScript4_InternalNS, "ECMAScript4_Internal"),
			 (Name.helperNS, "helper"),
			 (Name.UnicodeNS, "Unicode"),
			 (Name.RegExpInternalsNS, "RegExpInternals")
		]
		fun specialName n = 
			case List.find (fn (a,_) => a = n) specialNames of
				NONE => ""
			  | SOME (_, s) => "=" ^ s
	in
		case ns of
			Ast.OpaqueNamespace i => "<ns #" ^ (Int.toString i) ^ (specialName ns) ^ ">"
		  | Ast.TransparentNamespace s => "<ns '" ^ (Ustring.toAscii s) ^"'>"
	end
									 
fun fullName ({ns,id}:Ast.NAME) = (namespace ns) ^ "::" ^ (Ustring.toAscii id) ^ " "

fun name ({ns,id}:Ast.NAME) = if !doNamespaces
			      then fullName {ns=ns,id=id}
			      else (Ustring.toAscii id)

fun fname (n:Ast.FIXTURE_NAME) =
    case n of
	Ast.TempName n => "<temp " ^ (Int.toString n) ^ ">"
      | Ast.PropName n => name n

fun fixtureMap (r:Ast.FIXTURE_MAP) = 
    "[fixtureMap: " ^ (join ", " (map (fn (n,f) => fname n) 
			       (List.take(r,(Int.min(length r,10))))))
    ^ (if length r >10 then ", ...]" else "]")

fun fixtureMaps (rs:Ast.FIXTURE_MAPS) = 
    "[fixtureMaps: \n    " ^ (join ",\n    " (map fixtureMap rs)) ^ "\n]"

fun fmtNss (nss:Ast.NAMESPACE_SET) = 
   "(" ^ (join ", " (map namespace nss)) ^ ")"

fun fmtNsss (onss:Ast.OPEN_NAMESPACES) = 
   "{" ^ (join ", " (map fmtNss onss)) ^ "}"

fun nsExpr (nse:Ast.NAMESPACE_EXPRESSION) = 
	case nse of 
		Ast.Namespace ns => namespace ns
	  | Ast.NamespaceName ne => nameExpr ne

and nameExpr (ne:Ast.NAME_EXPRESSION) =
   let
	   fun unqualName (onss:Ast.OPEN_NAMESPACES)
					  (identifier:Ast.IDENTIFIER) =
		   let
		   in
			   if !doNamespaces
			   then (fmtNsss onss) ^ "::" ^ (Ustring.toAscii identifier)
			   else "[...]::" ^ (Ustring.toAscii identifier)
		   end		   
   in 
       case ne of
		   Ast.UnqualifiedName { identifier, openNamespaces, ... } => 
		   unqualName openNamespaces identifier
		 | Ast.QualifiedName { namespace, identifier } => 
		   ((nsExpr namespace) ^ "::" ^ (Ustring.toAscii identifier))
   end
   
fun identList fields =
    join ", " (map Ustring.toAscii fields)

fun ty t =
    let
        fun typeList tys =
            join ", " (map ty tys)
        fun typeOrList tys =
            join "|" (map ty tys)
        fun fieldToString (name, fieldType) = 
			(nameExpr name) ^ ": " ^ (ty fieldType)
        fun fieldList fields =
            join ", " (map fieldToString fields)
        
    in
        case t of
            Ast.AnyType => "*"
          | Ast.NullType => "null"
          | Ast.UndefinedType => "undefined"
          | Ast.UnionType tys => "(" ^ (typeOrList tys) ^ ")"
          | Ast.ArrayType (tys,NONE) => "[" ^ (typeList tys) ^ "]"
          | Ast.ArrayType (tys,SOME t) => "[" ^ (typeList tys) ^ "..." ^ (ty t) ^"]"
          | Ast.TypeName (name, _) => "TypeName("^(nameExpr name)^")"
		  | Ast.TypeIndexReferenceType (t,i) 
			=> "<TypeIndexReferenceType: "^(ty t)^"."^(Int.toString i)^">"
          | Ast.TypeNameReferenceType (t,n)
			=> "<TypeNameReferenceType: ...>"
          | Ast.FunctionType {params, result, hasRest, ...} => 
			"function (" 
			^ (typeList params) 
			^ (if hasRest 
			   then (if List.length params = 0 
					 then "..." 
					 else ", ...") 
			   else "")
			^ ") : " 
			^ (case result of
			       NONE => "void"
			     | SOME t => ty t)
			
          | Ast.RecordType fields => 
			"{" ^ fieldList fields ^ "}"
          | Ast.AppType (base, args) => 
			(ty base) ^ ".<" ^ (typeList args) ^ ">"
          | Ast.NonNullType t => (ty t) ^ "!"
          | Ast.ClassType (Ast.Class { name=n, ... }) => 
	        "ClassType("^(name n)^")"
          | Ast.InstanceType (Ast.Class { name=n, ... }) => 
	        "InstanceType("^(name n)^")"
          | Ast.InterfaceType (Ast.Interface { name=n, ... }) => 
			"InterfaceType("^(name n)^")"
    end

exception LexError of string
exception ParseError of string
exception NameError of string
exception DefnError of string
exception FixtureError of string
exception AstError of string
exception TypeError of string
exception VerifyError of string
exception EvalError of string
exception MachError of string
exception HostError of string
exception UnimplError of string
exception EofError

fun lexError ss =
     raise LexError (locstr ss)

fun parseError ss =
     raise ParseError (locstr ss)

fun nameError ss =
     raise NameError (locstr ss)

fun defnError ss =
     raise DefnError (locstr ss)

fun fixtureError ss =
     raise FixtureError (locstr ss)

fun typeError ss =
     raise TypeError (locstr ss)

fun verifyError ss =
     raise VerifyError (locstr ss)

fun evalError ss =
     raise EvalError (locstr ss)

fun machError ss =
     raise MachError (locstr ss)

fun astError ss =
     raise AstError (locstr ss)

fun hostError ss =
     raise HostError (locstr ss)

fun unimplError ss =
     raise UnimplError (locstr ss)

fun internalError ss =
     raise UnimplError (locstr ss)

end
