$!  BUILDVMS.COM - builds FCALC.EXE, the scientific calculator written in
$!  Fortran 90, on govax (https://github.com/tucats/govax), the VAX/VMS
$!  emulator whose FORTRAN compiler takes Fortran 90.
$!
$!  The sources are in [.SRC] below the directory this procedure is in, 16
$!  files, each a module but the last (FCALC.F90, the main program). The
$!  modules are compiled in the order below, each before the modules that
$!  USE it: compiling one writes its module file, NAME.F90$MOD, which the
$!  later ones read. fcalc must be compiled /G_FLOATING: its kind,
$!  SELECTED_REAL_KIND(15, 300), needs G_floating's range.
$!
$!  FCALC.EXE is left in the directory this procedure is in. Define a
$!  foreign command to run it, for example:
$!
$!      $ FCALC :== $DUA1:[ME.FCALC]FCALC
$!
$!  Usage: @BUILDVMS
$!
$ on error then goto failed
$ saved_default = f$environment("DEFAULT")
$ here = f$environment("PROCEDURE")
$ top = f$parse(here,,,"DEVICE") + f$parse(here,,,"DIRECTORY")
$ set default 'top'
$ set default [.src]
$ modules = "FCPLATFORM,FCKINDS,FCMESSAGES,FCVALUES,FCARRAYS,FCLEXER," + -
    "FCTREE,FCSYMBOLS,FCFUNCS,FCPOLY,FCMATRIX,FCEVAL,FCNUMERIC,FCPLOT," + -
    "FCSTATE,FCALC"
$ n = 0
$ compile:
$ module = f$element(n, ",", modules)
$ if module .eqs. "," then goto assemble
$ fortran/g_floating 'module'
$ macro/nolist 'module'
$ n = n + 1
$ goto compile
$ assemble:
$ link/executable='top'fcalc fcalc,fcplatform,fckinds,fcmessages,fcvalues,-
    fcarrays,fclexer,fctree,fcsymbols,fcfuncs,fcpoly,fcmatrix,fceval,-
    fcnumeric,fcplot,fcstate
$ delete *.mar;*,*.obj;*,*.f90$mod;*
$ set default 'saved_default'
$ write sys$output "FCALC.EXE built"
$ exit
$!
$ failed:
$ status = $status
$ set default 'saved_default'
$ write sys$output "FCALC.EXE was not built"
$ exit status
