cp $1.1.ast esc-tmp.ast
make run-dumped FILE="tests/self/debug.es tests/self/ast.es tests/self/ast_encoder.es tests/self/ast_decoder.es tests/self/lexer.es tests/self/util.es tests/self/parser.es tests/self/util-es4ri.es tests/self/esc2.es"
cp esc-tmp.ast $1.2.ast
diff -s $1.1.ast $1.2.ast