(* -*- mode: sml; mode: font-lock; tab-width: 4; insert-tabs-mode: nil; indent-tabs-mode: nil -*- *)
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
structure Verify = struct

open LogErr

type RIB = Ast.FIXTURES

(* ENV contains all type checking context, including ribs (variable-type bindings),
 * strict vs standard mode, and the expected return type, if any.
 *)

type ENV = { returnType: Ast.TYPE_EXPR option,
             strict: bool,
             ribs: RIB list }

fun withReturnType { returnType=_, strict, ribs } returnType =
    { returnType=returnType, strict=strict, ribs=ribs }

fun withRibs { returnType, strict, ribs=_ } ribs =
    { returnType=returnType, strict=strict, ribs=ribs }

fun withStrict { returnType, strict=_, ribs } strict =
    { returnType=returnType, strict=strict, ribs=ribs }

fun withRib { returnType, strict, ribs} extn =
    { returnType=returnType, strict=strict, ribs=extn :: ribs }

structure NmKey = struct type ord_key = Ast.NAME val compare = NameKey.compare end
structure NmMap = SplayMapFn (NmKey);

structure NmVecKey = struct type ord_key = (Ast.NAME vector) val compare = (Vector.collate NameKey.compare) end
structure NmVecMap = SplayMapFn (NmVecKey);

val (fixtureCache:(Ast.FIXTURE NmMap.map) ref) = ref NmMap.empty
val (instanceOfCache:(bool NmVecMap.map) ref) = ref NmVecMap.empty
val cachesz = 1024

(* Local tracing machinery *)

val doTrace = ref false
val doTraceProg = ref false
fun trace ss = if (!doTrace) then LogErr.log ("[verify] " :: ss) else ()
fun error ss = LogErr.verifyError ss

fun logType ty = (Pretty.ppType ty; TextIO.print "\n")
fun traceType ty = if (!doTrace) then logType ty else ()

(*
fun typeToString ty = ...
*)

fun fmtName n = if !doTrace
                then LogErr.name n
                else ""

fun fmtType ty = if !doTrace
                 then Type.toString ty
                 else ""

(* Mapping the rib structure to multiname lookup. *)
fun parentRib [] = NONE
  | parentRib (x::[]) = NONE
  | parentRib (x::xs) = SOME xs

fun resolve (ribs:RIB list) (mname:Ast.MULTINAME) =
    case ribs of
        [] => NONE
      | _ => Multiname.resolveInFixtures mname ribs List.hd parentRib

fun findFixture (ribs:RIB list) (mname:Ast.MULTINAME) =
    case resolve ribs mname of
        NONE => error ["unable to resolve fixture for multiname: ", LogErr.multiname mname]
      | SOME (fixs, n) => Fixture.getFixture fixs (Ast.PropName n)

