. MRAS JCL SCRIPT
//assign N=COMP
//assign E=CMD
.DO #N# (I) to import source from host - (O) to import _ORIG file
.   (D) to import _DASM file - (R) to reimport JCL
//if R
import -n #N#.jcl #N#/jcl:1
//exit
//end
//if D
import -n #N#_DASM.asm #N#/asm:1
//end
//if O
import -n #N#_ORIG.asm #N#/asm:1
//end
//if I
import -n #N#.asm #N#/asm:1
//end
//PAUSE
sim f
.mras #N#/asm:1 +o=#N#T/#E#:1 +s=#N#T/sym:1 -gc-nm-ne-nc-we-nh
mras #N#/asm:1 +o=#N#T/#E#:1 +l=#N#T/lst:1 -gc-nm-ne-nc-we-nh
//if I+O+D
export #N#T/#E#:1
.export #N#T/sym:1
export #N#T/lst:1
//end
sim s
