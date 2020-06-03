module tardy.from;

/**
   Local imports everywhere.
 */
template from(string moduleName) {
    mixin("import from = " ~ moduleName ~ ";");
}
