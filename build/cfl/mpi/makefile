#     $Id$
#=============================================================================
#
#        creates the mpi executable for the parallel version of cfl3d
#
#=============================================================================

# ***************************** CREATE LINKS *********************************

link:     lncode lnhead lnlibs

lncode:
	@ echo "        linking source code"
	ln -s $(CFLSRC_D)/*.F .
	ln -s $(CFLSRC_S)/ccomplex.F .

lnhead:

lnlibs:
	ln -s ../libs/$(COMMONLIB) .

# ****************************** SUFFIX RULES ********************************

.F.o:
	$(FTN) $(CPPOPT) $(FFLAG) -c $*.F

# **************************** CREATE LIBRARIES  *****************************

#Note: fsrc_dist dependancy list must not contain development.F 
	
FSRC_DIST = \
    ae_corr.F        \
    avggp.F          \
    bc_blkint.F      \
    bc_embed.F       \
    bc_patch.F       \
    bc_period.F      \
    calyplus.F       \
    cfl3d.F          \
    compg2n.F        \
    cputim.F         \
    dynptch.F        \
    findmin_new.F    \
    forceout.F       \
    mgbl.F           \
    mgblk.F          \
    newalpha.F       \
    patcher.F        \
    plot3c.F         \
    plot3c_sample.F  \
    plot3d_avg.F     \
    plot3d.F         \
    plot3d_2d.F      \
    plot3d_coarse.F  \
    plot3t.F         \
    pointers.F       \
    pre_bc.F         \
    prntcp.F         \
    qinter.F         \
    qout.F           \
    qout_2d.F        \
    qout_avg.F       \
    qout_coarse.F    \
    qout_sample.F    \
    reass.F          \
    resetg.F         \
    resp.F           \
    rrest.F          \
    rrestg.F         \
    setslave.F       \
    setup.F          \
    sizer.F          \
    termn8.F         \
    trnsfr_vals.F    \
    umalloc.F        \
    umalloc_c.F      \
    umalloc_r.F      \
    updatedg.F       \
    updateg.F        \
    usrint.F         \
    wrest.F          \
    wrestg.F         \
    writ_buf.F       \
    yplusout.F       
	
FSRC_SPEC =

FOBJ_DIST = $(FSRC_DIST:.F=.o)

FOBJ_SPEC = $(FSRC_SPEC:.F=.o)

DISTLIB = libdist.a

$(DISTLIB): $(FSRC_DIST) $(FOBJ_DIST) $(FSRC_SPEC) $(FOBJ_SPEC)
	ar $(AROPT) $(DISTLIB) $(FOBJ_DIST) $(FOBJ_SPEC)
	@$(RANLIB) $(DISTLIB)

HEAD_DIST = 
qout.o: ../libs/module_kwstm.o ../libs/module_profileout.o ../libs/module_contour.o
pointers.o: ../libs/module_kwstm.o
mgbl.o: ../libs/module_kwstm.o
setup.o: ../libs/module_kwstm.o

$(FOBJ_DIST): $(HEAD_DIST)
	$(FTN) $(CPPOPT) $(FFLAG) -c $*.F

$(FOBJ_SPEC): $(HEAD_DIST)
	$(FTN) $(CPPOPT) $(FFLAG_SPEC) -c $*.F

# *************************** CREATE EXECUTABLE ******************************

#Note: for inlining on cray, ccomplex must appear first in fsrc_main

FSRC_MAIN = ccomplex.F development.F  main.F

FOBJ_MAIN = $(FSRC_MAIN:.F=.o)

HEAD_MAIN = 

$(FOBJ_MAIN): $(HEAD_MAIN)
	$(FTN) $(CPPOPT) $(FFLAG) -c $*.F

COMMONLIB   = libcommon.a

$(EXEC): $(FSRC_MAIN) $(FOBJ_MAIN) $(DISTLIB) $(COMMONLIB) 
	-ln -s ../libs/*.o .
	$(FTN) $(CPPOPT) $(LFLAG) -o $(EXEC) *.o $(LLIBS) 
	@ echo "                                                              "
	@ echo "=============================================================="
	@ echo "                                                              "
	@ echo "                   DONE:  $(EXEC) created                     "
	@ echo "                                                              "
	@ echo "              the mpi executable can be found in:             "
	@ echo "                                                              "
	@ echo "                    $(DIR)/$(EXEC)                            "
	@ echo "                                                              "
	@ echo "=============================================================="
	@ echo "                                                              "

# ******************************* CLEAN/SCRUB ********************************

# the @touch is used to (silently) create some temp files to prevent irksome
# warning messages are sometimes created if there are no *.whatever files and
# one tries to remove them

cleano:
	@touch temp.o
	-rm -f *.o

cleane:
	-rm -f $(EXEC) 

cleana:
	@touch temp.a
	-rm -f *.a 

cleanf:
	@touch temp.f
	-rm -f *.f

cleanh:
	@touch temp.h
	-rm -f *.h

cleang:
	@touch temp.F
	-rm -f *.F

scrub: cleana cleano cleane cleanf cleanh cleang
