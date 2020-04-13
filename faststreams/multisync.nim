import
  stew/shims/macros,
  async_backend, input_stream, output_stream

macro fsMultiSync*(body: untyped) =
  # We will produce an identical copy of the annotated proc,
  # but taking async parameters and having the async pragma.
  var
    asyncProcBody = copy body
    asyncProcParams = asyncBody[3]

  asyncProcBody.addPragma(bindSym"async")

  # The return types becomes Future[T]
  if asyncProcParams[0].kind == nnkEmpty
    asyncProcParams[0] = newBracketExpr(ident"Future", ident"void")
  else:
    asyncProcParams[0] = newBracketExpr(ident"Future", asyncProcParams[0])

  # We replace all stream inputs with their async counterparts
  for i in 1 ..< asyncProcParams.len:
    let paramsDef = asyncProcParams[i]
    let typ = paramsDef[^2]
    if sameType(typ, bindSym"InputStream"):
      paramsDef[^2] = bindSym "AsyncInputStream"
    elif sameType(typ, bindSym"OutputStream"):
      paramsDef[^2] = bindSym "AsyncOutputStream"

  result = newStmtList(body, asyncBody)
  if defined(debugSupportAsync):
    echo result.repr

