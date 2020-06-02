import reggae;
enum debugFlags = "-w -g -debug";
alias ut = dubTestTarget!(CompilerFlags(debugFlags));
alias asan = dubConfigurationTarget!(
    Configuration("asan"),
    CompilerFlags(debugFlags ~ " -unittest -cov -fsanitize=address"),
    LinkerFlags("-fsanitize=address"),
);

mixin build!(ut, optional!asan);
