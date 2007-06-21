{ 
    import util.*;
    import cogen.*;

    use namespace Ast;
    use namespace Parser;

    var parser = new Parser("print(3+4)");
    var [ts1,nd1] = parser.program();
    print(Ast::encodeProgram (nd1));

/*  
    {
        import emitter.*;
        var e = new ABCEmitter();

        cogen.cgStmt({ "emitter": e, "asm": e.newScript().init.asm, "cp": e.constants }, 
                     nd1.block.stmts[0]);

        dumpABCFile(e.finalize(), "hello-test.es");
    }
*/

    dumpABCFile(cogen.cg(nd1), "hello-test.es");
}