fun resolveExprToNamespace (env:ENV)
                           (expr:Ast.EXPR)
    : Ast.NAMESPACE =
    case expr of
        Ast.LiteralExpr (Ast.LiteralNamespace ns) => ns
      | Ast.LexicalRef {ident = Ast.Identifier {ident, openNamespaces}, loc } =>
        (case findFixture (#ribs env) {nss = openNamespaces, id = ident} of
             Ast.NamespaceFixture ns => ns
           | _ => error ["namespace expression resolved ",
                         "to non-namespace fixture"])
      | _ => error ["unexpected expression type ",
                    "in namespace context"]


(****************************** standard types *************************)

fun instanceTypeExpr (n:Ast.NAME) : Ast.TYPE_EXPR =
    Ast.InstanceType (Fixture.instanceType (!Defn.topFixtures) n)

val undefinedType   = Ast.SpecialType Ast.Undefined
val nullType        = Ast.SpecialType Ast.Null
val anyType         = Ast.SpecialType Ast.Any

(****************************** misc auxiliary functions *************************)

fun assert b s = if b then () else (raise Fail s)

fun checkForDuplicates [] = ()
  | checkForDuplicates (x::xs) =
    if List.exists (fn y => x = y) xs
    then error ["concurrent definition"]
    else checkForDuplicates xs

fun unOptionDefault NONE def = def
  | unOptionDefault (SOME v) _ = v

fun flattenOptionList NONE = []
  | flattenOptionList (SOME l) = l

val gensymCounter : int ref = ref 0
fun gensym (s:Ustring.STRING) : Ustring.STRING =
    let
    in
	    gensymCounter := 1+(!gensymCounter);
	    Ustring.append [s, Ustring.dollar, Ustring.fromInt (!gensymCounter)]
    end

(************************* Substitution on Types *********************************)

(* TODO: normalized types?? *)

fun substTypeExpr (s:(Ast.IDENT*Type.TYPE_VALUE) list)
                  (t:Type.TYPE_VALUE)
    : Ast.TYPE_EXPR =
    let in
	case t of
	    Ast.UnionType ts =>
	    Ast.UnionType (map (substTypeExpr s) ts)
	  | Ast.ArrayType ts =>
	    Ast.ArrayType (map (substTypeExpr s) ts)
	  | Ast.AppType {base, args} =>
	    Ast.AppType {base=substTypeExpr s base, args=map (substTypeExpr s) args}
	  | Ast.NullableType {expr, nullable}
	    => Ast.NullableType {expr=substTypeExpr s expr, nullable=nullable}

	  | Ast.TypeName ((Ast.Identifier {ident=ident, openNamespaces=_})) =>
	    let in
		case List.find
			 (fn (id,ty) => id=ident)
			 s
		 of
		    (* TODO: we're dropping the nullable here, is that right? *)
		    SOME (_,ty) => ty
		  | NONE => t
	    end
	  | Ast.ObjectType fields =>
	    Ast.ObjectType (map (fn {name,ty} =>
				{name=name,ty=substTypeExpr s ty})
			fields)
	  | Ast.SpecialType st => Ast.SpecialType st

	  | Ast.FunctionType { typeParams, params, result, thisType, hasRest, minArgs } =>
	    (* Need to uniquify typeParams to avoid capture *)
	    let val oldNew = map (fn id => (id, gensym id)) typeParams
		    val nuSub =
		        map
			        (fn (oldId,newId) =>
			            (oldId,
			             Ast.TypeName (Ast.Identifier {ident=newId,openNamespaces=[]})))
			        oldNew
		    val bothSubs = fn t => substTypeExpr s (substTypeExpr nuSub t)
		    val nuTypeParams = map (fn (oldId,newId) => newId) oldNew
		(* val nuParams = map (fn t => substVarBinding s (substVarBinding nuSub t)) params *)
		in
		    Ast.FunctionType {typeParams=nuTypeParams,
			                  params = List.map bothSubs params,
			                  result = bothSubs result,
			                  thisType = Option.map bothSubs thisType,
			                  hasRest=hasRest, minArgs = minArgs }
		end
    end

(************************* Handling Types *********************************)

fun verifyTypeExpr (env:ENV)
                   (ty:Ast.TYPE_EXPR)
    : Type.TYPE_VALUE =
    let in
        trace ["verifyTypeExpr: ", fmtType ty];

	    case ty of
            (*
Ast.TypeName
*)
	        Ast.SpecialType _ =>
            ty
	      | Ast.UnionType tys =>
            Ast.UnionType (verifyTypeExprs env tys)
	      | Ast.ArrayType tys =>
            Ast.ArrayType (verifyTypeExprs env tys)
	      | Ast.NullableType {expr=ty,nullable} =>
            Ast.NullableType {expr=verifyTypeExpr env ty, nullable=nullable}
	      | Ast.AppType {base,args} =>
	        let val base' = verifyTypeExpr env base
                val args' = verifyTypeExprs env args
            in case base' of
                   Ast.FunctionType {typeParams,params,result,thisType,hasRest,minArgs} =>
                   let val _ =	assert (length args = length typeParams);
		               val sub = ListPair.zip (typeParams,args)
		               fun applySub t = substTypeExpr sub t
                       val result =
		                   Ast.FunctionType { typeParams=[],
			                                  params=map (substTypeExpr sub) params,
			                                  result=substTypeExpr sub result,
			                                  thisType= Option.map (substTypeExpr sub) thisType,
			                                  hasRest=hasRest, minArgs=minArgs }
                   in
                       verifyTypeExpr env result
                   end
                 | _ => Ast.AppType {base=base', args=args'}
	        end
	      | Ast.FunctionType {typeParams, params, result, thisType, hasRest, minArgs} =>
	        let
	            (* Add the type parameters to the environment. *)
	            val env' : ENV =
                    withRib env (List.map
                                     (fn id => (Ast.PropName (Name.nons id),
                                                Ast.TypeVarFixture))
                                     typeParams)
                val params' = verifyTypeExprs env' params
                val result' = verifyTypeExpr env' result
                val thisType' = Option.map (verifyTypeExpr env') thisType
            in
                Ast.FunctionType { typeParams=typeParams, params=params', result=result',
                                   thisType=thisType', hasRest=hasRest, minArgs=minArgs }
            end
	      | Ast.ObjectType fields =>
	        let val fields' =
		            map (fn {name,ty} => {name=name, ty=verifyTypeExpr env ty})
			            fields
                val names = map (fn {name,ty} => name) fields
                val _ = checkForDuplicates names
            in
                Ast.ObjectType fields'
	        end

          | Ast.TypeName ie =>
            let
                fun findType id nss =
                    let
                        fun tryRibs ribs =
                            case findFixture ribs {nss=nss, id=id} of
                                (* FIXME: re-resolve result ... in which environment? *)
                                Ast.TypeFixture ty => ty
                              | Ast.ClassFixture (Ast.Cls cls) => Ast.InstanceType (#instanceType cls)
                              | Ast.InterfaceFixture (Ast.Iface iface) => Ast.InstanceType (#instanceType iface)
                              | _ => error ["multiname ", LogErr.multiname {nss=nss, id=id},
                                                      " resolved to non-type fixture"]

(*
                              | _ => case ribs of
                                         (r :: rs) => tryRibs rs
                                       | [] => error ["multiname ", LogErr.multiname {nss=nss, id=id},
                                                      " resolved to non-type fixture"]
*)
                    in
                        tryRibs (#ribs env)
                    end

                val resolved = case ie of
                                   Ast.Identifier { ident, openNamespaces } => findType ident openNamespaces
                                 | Ast.QualifiedIdentifier { qual, ident } => findType ident [[resolveExprToNamespace env qual]]
                                 | Ast.WildcardIdentifier => Ast.SpecialType Ast.Any
                                 | _ => error ["unexpected identifier form in type name" ]
            in
                (*
                 * FIXME: this is a bug: we should re-resolve in the environment the type definition was found in,
                 * not our own environment. Since type definitions are only about lexical scope though, we should
                 * be in an extension of the defining environment, so unless there are shadowing relations we
                 * should get a tolerable approximation of correct
                 * behavior here. Fix later.
                 *)
                verifyTypeExpr env resolved
            end

          | Ast.ElementTypeRef ((Ast.ArrayType fields), idx) =>
            let
                val t = if idx < length fields
                        then List.nth (fields, idx)
                        else
                            if length fields > 0
                            then List.last fields
                            else Ast.SpecialType Ast.Any
            in
                verifyTypeExpr env t
            end

          | Ast.ElementTypeRef (Ast.SpecialType Ast.Any, _) =>
            Ast.SpecialType Ast.Any

          | Ast.ElementTypeRef (Ast.ElementTypeRef _, _) =>
            Ast.SpecialType Ast.Any    (* FIXME may be able to get a more specific type *)

          | Ast.ElementTypeRef (t, _) =>
            error ["ElementTypeRef on non-ArrayType: ", Type.toString t]

          | Ast.FieldTypeRef ((Ast.ObjectType fields), ident) =>
            let
                fun f [] = error ["FieldTypeRef on unknown field: ", Ustring.toAscii ident]
                  | f ({name,ty}::fields) = if name = ident
                                            then verifyTypeExpr env ty
                                            else f fields
            in
                f fields
            end

          | Ast.FieldTypeRef (Ast.SpecialType Ast.Any, _) =>
            Ast.SpecialType Ast.Any

          | Ast.FieldTypeRef (t, ident) =>
            error ["FieldTypeRef to ", Ustring.toAscii ident, " on non-ObjectType: ", Type.toString t]

          | _ => ty
                   (*
	      | _ =>
            let in
                logType ty;
                unimplError ["verifyTypeExpr"]
            end
            *)
    end

and verifyTypeExprs  (env:ENV)
		             (tys:Ast.TYPE_EXPR list)
    : Type.TYPE_VALUE list =
    (List.map (verifyTypeExpr env) tys)

(*
 * TODO: when type checking a function body, handle CalledEval
 * TODO: during type checking, if you see naked invocations of "eval" (that
 *       exact name), raise CalledEval
 *)

fun mergeTypes t1 t2 =
	(*FIXME*)
    t1

fun funcSigType (env:ENV)
                (fsig:Ast.FUNC_SIG)
    : Type.TYPE_VALUE =
    (* TODO: implement this *)
    anyType

(******************* Subtyping and Compatibility *************************)

infix 4 <:;

fun (tsub <: tsup) =
    Type.isSubtype (!Defn.topFixtures) tsub tsup

infix 4 ~:;

fun (tleft ~: tright) =
    Type.isCompatible (!Defn.topFixtures) tleft tright

fun checkCompatible (t1:Type.TYPE_VALUE)
		            (t2:Type.TYPE_VALUE)
    : unit =
    if t1 ~: t2
    then ()
    else let in
	     TextIO.print ("checkCompatible failed: " ^ (Type.toString t1) ^ " vs. " ^ (Type.toString t2) ^ "\n");
	     verifyError ["Types are not compatible"]
	 end

fun checkBicompatible (ty1:Type.TYPE_VALUE)
		              (ty2:Type.TYPE_VALUE)
    : unit =
    let in
	    checkCompatible ty1 ty2;
	    checkCompatible ty2 ty1
    end

fun checkConvertible (ty1:Type.TYPE_VALUE)
                     (ty2:Type.TYPE_VALUE)
    : unit =
    (* TODO: int to float, etc, and to() methods *)
    checkCompatible ty1 ty2

fun leastUpperBound (t1:Type.TYPE_VALUE)
                    (t2:Type.TYPE_VALUE)
    : Type.TYPE_VALUE =
    let
    in
        if t1 <: t2 then
            t2
        else if t2 <: t1 then
            t1
        else
            Ast.UnionType [t1, t2]
    end


(******************** Verification **************************************************)

(*
    HEAD
*)

and verifyInits (env:ENV) (inits:Ast.INITS)
    : Ast.INITS =
    List.map (fn (name, expr) => (name, verifyExprOnly env expr))
             inits

and verifyInitsOption (env:ENV)
		              (inits:Ast.INITS option)
    : Ast.INITS =
    case inits of
        SOME inits => verifyInits env inits
      | _ => internalError ["missing inits"]


and verifyHead (env:ENV) ((Ast.Head (fixtures, inits)):Ast.HEAD)
    : Ast.HEAD =
    (trace ["verifying head with ", Int.toString (length fixtures), " fixtures"];
     (Ast.Head (verifyFixtures env fixtures, verifyInits env inits)))

(*
    EXPR
*)

and verifyExpr (env:ENV)
               (expr:Ast.EXPR)
    : (Ast.EXPR * Type.TYPE_VALUE) =
    let
        fun verifySub e = verifyExpr env e
        fun verifySubList es = verifyExprs env es
        fun verifySubOption NONE = (NONE, NONE)
          | verifySubOption (SOME e) =
            let
                val (e', t) = verifySub e
            in
                (SOME e', SOME t)
            end
        fun return (e, t) =
            (Ast.ExpectedTypeExpr (t, e), t)
        val dummyType = Ast.SpecialType Ast.Any
        val { strict, ... } = env
        fun whenStrict (thunk:unit -> unit) : unit =
            if strict
            then thunk ()
            else ()

        val booleanType = instanceTypeExpr Name.intrinsic_boolean
    in
        case expr of
            Ast.TernaryExpr (e1, e2, e3) =>
            let
                val (e1', t1) = verifySub e1
                val (e2', t2) = verifySub e2
                val (e3', t3) = verifySub e3
            in
                whenStrict (fn () => checkConvertible t1 booleanType);
                (* FIXME: this produces a union type. is that right? *)
                return (Ast.TernaryExpr (e1', e2', e3'), leastUpperBound t2 t3)
            end

          | Ast.BinaryExpr (b, e1, e2) =>
            let
                val (e1', t1) = verifySub e1
                val (e2', t2) = verifySub e2
                val NumericType = verifyTypeExpr env (Name.typename Name.intrinsic_Numeric)
                val AdditionType = Ast.UnionType [ NumericType, instanceTypeExpr Name.intrinsic_string ]
                (* FIXME: these are way wrong. *)
                (* FIXME: need to deal with operator overloading *)
                val (expectedType1, expectedType2, resultType) =
                    case b of
                         Ast.Plus mode => (AdditionType, AdditionType, AdditionType)
                       | Ast.Minus mode => (NumericType, NumericType, NumericType)
                       | Ast.Times mode => (NumericType, NumericType, NumericType)
                       | Ast.Divide mode => (NumericType, NumericType, NumericType)
                       | Ast.Remainder mode => (NumericType, NumericType, NumericType)
                       | Ast.LeftShift => (NumericType, NumericType, NumericType)
                       | Ast.RightShift => (NumericType, NumericType, NumericType)
                       | Ast.RightShiftUnsigned => (NumericType, NumericType, NumericType)
                       | Ast.BitwiseAnd => (NumericType, NumericType, NumericType)
                       | Ast.BitwiseOr => (NumericType, NumericType, NumericType)
                       | Ast.BitwiseXor => (NumericType, NumericType, NumericType)
                       | Ast.LogicalAnd => (booleanType, booleanType, booleanType)
                       | Ast.LogicalOr => (booleanType, booleanType, booleanType)
                       | Ast.InstanceOf => (anyType, anyType, booleanType)
                       | Ast.In => (anyType, anyType, booleanType)
                       | Ast.Equals mode => (anyType, anyType, booleanType)
                       | Ast.NotEquals mode => (anyType, anyType, booleanType)
                       | Ast.StrictEquals mode => (anyType, anyType, booleanType)
                       | Ast.StrictNotEquals mode => (anyType, anyType, booleanType)
                       | Ast.Less mode => (NumericType, NumericType, booleanType)
                       | Ast.LessOrEqual mode => (NumericType, NumericType, booleanType)
                       | Ast.Greater mode => (NumericType, NumericType, booleanType)
                       | Ast.GreaterOrEqual mode => (NumericType, NumericType, booleanType)
                       | Ast.Comma => (anyType, anyType, t2)
            in
                whenStrict (fn () =>
                               let
                               in
                                   checkCompatible t1 expectedType1;
                                   checkCompatible t2 expectedType2
                               end);
                return (Ast.BinaryExpr (b, e1', e2'), resultType)
            end

          | Ast.ExpectedTypeExpr (t, e) =>
            (*
             * If we got here, we're re-verifying an already-verified expression.
             * This means we've already put expectations on all subexpressions, and
             * we don't want to re-wrap any subexpressions, so we just bottom out here.
             *)
            (Ast.ExpectedTypeExpr (t, e), t)

          | Ast.BinaryTypeExpr (b, e, te) =>
            let
                val (e', t1) = verifySub e
                val t2 = verifyTypeExpr env te
                val resultType = case b of
                                      Ast.Is => booleanType
                                    | _ => t2
            in
                whenStrict (fn () => case b of
                                          Ast.To => checkConvertible t1 t2
                                        | _ => checkCompatible t1 t2);
                return (Ast.BinaryTypeExpr (b, e', t2), resultType)
            end

          | Ast.UnaryExpr (u, e) =>
            let
                val (e', t) = verifySub e
                val NumericType = verifyTypeExpr env (Name.typename Name.intrinsic_Numeric)
                val resultType = case u of
                                      (* FIXME: these are probably mostly wrong *)
                                      Ast.Delete => booleanType
                                    | Ast.Void => undefinedType
                                    | Ast.Typeof => instanceTypeExpr Name.intrinsic_string
                                    | Ast.PreIncrement mode => NumericType
                                    | Ast.PreDecrement mode => NumericType
                                    | Ast.PostIncrement mode => NumericType
                                    | Ast.PostDecrement mode => NumericType
                                    | Ast.UnaryPlus mode => NumericType
                                    | Ast.UnaryMinus mode => NumericType
                                    | Ast.BitwiseNot => NumericType
                                    | Ast.LogicalNot => booleanType
                                    (* TODO: isn't this supposed to be the prefix of a type expression? *)
                                    | Ast.Type => instanceTypeExpr Name.intrinsic_Type
            in
                whenStrict (fn () =>
                               case u of
                                    (* FIXME: these are probably wrong *)
                                    Ast.Delete => ()
                                  | Ast.PreIncrement mode => checkCompatible t NumericType
                                  | Ast.PostIncrement mode => checkCompatible t NumericType
                                  | Ast.PreDecrement mode => checkCompatible t NumericType
                                  | Ast.PostDecrement mode => checkCompatible t NumericType
                                  | Ast.UnaryPlus mode => checkCompatible t NumericType
                                  | Ast.UnaryMinus mode => checkCompatible t NumericType
                                  | Ast.BitwiseNot => checkCompatible t NumericType
                                  | Ast.LogicalNot => checkConvertible t booleanType
                                  (* TODO: Ast.Type? *)
                                  | _ => ());
                return (Ast.UnaryExpr (u, e'), resultType)
            end

          | Ast.TypeExpr t =>
            let
                val t' = verifyTypeExpr env t
            in
                return (Ast.TypeExpr t', instanceTypeExpr Name.intrinsic_Type)
            end

          | Ast.ThisExpr =>
            (* FIXME: type of current class, if any... also Self type? *)
            return (Ast.ThisExpr, dummyType)

          | Ast.YieldExpr eo =>
            let
                val (eo', t) = verifySubOption eo
            in
                (* TODO: strict check that returnType is Generator.<t> *)
                return (Ast.YieldExpr eo', anyType)
            end

          | Ast.SuperExpr eo =>
            let
                val (eo', t) = verifySubOption eo
            in
                (* TODO: what is this AST form again? *)
                return (Ast.SuperExpr eo', dummyType)
            end

          | Ast.LiteralExpr le =>
            let
                val resultType = case le of
                                      Ast.LiteralNull => nullType
                                    | Ast.LiteralUndefined => undefinedType
                                    | Ast.LiteralDouble _ => instanceTypeExpr Name.intrinsic_double
                                    | Ast.LiteralDecimal _ => instanceTypeExpr Name.intrinsic_decimal
                                    | Ast.LiteralInt _ => instanceTypeExpr Name.intrinsic_int
                                    | Ast.LiteralUInt _ => instanceTypeExpr Name.intrinsic_uint
                                    | Ast.LiteralBoolean _ => instanceTypeExpr Name.intrinsic_boolean
                                    | Ast.LiteralString _ => instanceTypeExpr Name.intrinsic_string
                                    | Ast.LiteralArray { ty=SOME ty, ... } => verifyTypeExpr env ty
                                    (* FIXME: how do we want to represent [*] ? *)
                                    | Ast.LiteralArray { ty=NONE, ... } => Ast.ArrayType [Ast.SpecialType Ast.Any]
                                    (* TODO: define this *)
                                    | Ast.LiteralXML _ => anyType
                                    | Ast.LiteralNamespace _ => instanceTypeExpr Name.intrinsic_Namespace
                                    | Ast.LiteralObject { ty=SOME ty, ... } => verifyTypeExpr env ty
                                    (* FIXME: how do we want to represent {*} ? *)
                                    | Ast.LiteralObject { ty=NONE, ... } => anyType
                                    | Ast.LiteralFunction (Ast.Func { fsig, ... }) => funcSigType env fsig
                                    | Ast.LiteralRegExp _ => instanceTypeExpr Name.nons_RegExp
                                    | _ => internalError ["unprocessed literal returned by Defn"]
                fun verifyField { kind, name, init } =
                    { kind = kind,
                      name = name,
                      init = verifyExprOnly env init }

                val le = case le of
                             Ast.LiteralFunction func =>
                             Ast.LiteralFunction (verifyFunc env func)

                           | Ast.LiteralObject { expr, ty } =>
                             Ast.LiteralObject { expr = map verifyField expr,
                                                 ty = case ty of
                                                          NONE => NONE
                                                        | SOME ty' => SOME (verifyTypeExpr env ty') }

                           | Ast.LiteralArray { exprs, ... } =>
                             Ast.LiteralArray { exprs = map (verifyExprOnly env) exprs,
                                                ty = SOME resultType }
                           | x => x
            in
                return (Ast.LiteralExpr le, resultType)
            end

          | Ast.CallExpr {func, actuals} =>
            let
                val (func', t) = verifySub func
                val (actuals', ts) = verifySubList actuals
                val resultType = case t of
                                      Ast.FunctionType { result, ... } => result
                                    | _ => anyType
            in
                whenStrict (fn () =>
                               case t of
                                    (* FIXME: deal with type parameters *)
                                    Ast.FunctionType { typeParams, params, result, thisType, hasRest, minArgs } =>
                                    if (List.length actuals) < minArgs then
                                        verifyError ["too few actuals"]
                                    else if (not hasRest) andalso
                                            ((List.length actuals) > (List.length params)) then
                                        verifyError ["too many actuals"]
                                    else
                                        List.app (fn (formal, actual) => checkCompatible formal actual)
                                                 (ListPair.zip (params, ts))
                                  | Ast.SpecialType Ast.Any => ()
                                  | _ => verifyError ["ill-typed call"]);
                return (Ast.CallExpr { func = func', actuals = actuals' }, resultType)
            end

            (* TODO: what is this? *)
          | Ast.ApplyTypeExpr { expr, actuals } =>
            let
                val (expr', t) = verifySub expr
                val actuals' = List.map (verifyTypeExpr env) actuals
            in
                return (Ast.ApplyTypeExpr { expr = expr',
                                            actuals = actuals' }, dummyType)
            end

          (* TODO: ---------- left off here ---------- *)

          | Ast.LetExpr { defs, body, head } =>
            let
                val defs' = defs (* TODO *)
                val head' = Option.map (verifyHead env) head
                (* TODO: verify body with `head' fixtures in env *)
                val (body', t) = verifySub body
            in
                return (Ast.LetExpr { defs = defs',
                                      body = body',
                                      head = head' }, dummyType)
            end

          | Ast.NewExpr { obj, actuals } =>
            let
                val (obj', t) = verifySub obj
                val (actuals', ts) = verifySubList actuals
            in
                return (Ast.NewExpr { obj = obj',
                                      actuals = actuals' }, dummyType)
            end

          | Ast.ObjectRef { base, ident, loc } =>
            let
                val _ = LogErr.setLoc loc
                val (base', t) = verifySub base
                val _ = LogErr.setLoc loc
                val ident' = ident (* TODO *)
            in
                return (Ast.ObjectRef { base=base', ident=ident', loc=loc }, dummyType)
            end

          | Ast.LexicalRef { ident, loc } =>
            let
                val _ = LogErr.setLoc loc
                val ident' = ident (* TODO *)
                val _ = LogErr.setLoc loc
            in
                return (Ast.LexicalRef { ident=ident', loc=loc }, dummyType)
            end

          | Ast.SetExpr (a, le, re) =>
            let
                val (le', t1) = verifySub le
                val (re', t2) = verifySub re
            in
                return (Ast.SetExpr (a, le', re'), dummyType)
            end

          | Ast.GetTemp n =>
            (* TODO: these only occur on the RHS of compiled destructuring assignments. how to type-check? *)
            return (Ast.GetTemp n, dummyType)

          | Ast.GetParam n =>
            internalError ["GetParam not eliminated by Defn"]

          | Ast.ListExpr es =>
            let
                val (es', ts) = verifySubList es
            in
                return (Ast.ListExpr es', dummyType)
            end

          | Ast.SliceExpr (a, b, c) =>
            let
                val (a', t1) = verifySub a
                val (b', t2) = verifySub b
                val (c', t3) = verifySub c
            in
                return (Ast.SliceExpr (a, b, c), dummyType)
            end

          | Ast.InitExpr (it, head, inits) =>
            let
                val it' = it (* TODO *)
                val head' = verifyHead env head
                val inits' = verifyInits env inits
            in
                return (Ast.InitExpr (it', head', inits'), dummyType)
            end

    end


and verifyExprOnly (env:ENV)
                   (expr:Ast.EXPR)
    : Ast.EXPR =
    let
        val (e, _) = verifyExpr env expr
    in
        e
    end


and verifyExprs (env:ENV)
             (exprs:Ast.EXPR list)
    : Ast.EXPR list * Ast.TYPE_EXPR list =
    let
        val es = ListPair.unzip (map (verifyExpr env) exprs)
    in
        es
    end

and verifyExprAndCheck (env:ENV)
                       (expr:Ast.EXPR)
                       (expectedType:Type.TYPE_VALUE)
    : Ast.EXPR =
    let val (expr',ty') = verifyExpr env expr
        val _ = if #strict env
                then checkCompatible ty' expectedType
                else ()
    in
        expr'
    end

(*
    STMT
*)

and verifyStmt (env:ENV)
               (stmt:Ast.STMT)
    : Ast.STMT =
    let fun verifySub s = verifyStmt env s
        val booleanType = instanceTypeExpr Name.intrinsic_boolean
    in
        case stmt of
            Ast.EmptyStmt =>
            Ast.EmptyStmt

          | Ast.ExprStmt e =>
            Ast.ExprStmt (verifyExprOnly env e)

          | Ast.ForInStmt {isEach, defn, obj, fixtures, next, labels, body} =>
            let
                val obj = verifyExprOnly env obj
                val fixtures = valOf fixtures
                val fixtures = verifyFixtures env fixtures
                val env = withRib env fixtures
                val next = verifyStmt env next
                val body = verifyStmt env body
            in
                Ast.ForInStmt { isEach = isEach,
                                defn = defn,
                                obj = obj,
                                fixtures = SOME fixtures,
                                next = next,
                                labels = labels,
                                body = body }
            end

          | Ast.ThrowStmt es =>
            Ast.ThrowStmt (verifyExprOnly env es)

          | Ast.ReturnStmt es =>
            let val (es',ty) = verifyExpr env es
            in
                if #strict env
                then
	                case #returnType env of
	                    NONE => verifyError ["return not allowed here"]
                      | SOME retTy => checkCompatible ty retTy
                else ();
                Ast.ReturnStmt es'
            end

          | Ast.BreakStmt i =>
            Ast.BreakStmt i

          | Ast.ContinueStmt i =>
            Ast.ContinueStmt i

          | Ast.BlockStmt block =>
            Ast.BlockStmt (verifyBlock env block)

          | Ast.ClassBlock { ns, ident, name, block } =>
            Ast.ClassBlock { ns=ns, ident=ident, name=name,
                             block=verifyBlock env block }

          | Ast.LabeledStmt (id, s) =>
            Ast.LabeledStmt (id, verifySub s)

          | Ast.LetStmt block =>
            Ast.LetStmt (verifyBlock env block)

          | Ast.WhileStmt {cond,body,labels,fixtures=NONE} =>
            Ast.WhileStmt {cond=verifyExprAndCheck env cond booleanType,
                           body=verifySub body,
                           labels=labels,
                           fixtures=NONE}

          | Ast.DoWhileStmt {cond,body,labels,fixtures=NONE} =>
            Ast.DoWhileStmt {cond=verifyExprAndCheck env cond booleanType,
                             body=verifySub body,
                             labels=labels,
                             fixtures=NONE}

          | Ast.ForStmt  { defn=_, fixtures, init, cond, update, labels, body } =>
            let val fixtures' = verifyFixturesOption env fixtures
                val env' = withRib env fixtures'
                val init' = verifyStmts env' init
                val cond' = verifyExprAndCheck env' cond booleanType
                val update' = verifyExprOnly env' update
                val body' = verifyStmt env' body
            in
                Ast.ForStmt  { defn=NONE, fixtures=SOME fixtures', init=init', cond=cond',
                               update=update', labels=labels, body=body' }
            end
          | Ast.IfStmt {cnd, els, thn} =>
            Ast.IfStmt {cnd=verifyExprAndCheck env cnd booleanType,
                        els=verifySub els,
                        thn=verifySub thn}

          | Ast.WithStmt {obj, ty, body} => (*TODO*)
            Ast.WithStmt {obj=obj, ty=ty, body=body}

          | Ast.TryStmt {block, catches, finally} =>
            Ast.TryStmt {block=verifyBlock env block,
                         catches=List.map (verifyCatchClause env) catches,
                         finally=Option.map (verifyBlock env) finally }

          | Ast.SwitchStmt {cond, cases, mode, labels} =>
            let
                fun verifyCase { label, inits, body } =
                    { label = Option.map (verifyExprOnly env) label,
                      inits = Option.map (verifyInits env) inits,
                      body = verifyBlock env body }
            in
                Ast.SwitchStmt {cond = verifyExprOnly env cond,
                                cases = map verifyCase cases,
                                mode = mode,
                                labels = labels}
            end

          | Ast.SwitchTypeStmt {cond, ty, cases} =>
            Ast.SwitchTypeStmt {cond = verifyExprOnly env cond,
                                ty = verifyTypeExpr env ty,
                                cases = List.map (verifyCatchClause env) cases}

          | Ast.DXNStmt x => (*TODO*)
            Ast.DXNStmt x

          | _ => error ["Shouldn't happen: failed to match in Verify.verifyStmt"]

    end

and verifyCatchClause (env:ENV)
                      ({bindings, ty, fixtures, inits, block}:Ast.CATCH_CLAUSE)
    : Ast.CATCH_CLAUSE =
    let
        val ty = verifyTypeExpr env ty
        val fixtures' = verifyFixturesOption env fixtures
        val inits' = verifyInitsOption env inits
        val env' = withRib env fixtures'
        val block' = verifyBlock env' block
    in
        {bindings=bindings, ty=ty,
         fixtures=SOME fixtures', inits=SOME inits', block=block'}
    end

and verifyStmts (env) (stmts:Ast.STMT list)
    : Ast.STMT list =
    List.map (verifyStmt env) stmts

and verifyBlock (env:ENV)
                (b:Ast.BLOCK)
    : Ast.BLOCK =
    let
    in case b of
        Ast.Block { head, body, loc, pragmas=pragmas, defns=defns } =>
            let
                val _ = LogErr.setLoc loc
                val (Ast.Head (fixtures, _)) = valOf head
                val env = withRib env fixtures
                val head = Option.map (verifyHead env) head
                val body = verifyStmts env body
            in
                Ast.Block { pragmas = pragmas,
                            defns = defns,
                            body = body,
                            head = head,
                            loc = loc }
            end
    end

(*
    FIXTURES
*)

and verifyFunc (env:ENV)
               (func:Ast.FUNC)
    : Ast.FUNC =
    let
        val Ast.Func { name, fsig, native, block, param, defaults, ty, loc } = func
        val Ast.FunctionType ty = verifyTypeExpr env (Ast.FunctionType ty)
        val param = verifyHead env param
        val (defaults,_) = verifyExprs env defaults
        val (Ast.Head (paramFixtures, _)) = param
        val env = withRib env paramFixtures
        val block = verifyBlock env block
    in
        Ast.Func { name=name, fsig=fsig, native=native, block=block, param=param, defaults=defaults, ty=ty, loc=loc }
    end

and verifyFixture (env:ENV)
		          (f:Ast.FIXTURE)
    : Ast.FIXTURE = (*TODO*)
    let in
        case f of
         Ast.NamespaceFixture ns =>
         Ast.NamespaceFixture ns
       | Ast.ClassFixture (Ast.Cls {name, nonnullable, dynamic, extends, implements, classFixtures, instanceFixtures,
                                    instanceInits, constructor, classType, instanceType }) =>
         let
             val classFixtures = verifyFixtures env classFixtures
             val env = withRib env classFixtures
             val instanceFixtures = verifyFixtures env instanceFixtures
             val instanceInits = verifyHead env instanceInits
             val constructor = case constructor of
                                   NONE => NONE
                                 | SOME (Ast.Ctor {settings, superArgs, func}) =>
                                   let
                                       val settings = verifyHead env settings
                                       val (superArgs, _) = verifyExprs env superArgs
                                       val func = verifyFunc env func
                                   in
                                       SOME (Ast.Ctor { settings = settings,
                                                        superArgs = superArgs,
                                                        func = func })
                                   end
         in
             Ast.ClassFixture (Ast.Cls {name=name, nonnullable=nonnullable, dynamic=dynamic, extends=extends,
                                        implements=implements, classFixtures=classFixtures,
                                        instanceFixtures=instanceFixtures,
                                        instanceInits=instanceInits,
                                        constructor=constructor, classType=classType, instanceType=instanceType })
         end
       | Ast.TypeVarFixture =>
         Ast.TypeVarFixture
       | Ast.TypeFixture ty =>
         Ast.TypeFixture (verifyTypeExpr env ty)
       | Ast.ValFixture {ty, readOnly} =>
         Ast.ValFixture {ty=verifyTypeExpr env ty, readOnly=readOnly}
       | Ast.MethodFixture { func, ty, readOnly, override, final, abstract } =>
         let
             val func = verifyFunc env func
             val ty = verifyTypeExpr env ty
         in
             Ast.MethodFixture { func=func, ty=ty, readOnly=readOnly, override=override, final=final, abstract=abstract }
         end
       | Ast.VirtualValFixture { ty, getter, setter} =>
         let
             fun verifyFuncDefnOption NONE = NONE
               | verifyFuncDefnOption (SOME { kind, ns, final, override, prototype, static, abstract, func}) =
                 SOME { kind = kind,
                        ns = ns,
                        final = final,
                        override = override,
                        prototype = prototype,
                        static = static,
                        abstract = abstract,
                        func = verifyFunc env func}
             val ty = verifyTypeExpr env ty
             val getter = verifyFuncDefnOption getter
             val setter = verifyFuncDefnOption setter
         in
             Ast.VirtualValFixture { ty = ty, getter = getter, setter = setter }
         end

       | _ => f
    (*
       | _ => unimplError ["in verifyFixture"]
     *)
    end

and verifyFixtures (env:ENV)
                   (fixtures:Ast.FIXTURES)
    : Ast.FIXTURES =
    let
        val env = withRib env fixtures
        fun doFixture (name, fixture) =
            (trace ["verifying fixture: ", LogErr.fname name];
             (name,verifyFixture env fixture))
    in
        map doFixture fixtures
    end

and verifyFixturesOption (env:ENV)
		                 (fs:Ast.FIXTURES option)
    : Ast.FIXTURES =
    case fs of
        SOME fixtures => verifyFixtures env fixtures
      | _ => internalError ["missing fixtures"]

(*
    PROGRAM
*)

and topEnv () = { ribs = [Fixture.getTopFixtures (!Defn.topFixtures)],
                  strict = false,
                  returnType = NONE }

and verifyPackage (env:ENV) (p:Ast.PACKAGE)
    : Ast.PACKAGE =
    { name = (#name p),
      block = verifyBlock env (#block p) }

and verifyTopFixtures _ =
    (* FIXME: too much unwrapping/rewrapping going on here *)
    Defn.topFixtures := Fixture.mkTopFixtures (verifyFixtures (topEnv()) (Fixture.getTopFixtures (!Defn.topFixtures)))

and verifyProgram (p:Ast.PROGRAM)
    : Ast.PROGRAM =
    let
    in case p of
        { packages, fixtures, block } =>
            let
                val _ = LogErr.setLoc NONE
                val e = topEnv ()
                val packages = map (verifyPackage e) packages
                val block = verifyBlock e block
                val fixtures = verifyFixturesOption e fixtures
                val result = { packages = packages,
                               block = block,
                               fixtures = SOME fixtures }
            in
                verifyTopFixtures ();
                trace ["verification complete"];
                (if !doTrace orelse !doTraceProg
                 then Pretty.ppProgram result
                 else ());
                result
            end
    end
end



(********************************** OLD **************************************

(*
 * INVARIANTS:
 *   - all typed libraries in host environment must be DontDelete
 *   - all typed libraries in host environment must carry compatible runtime type constraints
 *)

(****************************** type environments *************************)

type ID = FIXTURE_NAME

fun checkForDuplicateExtension extensions =
    let val (names, _) = ListPair.unzip extensions
    in
      checkForDuplicates names
end

fun extendEnv (env:TYPE_ENV) (id:ID) (k:KIND) : TYPE_ENV = (id,k)::env
fun extendEnvWithTypeVars (params:ID list) (env:TYPE_ENV):TYPE_ENV =
    let in
	checkForDuplicates params;
	foldl (fn (p,env) => extendEnv env p TypeVar) env params
    end
fun extendEnvs (env:TYPE_ENV) (ext:TYPE_ENV) =
    let in
	ext @ env
    end
fun fixtureNameToString (TempName i) = "TempName" ^ (Int.toString(i))
  | fixtureNameToString (PropName { ns, id }) = id

fun lookupIdNamespace (env:TYPE_ENV)
		      (id:Ast.IDENT)
		      (ns:NAMESPACE)
    : KIND option =
    case List.find (fn (i,_) => i=PropName {id=id,ns=ns}) env of
	NONE => NONE
      | SOME (_,k) => SOME k

fun lookupIdNamespaces (env:TYPE_ENV)
		       (id:Ast.IDENT)
		       (nss : NAMESPACE list)
    : KIND option =
    let val theMatches
	  = List.mapPartial (lookupIdNamespace env id) nss
    in
	case theMatches of
	    [] => NONE
	  | [k] => SOME k



(******************** Expressions **************************************************)

and verifyIdentExpr (env as {env,this,...}:RIB)
		    (ide:Ast.IDENT_EXPR)
    : Ast.TYPE_EXPR =
    let
    in
	case ide of
	    Ast.QualifiedIdentifier { qual, ident } =>
	    let in
		checkCompatible (verifyExpr env qual) NamespaceType;
		anyType
	    end
	  | Ast.QualifiedExpression { qual, expr } =>
	    let in
		checkCompatible (verifyExpr env qual) NamespaceType;
		checkCompatible (verifyExpr env qual) stringType;
		anyType
	    end
	  | Ast.AttributeIdentifier idexpr =>
	    let in
		verifyIdentExpr env idexpr;
		anyType
	    end
	  | Ast.Identifier { ident, openNamespaces } =>
	    let val k : KIND = lookupIdNamespacess env ident openNamespaces
	    in
		case k of
		    TypeVar => verifyError ["Attempt to refer to type variable ",
                                    ident,
                                    " as a program variable"]
		  | ProgVar (ty,read_only) => ty
	    end
    end

and verifyExpr (env as {env,this,...}:RIB)
	       (e:EXPR)
    : Ast.TYPE_EXPR =
    let
    in
      TextIO.print ("type checking expr: env len " ^ (Int.toString (List.length env)) ^"\n");
      Pretty.ppExpr e;
      TextIO.print "\n";
      case e of
        LiteralExpr LiteralNull => nullType
      | LiteralExpr (LiteralInt _) => intType
      | LiteralExpr (LiteralUInt _) => uintType
      | LiteralExpr (LiteralDecimal _) => decimalType
      | LiteralExpr (LiteralDouble _) => doubleType
      | LiteralExpr (LiteralBoolean _) => booleanType
      | LiteralExpr (LiteralString _) => stringType
      | LiteralExpr (LiteralRegExp _) => regexpType
      | LiteralExpr (LiteralArray { exprs, ty }) =>
        (* EXAMPLES:
           [a, b, c] : [int, Boolean, String]
           [a, b, c] : Array
           [a, b, c] : *
           [a, b, c] : Object
        *)
        let val annotatedTy = unOptionDefault ty anyType
            val inferredTy = ArrayType (map (fn elt => verifyExpr env elt) exprs)
        in
          checkCompatible inferredTy annotatedTy;
          annotatedTy
        end
      | LiteralExpr (LiteralObject { expr=fields, ty }) =>
        let val annotatedTy = unOptionDefault ty anyType
            val inferredTy = ObjectType (map (verifyField env) fields)
        in
          checkCompatible inferredTy annotatedTy;
          annotatedTy
        end
      | LiteralExpr (LiteralFunction (Func { param=(fixtures,inits), block, ty, ... }))
	=>
	 let
	     val env1 = verifyFunctionType env ty
	     val extensions = verifyFixtures env1 fixtures
	     val env2 = withEnvExtn env1 extensions
	 in
	     checkForDuplicateExtension extensions;
(** FIXME: inits are now settings and are BINDINGS
	     verifyStmts env2 inits;
*)
	     verifyBlock env2 block;
	     Ast.FunctionType ty
         end
      | LexicalRef { ident, loc } =>
	verifyIdentExpr env ident
      | ListExpr l => List.last (List.map (verifyExpr env) l)
      | LetExpr {defs=_, body, head=SOME (fixtures,inits) } =>  (* FIXME: inits added *)
          let val extensions = verifyFixtures env fixtures
          in
	    checkForDuplicateExtension extensions;
	    verifyExpr (withEnvExtn env extensions) body
	  end
       | ThisExpr => this
       | UnaryExpr (unop, arg) => verifyUnaryExpr env unop arg
       | BinaryExpr (binop, lhs, rhs ) => verifyBinaryExpr env (binop, lhs, rhs)
       | BinaryTypeExpr (binop, lhs, rhs ) => verifyBinaryTypeExpr env (binop, lhs, rhs)
       | TrinaryExpr (triop, a,b,c ) => verifyTrinaryExpr env (triop, a,b,c)

       | CallExpr { func, actuals } => verifyCallExpr env func actuals
       | ApplyTypeExpr {expr, actuals} =>
	 (* Can only instantiate Functions, classes, and interfaces *)
	 let val exprTy = verifyExpr env expr;
	     val typeParams =
		 case exprTy of
		     Ast.FunctionType {typeParams, ...} => typeParams
                   (* TODO: class and interface types *)
		   | _ => verifyError ["Cannot instantiate a non-polymorphic type"]
	 in
	     List.app (fn t => verifyTypeExpr env t) actuals;
	     if (List.length typeParams) = (List.length actuals)
	     then ()
	     else verifyError ["Wrong number of type arguments"];
	     normalizeType (Ast.AppType { base=exprTy, args=actuals })
	 end

       | TypeExpr ty =>
	 let in
	     verifyTypeExpr env ty;
	     typeType
	 end

       | _ => (TextIO.print "verifyExpr incomplete: "; Pretty.ppExpr e; raise Match)
    end

(*
     and LITERAL =
       | LiteralXML of EXPR list
       | LiteralNamespace of NAMESPACE

       | LiteralObject of
         { name: EXPR,
           init: EXPR } list

     and EXPR =
        | YieldExpr of EXPR option
       | SuperExpr of EXPR option

       | Ref of { base: EXPR option,
                  ident: Ast.IDENT_EXPR }
       | NewExpr of { obj: EXPR,x
                      actuals: EXPR list }


     and Ast.IDENT_EXPR =
         Ast.QualifiedIdentifier of { qual : EXPR,
                                  ident : Ustring.STRING }
       | Ast.QualifiedExpression of { qual : EXPR,
                                  expr : EXPR }
       | Ast.AttributeIdentifier of Ast.IDENT_EXPR
       | Ast.Identifier of Ast.IDENT
       | Ast.Expression of EXPR   (* for bracket exprs: o[x] and @[x] *)

*)


and verifyCallExpr  (env as {env,this,...}:RIB)
		    func actuals
    : Ast.TYPE_EXPR =
    let val functy = verifyExpr env func;
	val actualsTy = (map (fn a => verifyExpr env a) actuals)
    in case normalizeType functy of
	   Ast.SpecialType Ast.Any =>
	   (* not much to do *)
	   anyType
	 | Ast.FunctionType { typeParams, params, result, thisType, hasRest, minArgs }
	   =>
	   let
	   in
	       if not (null typeParams)
	       then verifyError ["Attempt to apply polymorphic function to values"]
	       else ();
	       (* check this has compatible type *)
	       case thisType of
		   NONE => ()  (* this lexically bound, nothing to check *)
		 | SOME t => checkCompatible this t;
	       (* check compatible parameters *)
	       let val (normalParams, restParam) =
		       if hasRest
		       then (List.rev (List.tl (List.rev params)), SOME (List.last params))
		       else (params, NONE)
		   (* handleArgs normalParams actualTys *)
		   fun handleArgs [] [] = ()
		     | handleArgs (p::pr) (a::ar) =
		       let in
			   checkCompatible a p;
			   handleArgs pr ar
		       end
		     | handleArgs [] (_::_) =
		       if hasRest
		       then (* all ok, no type checking to do on rest arg *) ()
		       else verifyError ["Too many args to function"]
		     | handleArgs (_::_) [] =
		       verifyError ["Not enough args to function"]
	       in
		   handleArgs params actualsTy;
		   result
	       end
	   end
	 | _ => verifyError ["Function expression does not have a function type"]
    end


(* TODO: verifyPattern returns a pair of env extension and (inferred) type?
         or takes a type (checked) and returns just extension? *)
(*
and verifyPattern (env:RIB) (Ast.IdentifierPattern name) = (
  | verifyPattern env (Ast.ObjectPattern props) =
  | verifyPattern env (Ast.ArrayPattern elts) =
  | verifyPattern env (Ast.SimplePattern expr) = ??
*)

and verifyExprList (env as {env,this,...}:RIB)
		   (l:EXPR list)
    : Ast.TYPE_EXPR =
    let
    in
	List.last (List.map (verifyExpr env) l)
    end

and verifyField (env:RIB)
		({kind,name,init}:FIELD)
    : FIELD_TYPE =
	let
		val Ast.Identifier {ident,...} = name
	in
	    {name=ident, ty = verifyExpr env init }
	end

(* This type checksTODO: this needs to return some type structure as well *)

(* deprecated due to fixtures
and verifyBinding (env:RIB)
		  (Binding {init,pattern,ty})
    : TYPE_ENV =
    let val ty = unOptionDefault ty anyType in
	case init of
	    SOME expr => checkCompatible (verifyExpr env expr) ty
	  | NONE => ();
	case pattern of
	    IdentifierPattern ident => [(ident,SOME ty)]
    end

(*
 and VAR_BINDING =
         Binding of { init: EXPR option,
                      pattern: PATTERN,
                      ty: Ast.TYPE_EXPR option }

*)


and verifyVarBinding (env:RIB)
		     (Binding {init, pattern, ty}:VAR_BINDING)
    : TYPE_ENV =
    let in
	case pattern of
	    IdentifierPattern ident =>
	    [(ident,SOME (unOptionDefault ty anyType))]
	    end

and verifyVarBindings (env:RIB)
		      (vs:VAR_BINDING list)
    : TYPE_ENV =
    case vs of
	[] => []
      | h::t => (verifyVarBinding env h) @ (verifyVarBindings env t)
*)

and verifyUnaryExpr (env:RIB)
		    (unop:UNOP)
		    (arg:EXPR)
    : Ast.TYPE_EXPR =
    let val argType = verifyExpr env arg
	fun checkNumeric () =
	    let in
		checkBicompatible booleanType argType;
		argType
	    end
    in
	case unop of
	    Void => (verifyExpr env arg; undefinedType)
          | Typeof => (verifyExpr env arg; stringType)

	  (* Assume arg is an l-value *)
          | PreIncrement _  => checkNumeric ()
          | PostIncrement _ => checkNumeric ()
          | PreDecrement _  => checkNumeric ()
          | UnaryPlus _     => checkNumeric ()
          | UnaryMinus _    => checkNumeric ()
          | BitwiseNot      =>
	    let in checkConvertible argType uintType; uintType end
          | LogicalNot    =>
	    let in checkConvertible argType booleanType; booleanType end

  (*
             Delete => (case arg of
                            Ref {base=NONE,ident=???} =>
                          | Ref {base=SOME baseExpr,ident=???} =>
                          | _ => verifyError ["can only delete ref expressions"])
  *)

(*
          | MakeNamespace
          | Type
*)
          | _ =>
	    let in
		TextIO.print "verifyUnaryExpr incomplete: ";
		Pretty.ppExpr (UnaryExpr (unop,arg));
		raise Match
	    end
    end

and verifyBinaryExpr (env:RIB) (bop:BINOP, lhs:EXPR, rhs:EXPR) =
    let
    in
	case bop of
	    _ =>
	    let in
		TextIO.print "verifyBinaryExpr incomplete: ";
		Pretty.ppExpr (BinaryExpr (bop,lhs,rhs));
		raise Match
	    end
    end

and verifyBinaryTypeExpr (env:RIB)
			 (bop:BINTYPEOP, arg:EXPR, t:Ast.TYPE_EXPR) =
    let val argType = verifyExpr env arg
    in
	verifyTypeExpr env t;
	case bop of
	    Cast =>
	    let in
		(* TODO: check *)
		(* checkConvertible argType t; *)
		t
	    end
	  | To =>
	    let in
		(* TODO: check *)
		checkConvertible argType t;
		t
	    end
	  | Is =>
	    let in
		(* TODO: check *)
		checkConvertible argType t;
		booleanType
	    end
    end


and verifyTrinaryExpr (env:RIB) (triop:TRIOP, a:EXPR, b:EXPR, c:EXPR) =
    case triop of
	Cond =>
	let val aty = verifyExpr env a
	    val bty = verifyExpr env b
	    val cty = verifyExpr env c
	in
	    checkConvertible aty booleanType;
	    (*FIXME*)
	    checkConvertible bty cty;
	    cty
	end

(****************************** Verifying Statements ********************************)

and verifyStmts env ss = List.app (fn s => verifyStmt env s) ss

and verifyStmt (env as {this,env,lbls:(Ast.IDENT list),retTy}:RIB) (stmt:STMT) =
   let
   in
       TextIO.print ("type checking stmt: env len " ^ (Int.toString (List.length env)) ^"\n");
       Pretty.ppStmt stmt;
       TextIO.print "\n";
   case stmt of
    EmptyStmt => ()
  | ExprStmt e => (verifyExpr env e; ())
  | IfStmt {cnd,thn,els} =>
    let in
	checkCompatible (verifyExpr env cnd) booleanType;
	verifyStmt env thn;
	verifyStmt env els
    end

  | (DoWhileStmt {cond,body,labels,fixtures} | WhileStmt {cond,body,labels,fixtures}) =>
    let in
	checkCompatible (verifyExpr env cond) booleanType;
	verifyStmt (withLbls env (labels@lbls)) body
    end

  | ReturnStmt e =>
    let in
	case retTy of
	    NONE => verifyError ["return not allowed here"]
          | SOME retTy => checkCompatible (verifyExpr env e) retTy
    end

  | (BreakStmt NONE | ContinueStmt NONE) =>
    let in
	case lbls of
	    [] => verifyError ["Not in a loop"]
	  | _ => ()
    end

  | (BreakStmt (SOME lbl) | ContinueStmt (SOME lbl)) =>
    let in
	if List.exists (fn x => x=(lbl)) lbls
	then ()
	else verifyError ["No such label"]
    end

  | BlockStmt b => verifyBlock env b

  | LabeledStmt (lab, s) =>
	verifyStmt (withLbls env ((lab)::lbls)) s

  | ThrowStmt t =>
	checkCompatible (verifyExpr env t) exceptionType

(* deprecated due to fixtures
  | LetStmt (defns, body) =>
    let val extensions = List.concat (List.map (fn d => verifyBinding env d) defns)
    in
        checkForDuplicateExtension extensions;
        verifyStmt (withEnv (env, foldl extendEnv env extensions)) body
    end
*)

  | ForStmt { defn=_, fixtures, init, cond, update, labels, body } =>
    let val extensions = verifyFixturesOption env fixtures
        val env' = withEnvExtn env extensions
(* NOT USED
	fun verifyExprs exprs =
	    let in
		if List.length exprs = 0
		then booleanType
		else List.last (List.map (fn e => verifyExpr env' e) exprs)
	    end
*)

    in
  	verifyStmts env' init;
	checkCompatible (verifyExpr env' cond) booleanType;
	verifyExpr env' update;
	verifyStmt (withLbls env' (labels@lbls)) body
    end

  | SwitchStmt { cond, cases, ... } =>
    let val ty = verifyExpr env cond
    in
	List.app
	    (fn {label,body,inits} =>	(* FIXME: verify inits *)
		let in
		    (Option.app
			 (fn e => checkBicompatible ty (verifyExpr env e))
			 label);
		    verifyBlock env body
		end)
	    cases
    end

  | TryStmt { block, catches, finally } =>
    let
    in
	verifyBlock env block;
	case finally of
	    NONE => ()
	  | SOME block => verifyBlock env block;
	List.app
	(fn {bindings, ty, fixtures, block} =>
	    ())
	catches
    end

(* TODO: InitStmt for function defn test *)

  | _ => (TextIO.print "verifyStmt incomplete: "; Pretty.ppStmt stmt; raise Match)

(*
       | ForEachStmt of FOR_ENUM_STMT
       | ForInStmt of FOR_ENUM_STMT
       | SuperStmt of EXPR list

       | WithStmt of { obj: EXPR,
                       body: STMT }

       | TryStmt of { body: BLOCK,
                      catches: (FORMAL * BLOCK) list,
                      finally: BLOCK }
*)

   end

(***************************** Verifying Definitions ****************************************)


(*
and verifyDefn (env as {this,env,lbls,retTy}:RIB) (d:DEFN) : (TYPE_ENV * int list) =
    let
    in
	case d of
(* FIXME
	    VariableDefn {bindings,...} =>
	    (List.concat (List.map (verifyVarBinding env) bindings), [])
	  |
*)
	    FunctionDefn { kind, func,... } =>
	    let val Func {name, fsig, fixtures, inits, body } = func
		val FunctionSignature { typeParams, params, inits,
					returnType, thisType, hasRest }
		  = fsig
		val { kind, ident } = name
		val env3 = verifyFunctionSignature env fsig
	    in
		verifyBlock env3 body;
		([(ident, SOME (Ast.FunctionType fsig))],[])
            end

	  | InterfaceDefn {ident,ns,nonnullable,params,extends,body} =>
	    let val nuEnv = extendEnvWithTypeVars params env
	    in
		verifyBlock (withEnv (env,nuEnv)) body;
		List.app
		(fn (superi:Ast.IDENT_EXPR) =>
		    (* need to check that this interface implements _all_ methods of superinterface ident *)
		    ()
		)
		extends;
		([],[])
	    end


(*
and INTERFACE_DEFN =
         { ident: Ast.IDENT,
           ns: EXPR,
           nonnullable: bool,
           params: Ast.IDENT list,
           extends: Ast.IDENT_EXPR list,
           body: BLOCK }
     *)

	  | d => (TextIO.print "verifyDefn incomplete: "; Pretty.ppDefinition d; raise Match)
    end


and verifyDefns env ([]:DEFN list) : (TYPE_ENV * int list) = ([], [])
  | verifyDefns env ((d::ds):DEFN list) : (TYPE_ENV * int list) =
        let val (extensions1, classes1) = verifyDefn env d
            val (extensions2, classes2) = verifyDefns env ds
        in
            (extensions1 @ extensions2, classes1 @ classes2)
        end
*)

(******************** Fixtures **************************************************)

(* fixtures at the block level *)

(******************** Blocks **************************************************)




and verifyBlock (env as {env,...})

                (Block {pragmas,defns=_,body,head,loc}) =
let
     val SOME (fixtures,inits) = head
        val extensions = verifyFixtures env fixtures
        val env' = withEnvExtn env extensions
    in
        verifyStmts env' body
    end

fun verifyProgram (prog as { packages, fixtures, block }) =
    let
    in
      TextIO.print ("type checking program\n");
      Pretty.ppFixtures (!Defn.topFixtures);
      TextIO.print "\n";
      Pretty.ppProgram prog;
      TextIO.print "\n";
      verifyBlock {this=anyType, env=[], lbls=[], retTy=NONE} block;
      true
    end

(* CF: Let this propagate to top-level to see full trace
    handle VerifyError msg =>
	   let in
     	       TextIO.print "Ill typed exception: ";
     	       TextIO.print msg;
     	       TextIO.print "\n";
     	       false
	   end

*)

end

************************************)
